import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../repositories/usuario_repository.dart';
import 'usuario_form_screen.dart';
import 'scanner_screen.dart';

class UsuarioListScreen extends StatefulWidget {
  const UsuarioListScreen({super.key});

  @override
  State<UsuarioListScreen> createState() => _UsuarioListScreenState();
}

class _UsuarioListScreenState extends State<UsuarioListScreen> {
  final UsuarioRepository _repository = UsuarioRepository();
  List<Map<String, dynamic>> _allUsuarios = [];
  List<Map<String, dynamic>> _filteredUsuarios = [];
  bool _isLoading = true;

  // Filtro
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  Future<void> _refreshList() async {
    setState(() => _isLoading = true);
    final data = await _repository.getAll();
    setState(() {
      _allUsuarios = data;
      _applyFilters();
      _isLoading = false;
    });
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsuarios = _allUsuarios.where((user) {
        final matchNome = (user['nome'] ?? '').toString().toLowerCase().contains(query);
        final matchEmail = (user['email'] ?? '').toString().toLowerCase().contains(query);
        final matchBarcode = (user['codigo_barra_usuario'] ?? '').toString().toLowerCase().contains(query);
        
        return matchNome || matchEmail || matchBarcode;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Usuários'),
      ),
      body: Column(
        children: [
          // --- Barra de Filtro ---
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nome, e-mail ou crachá...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () async {
                    final barcode = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ScannerScreen(),
                      ),
                    );
                    if (barcode != null) {
                      setState(() {
                        _searchController.text = barcode;
                        _applyFilters();
                      });
                    }
                  },
                ),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              onChanged: (_) => _applyFilters(),
            ),
          ),
          const Divider(height: 1),

          // --- Lista ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsuarios.isEmpty
                    ? const Center(child: Text('Nenhum usuário encontrado.'))
                    : ListView.builder(
                        itemCount: _filteredUsuarios.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsuarios[index];
                          final bool isAtivo = user['ativo'] == 1;

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: user['codigo_tipo'] == 1 ? Colors.blue[100] : Colors.orange[100],
                                child: Icon(
                                  user['codigo_tipo'] == 1 ? Icons.admin_panel_settings : Icons.person,
                                  color: user['codigo_tipo'] == 1 ? Colors.blue[900] : Colors.orange[900],
                                ),
                              ),
                              title: Text(user['nome'] ?? 'Sem Nome'),
                              subtitle: Text('${user['tipo_nome']} | ${user['email']}\nStatus: ${isAtivo ? "Ativo" : "Inativo"}'),
                              trailing: const Icon(Icons.edit),
                              isThreeLine: true,
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UsuarioFormScreen(usuarioId: user['codigo_usuario']),
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
            MaterialPageRoute(builder: (context) => const UsuarioFormScreen()),
          );
          if (result == true) _refreshList();
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
