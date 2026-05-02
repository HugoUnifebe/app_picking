import 'package:flutter/material.dart';
import '../models/produto.dart';
import '../repositories/produto_repository.dart';
import 'scanner_screen.dart';

class ProdutoFormScreen extends StatefulWidget {
  final Produto? produto;

  const ProdutoFormScreen({super.key, this.produto});

  @override
  State<ProdutoFormScreen> createState() => _ProdutoFormScreenState();
}

class _ProdutoFormScreenState extends State<ProdutoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _barcodeController = TextEditingController();
  final _skuController = TextEditingController();
  final _corController = TextEditingController();
  final _tamanhoController = TextEditingController();
  final _quantidadeController = TextEditingController();
  final _variacaoController = TextEditingController();
  final _localizacaoController = TextEditingController();

  final ProdutoRepository _repository = ProdutoRepository();

  @override
  void initState() {
    super.initState();
    if (widget.produto != null) {
      _barcodeController.text = widget.produto!.codigoBarraProduto ?? '';
      _skuController.text = widget.produto!.sku;
      _corController.text = widget.produto!.cor;
      _tamanhoController.text = widget.produto!.tamanho;
      _quantidadeController.text = widget.produto!.quantidadeDisponivel.toString();
      _variacaoController.text = widget.produto!.variacao;
      _localizacaoController.text = widget.produto!.localizacao;
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _skuController.dispose();
    _corController.dispose();
    _tamanhoController.dispose();
    _quantidadeController.dispose();
    _variacaoController.dispose();
    _localizacaoController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final produto = Produto(
        codigoProduto: widget.produto?.codigoProduto,
        codigoBarraProduto: _barcodeController.text,
        sku: _skuController.text,
        cor: _corController.text,
        tamanho: _tamanhoController.text,
        quantidadeDisponivel: int.parse(_quantidadeController.text),
        variacao: _variacaoController.text,
        localizacao: _localizacaoController.text,
      );

      if (widget.produto == null) {
        await _repository.insert(produto);
      } else {
        await _repository.update(produto);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.produto == null ? 'Novo Produto' : 'Editar Produto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _barcodeController,
                decoration: InputDecoration(
                  labelText: 'Código de Barras',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ScannerScreen()),
                      );
                      if (result != null) {
                        setState(() {
                          _barcodeController.text = result;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _skuController,
                decoration: const InputDecoration(labelText: 'SKU', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _corController,
                decoration: const InputDecoration(labelText: 'Cor', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tamanhoController,
                decoration: const InputDecoration(labelText: 'Tamanho', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantidadeController,
                decoration: const InputDecoration(labelText: 'Quantidade Disponível', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _variacaoController,
                decoration: const InputDecoration(labelText: 'Variação', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _localizacaoController,
                decoration: const InputDecoration(labelText: 'Localização', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('SALVAR', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
