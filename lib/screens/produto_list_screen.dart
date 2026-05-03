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
  List<Produto> _allProdutos = [];
  List<Produto> _filteredProdutos = [];
  bool _isLoading = true;

  // Filtros
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
      _allProdutos = data;
      _applyFilters();
      _isLoading = false;
    });
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProdutos = _allProdutos.where((produto) {
        final matchNome = (produto.nomeProduto).toLowerCase().contains(query);
        final matchSku = (produto.sku ?? '').toLowerCase().contains(query);
        return matchNome || matchSku;
      }).toList();
    });
  }

  Future<void> _confirmarExclusao(Produto produto) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Produto'),
        content: Text('Deseja realmente excluir o produto "${produto.nomeProduto}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('EXCLUIR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && produto.codigoProduto != null) {
      await _repository.delete(produto.codigoProduto!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto excluído com sucesso!')),
        );
        _refreshList();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos'),
      ),
      body: Column(
        children: [
          // --- Barra de Filtros ---
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar por nome ou SKU...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
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
                : _filteredProdutos.isEmpty
                    ? const Center(child: Text('Nenhum produto encontrado.'))
                    : ListView.builder(
                        itemCount: _filteredProdutos.length,
                        itemBuilder: (context, index) {
                          final produto = _filteredProdutos[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.shopping_bag),
                              ),
                              title: Text(produto.nomeProduto),
                              subtitle: Text('SKU: ${produto.sku} | Local: ${produto.localizacao ?? "S/N"}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProdutoFormScreen(produto: produto),
                                        ),
                                      );
                                      if (result == true) _refreshList();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _confirmarExclusao(produto),
                                  ),
                                ],
                              ),
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
            MaterialPageRoute(builder: (context) => const ProdutoFormScreen()),
          );
          if (result == true) _refreshList();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
