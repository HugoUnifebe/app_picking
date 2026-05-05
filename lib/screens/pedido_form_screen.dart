import 'package:flutter/material.dart';
import 'dart:math';
import '../models/pedido.dart';
import '../repositories/pedido_repository.dart';
import '../repositories/produto_repository.dart';
import 'scanner_screen.dart';

class PedidoFormScreen extends StatefulWidget {
  final int? pedidoId;

  const PedidoFormScreen({super.key, this.pedidoId});

  @override
  State<PedidoFormScreen> createState() => _PedidoFormScreenState();
}

class _PedidoFormScreenState extends State<PedidoFormScreen> {
  final PedidoRepository _pedidoRepo = PedidoRepository();
  final ProdutoRepository _produtoRepo = ProdutoRepository();
  final _caixaBarraController = TextEditingController();
  
  List<Map<String, dynamic>> _itens = [];
  List<Map<String, dynamic>> _statuses = [];
  
  bool _isLoading = true;
  int? _currentPedidoId;
  int? _selectedStatusId;
  DateTime? _finalizadoEm;

  @override
  void initState() {
    super.initState();
    _currentPedidoId = widget.pedidoId;
    _initData();
  }

  void _gerarCodigoAleatorio() {
    final random = Random();
    String codigo = '';
    for (int i = 0; i < 13; i++) {
      codigo += random.nextInt(10).toString();
    }
    setState(() {
      _caixaBarraController.text = codigo;
    });
  }

  Future<void> _escanearCodigo() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );

    if (result != null && mounted) {
      setState(() {
        _caixaBarraController.text = result;
      });
    }
  }

  @override
  void dispose() {
    _caixaBarraController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    
    _statuses = await _pedidoRepo.getStatuses();
    
    if (_currentPedidoId != null) {
      final pedidoData = await _pedidoRepo.getById(_currentPedidoId!);
      if (pedidoData != null) {
        _selectedStatusId = pedidoData['codigo_status_pedido'];
        _caixaBarraController.text = pedidoData['codigo_barra_caixa'] ?? '';
        _finalizadoEm = pedidoData['finalizado_em'] != null 
            ? DateTime.tryParse(pedidoData['finalizado_em'].toString()) 
            : null;
      }
      await _loadItems();
    } else {
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

    // Se o status mudou para Finalizado (3), definimos a data de finalização
    if (_selectedStatusId == 3 && _finalizadoEm == null) {
      _finalizadoEm = DateTime.now();
    } else if (_selectedStatusId != 3) {
      _finalizadoEm = null;
    }

    final pedido = Pedido(
      codigoPedido: _currentPedidoId,
      codigoStatusPedido: _selectedStatusId,
      codigoBarraCaixa: _caixaBarraController.text,
      finalizadoEm: _finalizadoEm,
      editadoEm: null, 
      criadoEm: null,
    );

    if (isNovo) {
      final id = await _pedidoRepo.insert(pedido);
      setState(() => _currentPedidoId = id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pedido criado!')));
        if (fecharTela) {
          Navigator.pop(context, true);
        }
      }
    } else {
      await _pedidoRepo.update(pedido);
      
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
        content: const Text('Tem certeza que deseja excluir este pedido?'),
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
                      TextFormField(
                        controller: _caixaBarraController,
                        decoration: InputDecoration(
                          labelText: 'Código de Barras da Caixa',
                          prefixIcon: const Icon(Icons.inventory),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.qr_code_scanner, color: Colors.blue),
                                tooltip: 'Escanear Código',
                                onPressed: _escanearCodigo,
                              ),
                              IconButton(
                                icon: const Icon(Icons.casino, color: Colors.orange),
                                tooltip: 'Gerar Aleatório',
                                onPressed: _gerarCodigoAleatorio,
                              ),
                            ],
                          ),
                        ),
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
