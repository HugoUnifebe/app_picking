import 'package:flutter/material.dart';
import '../models/produto.dart';
import '../repositories/produto_repository.dart';
import 'produto_form_screen.dart';

class ProdutoListScreen extends StatefulWidget {
  const ProdutoListScreen({super.key});

  @override
  State<ProdutoListScreen> createState() => _ProdutoListScreenState();
}

class _ProdutoListScreenState extends State<ProdutoListScreen> {
  final ProdutoRepository _repository = ProdutoRepository();
  List<Produto> _produtos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  Future<void> _refreshList() async {
    setState(() => _isLoading = true);
    final data = await _repository.getAll();
    setState(() {
      _produtos = data;
      _isLoading = false;
    });
  }

  void _deleteProduto(int id) async {
    await _repository.delete(id);
    _refreshList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _produtos.isEmpty
              ? const Center(child: Text('Nenhum produto cadastrado.'))
              : ListView.builder(
                  itemCount: _produtos.length,
                  itemBuilder: (context, index) {
                    final produto = _produtos[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text('${produto.nomeProduto}'),
                        subtitle: Text('SKU: ${produto.sku} | Cor: ${produto.cor}\nEAN: ${produto.codigoBarraProduto ?? "N/A"}\nTam: ${produto.tamanho} | Qtd: ${produto.quantidadeDisponivel}\nLoc: ${produto.localizacao}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => ProdutoFormScreen(produto: produto)),
                                );
                                if (result == true) _refreshList();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteDialog(produto),
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
            MaterialPageRoute(builder: (context) => const ProdutoFormScreen()),
          );
          if (result == true) _refreshList();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteDialog(Produto produto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Produto'),
        content: Text('Deseja realmente excluir o produto ${produto.sku}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () {
              _deleteProduto(produto.codigoProduto!);
              Navigator.pop(context);
            },
            child: const Text('EXCLUIR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
