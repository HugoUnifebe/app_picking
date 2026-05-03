import 'package:flutter/material.dart';
import '../repositories/caixa_repository.dart';
import 'caixa_form_screen.dart';

class CaixaListScreen extends StatefulWidget {
  const CaixaListScreen({super.key});

  @override
  State<CaixaListScreen> createState() => _CaixaListScreenState();
}

class _CaixaListScreenState extends State<CaixaListScreen> {
  final CaixaRepository _repository = CaixaRepository();
  List<Map<String, dynamic>> _allCaixas = [];
  List<Map<String, dynamic>> _filteredCaixas = [];
  List<Map<String, dynamic>> _statuses = [];
  
  bool _isLoading = true;

  // Filtros
  final _nomeController = TextEditingController();
  int? _selectedStatusId;

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  Future<void> _refreshList() async {
    setState(() => _isLoading = true);
    final data = await _repository.getAllWithDetails();
    _statuses = await _repository.getStatuses();
    
    setState(() {
      _allCaixas = data;
      _applyFilters();
      _isLoading = false;
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredCaixas = _allCaixas.where((caixa) {
        // Filtro por Nome
        final matchNome = _nomeController.text.isEmpty || 
            (caixa['nome_caixa'] ?? '').toString().toLowerCase().contains(_nomeController.text.toLowerCase());
        
        // Filtro por Status
        final matchStatus = _selectedStatusId == null || 
            caixa['codigo_status_caixa'] == _selectedStatusId;

        return matchNome && matchStatus;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caixas e Localizações'),
      ),
      body: Column(
        children: [
          // --- Barra de Filtros ---
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      hintText: 'Nome da caixa...',
                      prefixIcon: Icon(Icons.search, size: 20),
                    ),
                    onChanged: (_) => _applyFilters(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    value: _selectedStatusId,
                    isExpanded: true,
                    decoration: const InputDecoration(hintText: 'Status'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      ..._statuses.map((s) => DropdownMenuItem(
                        value: s['codigo_status_caixa'] as int,
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
          ),
          
          const Divider(height: 1),

          // --- Lista ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCaixas.isEmpty
                    ? const Center(child: Text('Nenhuma caixa encontrada.'))
                    : ListView.builder(
                        itemCount: _filteredCaixas.length,
                        itemBuilder: (context, index) {
                          final caixa = _filteredCaixas[index];
                          final colorHex = caixa['cor_hex'] ?? 'CCCCCC';
                          final statusColor = Color(int.parse('FF$colorHex', radix: 16));

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: statusColor,
                                child: const Icon(Icons.inventory, color: Colors.white),
                              ),
                              title: Text(caixa['nome_caixa'] ?? 'Sem Nome'),
                              subtitle: Text(
                                'Status: ${caixa['status_nome']}\n'
                                'Local: ${caixa['localizacao'] ?? "Não definida"}',
                              ),
                              trailing: const Icon(Icons.edit),
                              isThreeLine: true,
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CaixaFormScreen(caixaId: caixa['codigo_caixa']),
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
            MaterialPageRoute(builder: (context) => const CaixaFormScreen()),
          );
          if (result == true) _refreshList();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
