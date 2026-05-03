import 'package:flutter/material.dart';
import '../repositories/caixa_repository.dart';
import '../models/caixa.dart';
import 'caixa_form_screen.dart';

class CaixaListScreen extends StatefulWidget {
  const CaixaListScreen({super.key});

  @override
  State<CaixaListScreen> createState() => _CaixaListScreenState();
}

class _CaixaListScreenState extends State<CaixaListScreen> {
  final CaixaRepository _repository = CaixaRepository();
  List<Map<String, dynamic>> _caixas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  Future<void> _refreshList() async {
    setState(() => _isLoading = true);
    final data = await _repository.getAllWithDetails();
    setState(() {
      _caixas = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Caixas'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _caixas.isEmpty
              ? const Center(child: Text('Nenhuma caixa cadastrada.'))
              : ListView.builder(
                  itemCount: _caixas.length,
                  itemBuilder: (context, index) {
                    final caixaMap = _caixas[index];
                    final colorHex = caixaMap['cor_hex'] ?? 'CCCCCC';
                    final color = Color(int.parse('FF$colorHex', radix: 16));
                    // Define a cor do ícone: preto se o fundo for branco (Desativado), branco caso contrário
                    final iconColor = colorHex.toUpperCase() == 'FFFFFF' ? Colors.grey : Colors.white;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color,
                          child: Icon(Icons.inventory, color: iconColor),
                        ),
                        title: Text(caixaMap['nome_caixa'] ?? 'Sem nome'),
                        subtitle: Text('Local: ${caixaMap['localizacao']}\nStatus: ${caixaMap['status_nome']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CaixaFormScreen(
                                      caixa: Caixa.fromMap(caixaMap),
                                    ),
                                  ),
                                );
                                if (result == true) _refreshList();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteDialog(caixaMap['codigo_caixa'], caixaMap['nome_caixa'] ?? ''),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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

  void _showDeleteDialog(int id, String nome) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Caixa'),
        content: Text('Deseja realmente excluir a caixa $nome?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () async {
              await _repository.delete(id);
              if (mounted) Navigator.pop(context);
              _refreshList();
            },
            child: const Text('EXCLUIR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
