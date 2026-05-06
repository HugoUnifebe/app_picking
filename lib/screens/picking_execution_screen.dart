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
  
  List<Map<String, dynamic>> _allOrderItems = [];
  Map<String, List<Map<String, dynamic>>> _groupedItems = {};
  bool _isLoading = true;
  Color _feedbackColor = Colors.white;
  String _message = '';

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
    
    // Agrupar itens por SKU/Endereço/Cor/Tamanho para exibição em lista
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (var item in items) {
      final key = "${item['sku']}-${item['localizacao']}-${item['cor']}-${item['tamanho']}";
      grouped.putIfAbsent(key, () => []).add(item);
    }

    setState(() {
      _allOrderItems = items;
      _groupedItems = grouped;
      _isLoading = false;
    });

    // Se todos os itens estiverem na caixa (status 2 ou 3), finaliza
    final todosColetados = items.every((i) => i['codigo_status_produto_pedido'] >= 2);
    if (todosColetados && items.isNotEmpty) {
      // Consideramos completa se não houver nenhum item com status 1 (Pendente)
      // O status 2 é "Na caixa" e o status 3 é "Finalizado" (se aplicável)
      _finalizarCaixa(completa: true);
    }
  }

  Future<void> _playBeep(bool success, {bool completed = false, bool finishing = false}) async {
    if (finishing) {
      await _audioPlayer.play(AssetSource('success.mp3'));
      return;
    }

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

    if (prod != null) {
      // Encontrar o primeiro item pendente com esse SKU na lista geral do pedido
      final itemPendente = _allOrderItems.where((i) => 
        i['sku'] == prod['sku'] && 
        i['codigo_status_produto_pedido'] == 1
      ).firstOrNull;

      if (itemPendente != null) {
        // SUCESSO: O produto bipado pertence a um item pendente
        setState(() => _feedbackColor = Colors.green);

        await _pedidoRepo.updateItemStatus(
          widget.pedidoId, 
          itemPendente['codigo_produto'], 
          itemPendente['codigo_produto_pedido'], 
          2 // Status "Na caixa"
        );

        // Verifica se essa SKU específica acabou de ser concluída
        final key = "${itemPendente['sku']}-${itemPendente['localizacao']}-${itemPendente['cor']}-${itemPendente['tamanho']}";
        final group = _groupedItems[key]!;
        final itensRestantesNoGrupo = group.where((i) => 
          i['codigo_produto_pedido'] != itemPendente['codigo_produto_pedido'] &&
          i['codigo_status_produto_pedido'] == 1
        ).length;

        if (itensRestantesNoGrupo == 0) {
          await _playBeep(true, completed: true);
        } else {
          await _playBeep(true);
        }

        await Future.delayed(const Duration(milliseconds: 300));
        _loadItems();
        setState(() => _feedbackColor = Colors.white);
      } else {
        // SKU existe mas não tem saldo pendente no pedido
        _showError('SKU sem saldo ou já coletada');
      }
    } else {
      _showError('Produto não encontrado');
    }
  }

  void _finalizarCaixa({required bool completa}) {
    if (completa) {
      setState(() => _feedbackColor = Colors.green);
      _playBeep(true, finishing: true);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(completa ? 'CAIXA FINALIZADA' : 'CAIXA COM PICKING PARCIAL'),
        content: Text(completa 
          ? 'Todas as peças foram coletadas com sucesso!' 
          : 'Algumas peças não foram coletadas por desabastecimento.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fecha dialog
              setState(() => _feedbackColor = Colors.white);
            },
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Fecha dialog
              Navigator.pop(context); // Volta para o início
            },
            child: const Text('CONFIRMAR'),
          )
        ],
      ),
    );
  }

  Widget _buildAttributeRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ],
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
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _groupedItems.length,
              itemBuilder: (context, index) {
                final key = _groupedItems.keys.elementAt(index);
                final group = _groupedItems[key]!;
                final first = group.first;
                
                final total = group.length;
                final coletados = group.where((i) => i['codigo_status_produto_pedido'] >= 2).length;
                final isDone = coletados >= total;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDone ? Colors.green[50] : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDone ? Colors.green[200]! : Colors.grey[300]!, 
                      width: 2
                    ),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildAttributeRow('REFERÊNCIA', first['sku'] ?? '--'),
                                const SizedBox(height: 4),
                                _buildAttributeRow('COR', first['cor'] ?? '--'),
                                const SizedBox(height: 4),
                                _buildAttributeRow('TAMANHO', first['tamanho'] ?? '--'),
                              ],
                            ),
                          ),
                          if (isDone)
                            const Icon(Icons.check_circle, color: Colors.green, size: 32),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ENDEREÇO', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text(
                                first['localizacao'] ?? '--',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF003399)),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Text('QTD: ', style: TextStyle(fontSize: 16)),
                              Text('$coletados', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDone ? Colors.green : Colors.orange)),
                              Text(' / $total', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          if (_message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_message, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
            ),

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
