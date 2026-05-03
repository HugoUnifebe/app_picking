import 'package:flutter/material.dart';
import '../repositories/pedido_repository.dart';
import 'pedido_form_screen.dart';

class PedidoListScreen extends StatefulWidget {
  const PedidoListScreen({super.key});

  @override
  State<PedidoListScreen> createState() => _PedidoListScreenState();
}

class _PedidoListScreenState extends State<PedidoListScreen> {
  final PedidoRepository _repository = PedidoRepository();
  List<Map<String, dynamic>> _pedidos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  Future<void> _refreshList() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final data = await _repository.getAllWithDetails();
    if (mounted) {
      setState(() {
        _pedidos = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pedidos.isEmpty
              ? const Center(child: Text('Nenhum pedido encontrado.'))
              : ListView.builder(
                  itemCount: _pedidos.length,
                  itemBuilder: (context, index) {
                    final pedido = _pedidos[index];
                    final colorHex = pedido['status_cor'] ?? 'CCCCCC';
                    final statusColor = Color(int.parse('FF$colorHex', radix: 16));

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Container(
                          width: 8,
                          height: 40,
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        title: Text('Pedido #${pedido['codigo_pedido']}'),
                        subtitle: Text(
                          'Status: ${pedido['status_nome'] ?? "Aberto"}\n'
                          'Caixa: ${pedido['nome_caixa'] ?? "Não atribuída"}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PedidoFormScreen(pedidoId: pedido['codigo_pedido']),
                            ),
                          );
                          if (result == true) _refreshList();
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PedidoFormScreen()),
          );
          if (result == true) _refreshList();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
