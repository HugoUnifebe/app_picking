import 'package:flutter/material.dart';
import '../models/caixa.dart';
import '../repositories/caixa_repository.dart';

class CaixaFormScreen extends StatefulWidget {
  final Caixa? caixa;

  const CaixaFormScreen({super.key, this.caixa});

  @override
  State<CaixaFormScreen> createState() => _CaixaFormScreenState();
}

class _CaixaFormScreenState extends State<CaixaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _localizacaoController = TextEditingController();
  final CaixaRepository _repository = CaixaRepository();
  
  List<Map<String, dynamic>> _statuses = [];
  int? _selectedStatusId;
  bool _isLoadingStatuses = true;

  @override
  void initState() {
    super.initState();
    if (widget.caixa != null) {
      _nomeController.text = widget.caixa!.nomeCaixa;
      _localizacaoController.text = widget.caixa!.localizacao;
      _selectedStatusId = widget.caixa!.codigoStatusCaixa;
    }
    _loadStatuses();
  }

  Future<void> _loadStatuses() async {
    final data = await _repository.getStatuses();
    setState(() {
      _statuses = data;
      _isLoadingStatuses = false;
      if (_selectedStatusId == null && _statuses.isNotEmpty) {
        try {
          _selectedStatusId = _statuses.firstWhere((s) => s['descricao'] == 'Livre')['codigo_status_caixa'];
        } catch (e) {
          _selectedStatusId = _statuses.first['codigo_status_caixa'];
        }
      }
    });
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _localizacaoController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final caixa = Caixa(
        codigoCaixa: widget.caixa?.codigoCaixa,
        nomeCaixa: _nomeController.text,
        codigoStatusCaixa: _selectedStatusId,
        localizacao: _localizacaoController.text,
        criadoEm: widget.caixa?.criadoEm ?? DateTime.now(),
        editadoEm: DateTime.now(),
      );

      if (widget.caixa == null) {
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
        title: Text(widget.caixa == null ? 'Nova Caixa' : 'Editar Caixa'),
      ),
      body: _isLoadingStatuses 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome da Caixa',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value!.isEmpty ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _localizacaoController,
                    decoration: const InputDecoration(
                      labelText: 'Localização / Identificação',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value!.isEmpty ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _selectedStatusId,
                    decoration: const InputDecoration(
                      labelText: 'Status da Caixa',
                      border: OutlineInputBorder(),
                    ),
                    items: _statuses.map((status) {
                      final colorHex = status['cor_hex'] ?? 'CCCCCC';
                      return DropdownMenuItem<int>(
                        value: status['codigo_status_caixa'],
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Color(int.parse('FF$colorHex', radix: 16)),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(status['descricao']),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStatusId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 30),
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
