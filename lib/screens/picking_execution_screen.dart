import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../repositories/pedido_repository.dart';
import 'scanner_screen.dart';

class PickingExecutionScreen extends StatefulWidget {
  final int pedidoId;
  const PickingExecutionScreen({super.key, required this.pedidoId});

  @override
  State<PickingExecutionScreen> createState() => _PickingExecutionScreenState();
}

class _PickingExecutionScreenState extends State<PickingExecutionScreen> {
  final PedidoRepository _pedidoRepo = PedidoRepository();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  List<Map<String, dynamic>> _itens = [];
  bool _isLoading = true;
  Color _feedbackColor = Colors.white;
  String _message = '';
  
  // Controle de Item Atual (Endereço)
  Map<String, dynamic>? _currentItem;
  int _collectedCount = 0;
  int _totalToCollect = 0;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final items = await _pedidoRepo.getItems(widget.pedidoId);
    
    // Filtrar apenas itens que não estão na caixa (ou entregues)
    final pendentes = items.where((i) => i['codigo_status_produto_pedido'] == 1).toList();

    if (pendentes.isEmpty) {
      _finalizarCaixa(completa: items.length == items.where((i) => i['codigo_status_produto_pedido'] == 3).length);
    } else {
      setState(() {
        _itens = pendentes;
        _currentItem = pendentes.first;
        // Agrupar por SKU/Endereço para saber quanto falta
        _totalToCollect = pendentes.where((i) => 
          i['sku'] == _currentItem!['sku'] && 
          i['localizacao'] == _currentItem!['localizacao']
        ).length;
        _collectedCount = 0;
        _isLoading = false;
      });
    }
  }

  Future<void> _playBeep(bool success, {bool completed = false}) async {
    if (success) {
      if (completed) {
        await _audioPlayer.play(AssetSource('beep_simples.mp3'));
        await Future.delayed(const Duration(milliseconds: 200));
        await _audioPlayer.play(AssetSource('beep_simples.mp3'));
      } else {
        await _audioPlayer.play(AssetSource('beep_simples.mp3'));
      }
    } else {
      await _audioPlayer.play(AssetSource('beep_longo.mp3'));
    }
  }

  void _showError(String msg) {
    setState(() {
      _feedbackColor = Colors.red;
      _message = msg;
    });
    _playBeep(false);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('ALERTA DE PICKING', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text(msg, style: const TextStyle(fontSize: 18)),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _feedbackColor = Colors.white;
                _message = '';
              });
            },
            child: const Text('CONFIRMAR E PROSSEGUIR'),
          )
        ],
      ),
    );
  }

  Future<void> _biparPeca() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );

    if (barcode == null) return;

    // Busca o produto pelo código de barras bipado
    final prod = await _pedidoRepo.getProdutoByBarcode(barcode);

    if (prod != null && prod['sku'] == _currentItem?['sku']) {
      // SUCESSO: O produto bipado pertence à SKU do endereço atual
      setState(() {
        _feedbackColor = Colors.green;
        _collectedCount++;
      });

      // Atualizar no banco: usamos o codigo_produto_pedido do item que estamos processando
      await _pedidoRepo.updateItemStatus(
        widget.pedidoId, 
        _currentItem!['codigo_produto'], 
        _currentItem!['codigo_produto_pedido'], 
        2 // Status "Na caixa"
      );

      if (_collectedCount >= _totalToCollect) {
        await _playBeep(true, completed: true);
        await Future.delayed(const Duration(milliseconds: 500));
        _loadItems(); // Pula para o próximo endereço
        setState(() => _feedbackColor = Colors.white);
      } else {
        await _playBeep(true);
        // Remove o item atual da lista local de itens do mesmo grupo para pegar o próximo
        _itens.remove(_currentItem);
        
        // Encontra o próximo item da mesma SKU no grupo
        final nextInGroup = _itens.firstWhere((i) => 
          i['sku'] == prod['sku'] && 
          i['codigo_status_produto_pedido'] == 1
        );
        
        setState(() {
          _currentItem = nextInGroup;
          _feedbackColor = Colors.white;
        });
      }
    } else {
      // ERRO
      if (prod == null || prod['sku'] != _currentItem?['sku']) {
        _showError('SKU não pertence à caixa');
      } else {
        // Este caso teoricamente não ocorreria mais com a nova lógica, 
        // mas mantemos para segurança de fluxo.
        _showError('Peça sem saldo');
      }
    }
  }

  void _finalizarCaixa({required bool completa}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(completa ? 'CAIXA FINALIZADA' : 'CAIXA COM PICKING PARCIAL'),
        content: Text(completa 
          ? 'Todas as peças foram coletadas com sucesso!' 
          : 'Algumas peças não foram coletadas por desabastecimento.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Fecha dialog
              Navigator.pop(context); // Volta para o início
            },
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: _feedbackColor,
      appBar: AppBar(
        title: Text('Picking Pedido #${widget.pedidoId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _finalizarCaixa(completa: false),
            tooltip: 'Salvar Parcial',
          )
        ],
      ),
      body: Column(
        children: [
          // Card de Endereço (Imagem 2.2)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!, width: 2),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('REFERÊNCIA', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(_currentItem?['sku'] ?? '--', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('TAMANHO', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(_currentItem?['tamanho'] ?? '--', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 32),
                const Text('ENDEREÇO', style: TextStyle(color: Colors.grey, fontSize: 14)),
                Text(
                  _currentItem?['localizacao'] ?? '--',
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF003399)),
                ),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('QUANTIDADE: ', style: TextStyle(fontSize: 20)),
                    Text('$_collectedCount', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
                    Text(' / $_totalToCollect', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          
          if (_message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_message, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
            ),

          const Spacer(),

          // Botões de Ação
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showError('Funcionalidade de pulo não implementada');
                        },
                        icon: const Icon(Icons.skip_next),
                        label: const Text('PULAR SKU'),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.map),
                        label: const Text('ESTOQUE'),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 80,
                  child: ElevatedButton.icon(
                    onPressed: _biparPeca,
                    icon: const Icon(Icons.qr_code_scanner, size: 32),
                    label: const Text('BIPAR PEÇA', style: TextStyle(fontSize: 24)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003399),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
