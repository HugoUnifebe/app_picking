import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../repositories/usuario_repository.dart';
import 'usuario_form_screen.dart';

class UsuarioListScreen extends StatefulWidget {
  const UsuarioListScreen({super.key});

  @override
  State<UsuarioListScreen> createState() => _UsuarioListScreenState();
}

class _UsuarioListScreenState extends State<UsuarioListScreen> {
  final UsuarioRepository _repository = UsuarioRepository();
  List<Map<String, dynamic>> _usuarios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  Future<void> _refreshList() async {
    setState(() => _isLoading = true);
    // Adicionaremos um método getAll no repositório
    final data = await _repository.getAll();
    setState(() {
      _usuarios = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Usuários'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _usuarios.isEmpty
              ? const Center(child: Text('Nenhum usuário encontrado.'))
              : ListView.builder(
                  itemCount: _usuarios.length,
                  itemBuilder: (context, index) {
                    final user = _usuarios[index];
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
