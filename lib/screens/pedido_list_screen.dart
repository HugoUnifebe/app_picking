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
  List<Map<String, dynamic>> _allPedidos = [];
  List<Map<String, dynamic>> _filteredPedidos = [];
  List<Map<String, dynamic>> _statuses = [];
  
  bool _isLoading = true;
  
  // Filtros
  final _idController = TextEditingController();
  final _caixaController = TextEditingController();
  int? _selectedStatusId;

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  Future<void> _refreshList() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    final data = await _repository.getAllWithDetails();
    _statuses = await _repository.getStatuses();
    
    List<Map<String, dynamic>> mutableData = List.from(data);
    mutableData.sort((a, b) {
      int statusA = a['codigo_status_pedido'] ?? 99;
      int statusB = b['codigo_status_pedido'] ?? 99;
      
      if (statusA != statusB) {
        return statusA.compareTo(statusB);
      }
      
      String dateStrA = a['criado_em'] ?? '';
      String dateStrB = b['criado_em'] ?? '';
      
      if (dateStrA.isEmpty) return 1;
      if (dateStrB.isEmpty) return -1;
      
      return dateStrA.compareTo(dateStrB);
    });
    
    if (mounted) {
      setState(() {
        _allPedidos = mutableData;
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredPedidos = _allPedidos.where((pedido) {
        // Filtro por ID
        final matchId = _idController.text.isEmpty || 
            pedido['codigo_pedido'].toString().contains(_idController.text);
        
        // Filtro por Status
        final matchStatus = _selectedStatusId == null || 
            pedido['codigo_status_pedido'] == _selectedStatusId;
        
        // Filtro por Caixa (Código de Barras)
        final matchCaixa = _caixaController.text.isEmpty || 
            (pedido['codigo_barra_caixa'] ?? '').toString().toLowerCase().contains(_caixaController.text.toLowerCase());

        return matchId && matchStatus && matchCaixa;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos'),
      ),
      body: Column(
        children: [
          // --- Barra de Filtros ---
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _idController,
                        decoration: const InputDecoration(
                          hintText: 'Nº Pedido',
                          prefixIcon: Icon(Icons.search, size: 20),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _applyFilters(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<int>(
                        value: _selectedStatusId,
                        isExpanded: true,
                        decoration: const InputDecoration(hintText: 'Status'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Todos Status')),
                          ..._statuses.map((s) => DropdownMenuItem(
                            value: s['codigo_status_pedido'] as int,
                            child: Text(s['descricao']),
                          )),
                        ],
                        onChanged: (val) {
                          _selectedStatusId = val;
                          _applyFilters();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _caixaController,
                  decoration: const InputDecoration(
                    hintText: 'Filtrar por Código da Caixa...',
                    prefixIcon: Icon(Icons.inventory, size: 20),
                  ),
                  onChanged: (_) => _applyFilters(),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),

          // --- Lista ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPedidos.isEmpty
                    ? const Center(child: Text('Nenhum pedido encontrado para os filtros.'))
                    : ListView.builder(
                        itemCount: _filteredPedidos.length,
                        itemBuilder: (context, index) {
                          final pedido = _filteredPedidos[index];
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
                                'Caixa: ${pedido['codigo_barra_caixa'] ?? "Não informada"}',
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
          ),
        ],
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
