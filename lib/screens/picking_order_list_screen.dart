import 'dart:async';
import 'package:flutter/material.dart';
import '../repositories/pedido_repository.dart';
import '../models/usuario.dart';
import 'picking_execution_screen.dart';
import 'scanner_screen.dart';

class PickingOrderListScreen extends StatefulWidget {
  final Usuario usuario;
  const PickingOrderListScreen({super.key, required this.usuario});

  @override
  State<PickingOrderListScreen> createState() => PickingOrderListScreenState();
}

class PickingOrderListScreenState extends State<PickingOrderListScreen> {
  final PedidoRepository _pedidoRepo = PedidoRepository();
  List<Map<String, dynamic>> _allPedidos = [];
  List<Map<String, dynamic>> _filteredPedidos = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  final _idController = TextEditingController();
  final _caixaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    refreshList();
    _startPolling();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _idController.dispose();
    _caixaController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        refreshList(isSilent: true);
      }
    });
  }

  Future<void> refreshList({bool isSilent = false}) async {
    if (!mounted) return;
    
    if (!isSilent && _allPedidos.isEmpty) {
      setState(() => _isLoading = true);
    }
    
    try {
      final data = await _pedidoRepo.getAllWithDetails();
      
      List<Map<String, dynamic>> mutableData = List.from(data);
      
      mutableData.sort((a, b) {
        int statusA = a['codigo_status_pedido'] ?? 99;
        int statusB = b['codigo_status_pedido'] ?? 99;
        if (statusA != statusB) return statusA.compareTo(statusB);
        String dateStrA = a['criado_em'] ?? '';
        String dateStrB = b['criado_em'] ?? '';
        return dateStrA.compareTo(dateStrB);
      });

      if (mounted) {
        setState(() {
          _allPedidos = mutableData.where((p) => p['codigo_status_pedido'] != 3).toList();
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao atualizar lista: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final idQuery = _idController.text.trim();
    final caixaQuery = _caixaController.text.trim().toLowerCase();

    setState(() {
      _filteredPedidos = _allPedidos.where((pedido) {
        final matchId = idQuery.isEmpty || 
            pedido['codigo_pedido'].toString().contains(idQuery);
        final matchCaixa = caixaQuery.isEmpty || 
            (pedido['nome_caixa'] ?? '').toString().toLowerCase().contains(caixaQuery);
        return matchId && matchCaixa;
      }).toList();
    });
  }

  String _formatarHora(dynamic data) {
    if (data == null || data.toString() == "null" || data.toString().isEmpty) {
      return "--:--";
    }
    
    try {
      DateTime dt = (data is DateTime) ? data : DateTime.parse(data.toString().trim());
      String dia = dt.day.toString().padLeft(2, '0');
      String mes = dt.month.toString().padLeft(2, '0');
      String hora = dt.hour.toString().padLeft(2, '0');
      String minuto = dt.minute.toString().padLeft(2, '0');
      return "$dia/$mes $hora:$minuto";
    } catch (e) {
      return "--:--";
    }
  }

  void _abrirPorPapeleta() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => ScannerScreen()),
    );

    if (barcode != null) {
      // Procura o pedido pelo Nº do Pedido ou pelo Nome da Caixa na lista atual
      final pedidoEncontrado = _allPedidos.firstWhere(
        (p) => p['codigo_pedido'].toString() == barcode || 
               (p['nome_caixa'] ?? '').toString().toLowerCase() == barcode.toLowerCase(),
        orElse: () => {},
      );

      if (pedidoEncontrado.isNotEmpty) {
        _selecionarPedido(pedidoEncontrado);
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Não encontrado'),
              content: Text('Nenhum pedido aberto ou em andamento encontrado para a papeleta: $barcode'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
              ],
            ),
          );
        }
      }
    }
  }

  void _selecionarPedido(Map<String, dynamic> pedido) async {
    final bool emAndamento = pedido['codigo_status_pedido'] == 2;
    final int? responsavelId = pedido['codigo_usuario_responsavel'];
    final bool souResponsavel = responsavelId == widget.usuario.codigoUsuario;

    // Se o pedido já estiver em andamento e eu não for o responsável
    if (emAndamento && !souResponsavel && responsavelId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Este pedido já está sendo coletado por ${pedido['responsavel_nome'] ?? "outro usuário"}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Se eu já sou o responsável ou o pedido está aguardando
    if (souResponsavel || !emAndamento) {
      final bool? confirmar = souResponsavel ? true : await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar Picking'),
          content: Text('Deseja assumir a responsabilidade pela coleta do Pedido #${pedido['codigo_pedido']}?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('NÃO')),
            TextButton(
              onPressed: () => Navigator.pop(context, true), 
              child: const Text('SIM', style: TextStyle(fontWeight: FontWeight.bold))
            ),
          ],
        ),
      );

      if (confirmar == true) {
        if (!souResponsavel) {
          await _pedidoRepo.atribuirResponsavel(pedido['codigo_pedido'], widget.usuario.codigoUsuario!);
        }
        
        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PickingExecutionScreen(
                pedidoId: pedido['codigo_pedido'],
                usuario: widget.usuario,
              ),
            ),
          );
          refreshList();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fila de Picking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF003399)),
            onPressed: _abrirPorPapeleta,
            tooltip: "Abrir por Papeleta",
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => refreshList(),
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _idController,
                    decoration: InputDecoration(
                      hintText: 'Nº Pedido',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _applyFilters(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _caixaController,
                    decoration: InputDecoration(
                      hintText: 'Filtrar Caixa...',
                      prefixIcon: const Icon(Icons.inventory, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    ),
                    onChanged: (_) => _applyFilters(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => refreshList(),
                    child: _filteredPedidos.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                              const Center(child: Icon(Icons.check_circle_outline, size: 64, color: Colors.grey)),
                              const SizedBox(height: 16),
                              const Center(child: Text('Tudo limpo! Sem pedidos pendentes.', style: TextStyle(color: Colors.grey))),
                            ],
                          )
                        : ListView.builder(
                            itemCount: _filteredPedidos.length,
                            itemBuilder: (context, index) {
                              final pedido = _filteredPedidos[index];
                              final bool emAndamento = pedido['codigo_status_pedido'] == 2;
                              final bool souResponsavel = pedido['codigo_usuario_responsavel'] == widget.usuario.codigoUsuario;

                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                elevation: emAndamento ? 4 : 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: emAndamento 
                                    ? BorderSide(color: souResponsavel ? Colors.blue : Colors.red, width: 2) 
                                    : BorderSide.none,
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  title: Row(
                                    children: [
                                      Text('PEDIDO #${pedido['codigo_pedido']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                      const Spacer(),
                                      _buildBadge(
                                        souResponsavel ? "Meu Picking" : (pedido['status_nome'] ?? 'Aguardando'), 
                                        emAndamento ? (souResponsavel ? Colors.blue : Colors.red) : Colors.orange
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.inventory, size: 16, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text('Caixa: ${pedido['nome_caixa'] ?? "Não atribuída"}', style: const TextStyle(fontSize: 16)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text('Criado em: ${_formatarHora(pedido['criado_em'])}', style: const TextStyle(color: Colors.grey)),
                                          ],
                                        ),
                                        if (emAndamento && !souResponsavel)
                                          Text('Resp: ${pedido['responsavel_nome'] ?? "Outro"}', style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  onTap: () => _selecionarPedido(pedido),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color)),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
