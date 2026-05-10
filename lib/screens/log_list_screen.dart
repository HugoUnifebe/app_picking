import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../repositories/log_repository.dart';
import '../repositories/usuario_repository.dart';

class LogListScreen extends StatefulWidget {
  final Usuario usuarioLogado;
  const LogListScreen({super.key, required this.usuarioLogado});

  @override
  State<LogListScreen> createState() => _LogListScreenState();
}

class _LogListScreenState extends State<LogListScreen> {
  final LogRepository _logRepo = LogRepository();
  final UsuarioRepository _usuarioRepo = UsuarioRepository();
  
  List<Map<String, dynamic>> _logs = [];
  List<Map<String, dynamic>> _usuarios = [];
  bool _isLoading = true;
  
  int? _selectedUsuarioId;
  final _acaoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _usuarios = await _usuarioRepo.getAll();
    await _refreshLogs();
  }

  Future<void> _refreshLogs() async {
    final data = await _logRepo.getAllFiltered(
      codigoUsuario: _selectedUsuarioId,
      acao: _acaoController.text.trim(),
    );
    if (mounted) {
      setState(() {
        _logs = data;
        _isLoading = false;
      });
    }
  }

  String _formatarData(String? dataIso) {
    if (dataIso == null) return '--/-- --:--';
    try {
      final dt = DateTime.parse(dataIso);
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return dataIso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs do Sistema'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                DropdownButtonFormField<int?>(
                  value: _selectedUsuarioId,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por Usuário',
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos Usuários')),
                    ..._usuarios.map((u) => DropdownMenuItem(
                      value: u['codigo_usuario'] as int,
                      child: Text(u['nome']),
                    )),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedUsuarioId = val);
                    _refreshLogs();
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _acaoController,
                  decoration: const InputDecoration(
                    labelText: 'Buscar por Ação',
                    hintText: 'Ex: Criou, Editou, Acessou...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (_) => _refreshLogs(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? const Center(child: Text('Nenhum log encontrado.'))
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          return ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.history_edu)),
                            title: Text(log['acao'] ?? 'Sem ação'),
                            subtitle: Text(
                              'Por: ${log['usuario_nome']}\n'
                              'Em: ${_formatarData(log['criado_em'])}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.info_outline),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Detalhes do Log'),
                                    content: Text(log['detalhes'] ?? 'Nenhum detalhe adicional.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('FECHAR'),
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),
                            isThreeLine: true,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
