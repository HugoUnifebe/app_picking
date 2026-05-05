import 'dart:async';
import 'package:flutter/material.dart';
import '../repositories/pedido_repository.dart';
import '../models/usuario.dart';
import '../utils/audio_helper.dart';
import 'scanner_screen.dart';

class PickingExecutionScreen extends StatefulWidget {
  final int pedidoId;
  final Usuario usuario;

  const PickingExecutionScreen({
    super.key,
    required this.pedidoId,
    required this.usuario,
  });

  @override
  State<PickingExecutionScreen> createState() => _PickingExecutionScreenState();
}

class _PickingExecutionScreenState extends State<PickingExecutionScreen> {
  final PedidoRepository _pedidoRepo = PedidoRepository();
  List<Map<String, dynamic>> _itens = [];
  Map<String, dynamic>? _pedidoData;
  bool _isLoading = true;
  
  // Controle de feedback visual/sonoro (simulado)
  Color _feedbackColor = Colors.transparent;
  String _feedbackMessage = "";
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _pedidoData = await _pedidoRepo.getById(widget.pedidoId);
    _itens = await _pedidoRepo.getItems(widget.pedidoId);
    setState(() => _isLoading = false);
  }

  void _triggerFeedback(Color color, String message, {bool isLong = false}) {
    _feedbackTimer?.cancel();
    setState(() {
      _feedbackColor = color;
      _feedbackMessage = message;
    });
    
    // Som e Feedback Sonoro real
    if (color == Colors.green) {
      if (isLong) {
        AudioHelper.playBeepSimples().then((_) {
          Future.delayed(const Duration(milliseconds: 300), () => AudioHelper.playBeepSimples());
        });
      } else {
        AudioHelper.playBeepSimples();
      }
    } else if (color == Colors.red) {
      AudioHelper.playBeepLongo();
    }

    _feedbackTimer = Timer(Duration(seconds: isLong ? 3 : 1), () {
      if (mounted) {
        setState(() {
          _feedbackColor = Colors.transparent;
          _feedbackMessage = "";
        });
      }
    });
  }

  Future<void> _startScanning() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );

    if (barcode != null) {
      _processScannedBarcode(barcode);
    }
  }

  void _processScannedBarcode(String barcode) async {
    final scannedCode = barcode.trim();
    debugPrint('DEBUG SCAN - Código lido: "$scannedCode"');
    
    // Procura na lista de itens do pedido um produto que combine com o barcode
    int? itemIndex;
    for (int i = 0; i < _itens.length; i++) {
      final item = _itens[i];
      final sku = (item['sku'] ?? '').toString().trim();
      final ean = (item['codigo_barra_produto'] ?? '').toString().trim();
      
      debugPrint('DEBUG SCAN - Comparando com Item $i: SKU="$sku", EAN="$ean"');

      if ((sku == scannedCode || ean == scannedCode) &&
          item['codigo_status_produto_pedido'] == 1) {
        itemIndex = i;
        break;
      }
    }

    if (itemIndex != null) {
      final item = _itens[itemIndex];
      debugPrint('DEBUG SCAN - Item encontrado: ${item['nome_produto']}');
      
      // Atualiza no banco
      await _pedidoRepo.updateItemStatus(
        widget.pedidoId,
        item['codigo_produto'],
        item['codigo_produto_pedido'],
        2, // Na caixa
      );

      // Recarrega dados locais para validar se SKU completou
      final novosItens = await _pedidoRepo.getItems(widget.pedidoId);
      final skuPartes = novosItens.where((i) => i['sku'] == item['sku']).toList();
      final skuCompleta = skuPartes.every((i) => i['codigo_status_produto_pedido'] != 1);

      if (skuCompleta) {
        _triggerFeedback(Colors.green, "SKU ${item['sku']} COMPLETA!", isLong: true);
      } else {
        _triggerFeedback(Colors.green, "PEÇA COLETADA!");
      }

      setState(() => _itens = novosItens);
    } else {
      // 3.4: Verifica se já foi bipada (sem saldo)
      bool jaColetado = _itens.any((item) => 
        (item['sku'] == barcode || item['codigo_barra_produto'] == barcode) && 
        item['codigo_status_produto_pedido'] != 1
      );

      if (jaColetado) {
        _triggerFeedback(Colors.red, "PEÇA SEM SALDO!", isLong: true);
        _showErrorDialog("Atenção", "Peça sem saldo (já bipada).");
      } else {
        // 3.3: Não pertence ao pedido
        _triggerFeedback(Colors.red, "SKU NÃO PERTENCE À CAIXA!", isLong: true);
        _showErrorDialog("Erro de Validação", "SKU não pertence à caixa.");
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CONFIRMAR E PROSSEGUIR')),
        ],
      ),
    );
  }

  // 4.1 & 4.2: Recursos para SKU desabastecida
  void _optionsSKU(Map<String, dynamic> item) {
    if (item['codigo_status_produto_pedido'] != 1) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Opções para SKU: ${item['sku']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.skip_next, color: Colors.orange),
              title: const Text('Pular coleta (Desabastecida)'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item pulado.')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.blue),
              title: const Text('Ver outras localizações'),
              onTap: () {
                Navigator.pop(context);
                _showAlternativeLocations(item['sku']);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAlternativeLocations(String sku) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Localizações SKU $sku'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text('A02.01.4A'), subtitle: Text('Estoque Principal')),
            ListTile(title: Text('B05.02.1B'), subtitle: Text('Reserva Superior')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('FECHAR')),
        ],
      ),
    );
  }

  // 5.1, 5.2, 5.3: Finalização
  void _finalizarPicking() async {
    int total = _itens.length;
    int coletados = _itens.where((i) => i['codigo_status_produto_pedido'] != 1).length;
    bool incompleto = coletados < total;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(incompleto ? 'Picking Parcial' : 'Picking Completo'),
        content: Text(incompleto 
          ? 'Faltam itens a serem coletados. Deseja salvar como picking parcial?' 
          : 'Deseja finalizar a caixa e encerrar o pedido?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('VOLTAR')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: Text(incompleto ? 'SALVAR PARCIAL' : 'FINALIZAR CAIXA', style: const TextStyle(fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirm == true) {
      // 5.3: Se incompleto, o status do pedido permanece em andamento ou parcial
      if (!incompleto) {
        await _pedidoRepo.updateStatusPedido(widget.pedidoId, 3); // 3 = Finalizado
      }
      
      if (mounted) {
        _triggerFeedback(
          incompleto ? Colors.orange : Colors.green, 
          incompleto ? "CAIXA COM PICKING PARCIAL" : "CAIXA FINALIZADA", 
          isLong: true
        );
        
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalItens = _itens.length;
    int coletados = _itens.where((i) => i['codigo_status_produto_pedido'] != 1).length;
    bool tudoColetado = totalItens > 0 && coletados == totalItens;

    return Scaffold(
      appBar: AppBar(
        title: Text('Picking Pedido #${widget.pedidoId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt, color: Colors.orange),
            onPressed: _finalizarPicking, // Salva parcial a qualquer momento
            tooltip: "Salvar Picking Parcial",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
                  children: [
                    // Cabeçalho Operacional
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: const Color(0xFF003399).withOpacity(0.05),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.inventory, color: Color(0xFF003399)),
                              const SizedBox(width: 8),
                              Text('Caixa: ${_pedidoData?['nome_caixa'] ?? "S/N"}', 
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Responsável: ${widget.usuario.nome}', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    
                    // Barra de Progresso
                    if (totalItens > 0)
                      LinearProgressIndicator(
                        value: coletados / totalItens,
                        backgroundColor: Colors.grey[200],
                        color: tudoColetado ? Colors.green : const Color(0xFF003399),
                      ),

                    Expanded(
                      child: ListView.builder(
                        itemCount: _itens.length,
                        itemBuilder: (context, index) {
                          final item = _itens[index];
                          final bool naCaixa = item['codigo_status_produto_pedido'] != 1;
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            elevation: naCaixa ? 0 : 2,
                            color: naCaixa ? Colors.green[50] : Colors.white,
                            child: ListTile(
                              onTap: () => _optionsSKU(item), // Atalho para desabastecimento
                              leading: CircleAvatar(
                                backgroundColor: naCaixa ? Colors.green : Colors.grey[200],
                                child: Text("${index + 1}", style: TextStyle(color: naCaixa ? Colors.white : Colors.black54)),
                              ),
                              // ** Sugestão: Referência/Cor/Tamanho na mesma linha **
                              title: Text('${item['sku']} - ${item['cor'] ?? ""} - ${item['tamanho'] ?? ""}',
                                style: TextStyle(
                                  decoration: naCaixa ? TextDecoration.lineThrough : null,
                                  fontWeight: naCaixa ? FontWeight.normal : FontWeight.bold,
                                ),
                              ),
                              subtitle: Text('Endereço: ${item['localizacao'] ?? "S/N"}'),
                              trailing: Icon(
                                naCaixa ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: naCaixa ? Colors.green : Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                
                // Overlay de Feedback Visual (Sinal Luminoso)
                if (_feedbackColor != Colors.transparent)
                  Container(
                    color: _feedbackColor.withOpacity(0.8),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _feedbackColor == Colors.green ? Icons.check_circle : Icons.error,
                            size: 100,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _feedbackMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: !tudoColetado ? FloatingActionButton.extended(
        onPressed: _startScanning,
        backgroundColor: const Color(0xFF003399),
        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
        label: const Text('BIPAR PRODUTO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ) : FloatingActionButton.extended(
        onPressed: _finalizarPicking,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.flag, color: Colors.white),
        label: const Text('FINALIZAR CAIXA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
