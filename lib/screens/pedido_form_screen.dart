import 'package:flutter/material.dart';
import '../models/pedido.dart';
import '../repositories/pedido_repository.dart';
import '../repositories/produto_repository.dart';
import '../repositories/caixa_repository.dart';

class PedidoFormScreen extends StatefulWidget {
  final int? pedidoId;

  const PedidoFormScreen({super.key, this.pedidoId});

  @override
  State<PedidoFormScreen> createState() => _PedidoFormScreenState();
}

class _PedidoFormScreenState extends State<PedidoFormScreen> {
  final PedidoRepository _pedidoRepo = PedidoRepository();
  final ProdutoRepository _produtoRepo = ProdutoRepository();
  final CaixaRepository _caixaRepo = CaixaRepository();
  
  List<Map<String, dynamic>> _itens = [];
  List<Map<String, dynamic>> _statuses = [];
  List<Map<String, dynamic>> _caixas = [];
  
  bool _isLoading = true;
  int? _currentPedidoId;
  int? _selectedStatusId;
  int? _selectedCaixaId;
  int? _originalCaixaId;

  @override
  void initState() {
    super.initState();
    _currentPedidoId = widget.pedidoId;
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    
    _statuses = await _pedidoRepo.getStatuses();
    
    if (_currentPedidoId != null) {
      final pedidoData = await _pedidoRepo.getById(_currentPedidoId!);
      if (pedidoData != null) {
        _selectedStatusId = pedidoData['codigo_status_pedido'];
        _selectedCaixaId = pedidoData['codigo_caixa'];
        _originalCaixaId = _selectedCaixaId;
      }
      _caixas = await _caixaRepo.getFreeBoxes(includeCaixaId: _selectedCaixaId);
      await _loadItems();
    } else {
      _caixas = await _caixaRepo.getFreeBoxes();
      if (_statuses.isNotEmpty) _selectedStatusId = _statuses.first['codigo_status_pedido'];
      _isLoading = false;
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadItems() async {
    if (_currentPedidoId == null) return;
    final items = await _pedidoRepo.getItems(_currentPedidoId!);
    if (mounted) {
      setState(() {
        _itens = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _savePedido({bool fecharTela = false}) async {
    final isNovo = _currentPedidoId == null;

    final pedido = Pedido(
      codigoPedido: _currentPedidoId,
      codigoStatusPedido: _selectedStatusId,
      codigoCaixa: _selectedCaixaId,
      editadoEm: DateTime.now(),
      criadoEm: isNovo ? DateTime.now() : null,
    );

    if (isNovo) {
      final id = await _pedidoRepo.insert(pedido);
      setState(() => _currentPedidoId = id);
      
      if (_selectedCaixaId != null) {
        await _caixaRepo.updateStatus(_selectedCaixaId!, 2);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pedido criado!')));
        if (fecharTela) {
          Navigator.pop(context, true);
        }
      }
    } else {
      await _pedidoRepo.update(pedido);
      
      if (_selectedStatusId == 3 && _selectedCaixaId != null) {
        await _caixaRepo.updateStatus(_selectedCaixaId!, 1);
      } else if (_selectedCaixaId != _originalCaixaId) {
        if (_originalCaixaId != null) {
          await _caixaRepo.updateStatus(_originalCaixaId!, 1);
        }
        if (_selectedCaixaId != null) {
          await _caixaRepo.updateStatus(_selectedCaixaId!, 2);
        }
        _originalCaixaId = _selectedCaixaId;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pedido atualizado!')));
        if (fecharTela) {
          Navigator.pop(context, true);
        }
      }
    }
  }

  Future<void> _excluirPedido() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Pedido'),
        content: const Text('Tem certeza que deseja excluir este pedido? A caixa vinculada será liberada.'),
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

    if (confirm == true && _currentPedidoId != null) {
      if (_selectedCaixaId != null) {
        await _caixaRepo.updateStatus(_selectedCaixaId!, 1);
      }
      await _pedidoRepo.delete(_currentPedidoId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pedido excluído com sucesso!')));
        Navigator.pop(context, true);
      }
    }
  }

  void _adicionarProduto() async {
    if (_currentPedidoId == null) {
      await _savePedido(fecharTela: false);
    }

    final produtos = await _produtoRepo.getAll();
    if (produtos.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cadastre produtos primeiro!')));
      return;
    }

    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _SeletorProdutoModal(
          produtos: produtos,
          onSelected: (produtoId) async {
            await _pedidoRepo.addItem(_currentPedidoId!, produtoId);
            _loadItems();
          },
        ),
      );
    }
  }

  void _removerProduto(Map<String, dynamic> item) async {
    await _pedidoRepo.removeItem(
      item['codigo_pedido'], 
      item['codigo_produto'], 
      item['codigo_produto_pedido']
    );
    _loadItems();
  }

  void _alterarStatusItem(Map<String, dynamic> item) async {
    final statuses = await _pedidoRepo.getItemStatuses();
    
    if (mounted) {
      showModalBottomSheet(
        context: context,
        builder: (context) => Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Alterar Status do Item',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...statuses.map((s) {
                final colorHex = s['cor_hex'] ?? 'CCCCCC';
                final color = Color(int.parse('FF$colorHex', radix: 16));
                return ListTile(
                  leading: CircleAvatar(backgroundColor: color, radius: 12),
                  title: Text(s['descricao']),
                  onTap: () async {
                    await _pedidoRepo.updateItemStatus(
                      item['codigo_pedido'],
                      item['codigo_produto'],
                      item['codigo_produto_pedido'],
                      s['codigo_status_produto_pedido'],
                    );
                    Navigator.pop(context);
                    _loadItems();
                  },
                );
              }).toList(),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentPedidoId == null ? 'Novo Pedido' : 'Pedido #$_currentPedidoId'),
        actions: [
          if (_currentPedidoId != null) ...[
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _excluirPedido,
            ),
            IconButton(
              icon: const Icon(Icons.save, color: Colors.blue),
              onPressed: () => _savePedido(fecharTela: true),
            ),
          ]
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Column(
                    children: [
                      DropdownButtonFormField<int>(
                        value: _selectedStatusId,
                        decoration: const InputDecoration(labelText: 'Status do Pedido'),
                        items: _statuses.map((s) => DropdownMenuItem(
                          value: s['codigo_status_pedido'] as int,
                          child: Text(s['descricao']),
                        )).toList(),
                        onChanged: (val) => setState(() => _selectedStatusId = val),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: _selectedCaixaId,
                        decoration: const InputDecoration(labelText: 'Caixa / Carrinho'),
                        items: _caixas.map((c) => DropdownMenuItem(
                          value: c['codigo_caixa'] as int,
                          child: Text('${c['nome_caixa'] ?? "S/N"} (${c['localizacao'] ?? ""})'),
                        )).toList(),
                        onChanged: (val) => setState(() => _selectedCaixaId = val),
                      ),
                    ],
                  ),
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('PRODUTOS NO PEDIDO', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),

                Expanded(
                  child: _itens.isEmpty
                      ? const Center(child: Text('Nenhum produto adicionado.'))
                      : ListView.builder(
                          itemCount: _itens.length,
                          itemBuilder: (context, index) {
                            final item = _itens[index];
                            final colorHex = item['status_item_cor'] ?? 'CCCCCC';
                            final color = Color(int.parse('FF$colorHex', radix: 16));
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: ListTile(
                                onTap: () => _alterarStatusItem(item),
                                leading: Container(
                                  width: 8,
                                  height: double.infinity,
                                  decoration: BoxDecoration(
                                    color: color,
                                    border: color == Colors.white 
                                      ? Border.all(color: Colors.grey[300]!) 
                                      : null,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                title: Text(item['nome_produto'] ?? 'Sem nome'),
                                subtitle: Text(
                                  'SKU: ${item['sku']} | Cor: ${item['cor']}\n'
                                  'Status: ${item['status_item_nome']}',
                                  style: TextStyle(
                                    color: item['status_item_nome'] == 'Não está na caixa' 
                                      ? Colors.grey[600] 
                                      : Colors.black87,
                                    fontWeight: item['status_item_nome'] != 'Não está na caixa'
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  ),
                                ),
                                isThreeLine: true,
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                  onPressed: () => _removerProduto(item),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _adicionarProduto,
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('ADICIONAR PRODUTO'),
      ),
    );
  }
}

// --- Widget Interno para o Modal de Seleção de Produtos com Filtro ---
class _SeletorProdutoModal extends StatefulWidget {
  final List<dynamic> produtos;
  final Function(int) onSelected;

  const _SeletorProdutoModal({required this.produtos, required this.onSelected});

  @override
  State<_SeletorProdutoModal> createState() => _SeletorProdutoModalState();
}

class _SeletorProdutoModalState extends State<_SeletorProdutoModal> {
  final _searchController = TextEditingController();
  List<dynamic> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.produtos;
  }

  void _filter(String q) {
    setState(() {
      _filtered = widget.produtos.where((p) {
        final query = q.toLowerCase();
        return p.nomeProduto.toLowerCase().contains(query) || 
               (p.sku ?? '').toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          const Text('Selecione o Produto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Filtrar por nome ou SKU...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            onChanged: _filter,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _filtered.isEmpty
              ? const Center(child: Text('Nenhum produto encontrado.'))
              : ListView.builder(
                  itemCount: _filtered.length,
                  itemBuilder: (context, index) {
                    final p = _filtered[index];
                    return ListTile(
                      title: Text(p.nomeProduto),
                      subtitle: Text('${p.sku} | Cor: ${p.cor}'),
                      onTap: () {
                        widget.onSelected(p.codigoProduto!);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
