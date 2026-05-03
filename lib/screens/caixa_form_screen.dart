import 'package:flutter/material.dart';
import '../models/caixa.dart';
import '../repositories/caixa_repository.dart';

class CaixaFormScreen extends StatefulWidget {
  final int? caixaId;
  const CaixaFormScreen({super.key, this.caixaId});

  @override
  State<CaixaFormScreen> createState() => _CaixaFormScreenState();
}

class _CaixaFormScreenState extends State<CaixaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final CaixaRepository _repository = CaixaRepository();
  
  final _nomeController = TextEditingController();
  final _localizacaoController = TextEditingController();
  
  int _selectedStatusId = 1; // Default Livre
  bool _isLoading = true;
  List<Map<String, dynamic>> _statuses = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _statuses = await _repository.getStatuses();
    
    if (widget.caixaId != null) {
      // Busca os dados da caixa pelo ID
      final allCaixas = await _repository.getAllWithDetails();
      final caixaMap = allCaixas.firstWhere(
        (c) => c['codigo_caixa'] == widget.caixaId,
        orElse: () => {},
      );

      if (caixaMap.isNotEmpty) {
        _nomeController.text = caixaMap['nome_caixa'] ?? '';
        _localizacaoController.text = caixaMap['localizacao'] ?? '';
        _selectedStatusId = caixaMap['codigo_status_caixa'] ?? 1;
      }
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final caixa = Caixa(
        codigoCaixa: widget.caixaId,
        nomeCaixa: _nomeController.text,
        codigoStatusCaixa: _selectedStatusId,
        localizacao: _localizacaoController.text,
        criadoEm: widget.caixaId == null ? DateTime.now() : null,
        editadoEm: DateTime.now(),
      );

      if (widget.caixaId == null) {
        await _repository.insert(caixa);
      } else {
        await _repository.update(caixa);
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
        title: Text(widget.caixaId == null ? 'Nova Caixa' : 'Editar Caixa'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(labelText: 'Nome da Caixa'),
                      validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _localizacaoController,
                      decoration: const InputDecoration(labelText: 'Localização / Endereço'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedStatusId,
                      decoration: const InputDecoration(labelText: 'Status da Caixa'),
                      items: _statuses.map((s) => DropdownMenuItem(
                        value: s['codigo_status_caixa'] as int,
                        child: Text(s['descricao']),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedStatusId = val!),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003399),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('SALVAR CAIXA'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
