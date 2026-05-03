import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../repositories/usuario_repository.dart';
import 'scanner_screen.dart';

class UsuarioFormScreen extends StatefulWidget {
  final int? usuarioId;

  const UsuarioFormScreen({super.key, this.usuarioId});

  @override
  State<UsuarioFormScreen> createState() => _UsuarioFormScreenState();
}

class _UsuarioFormScreenState extends State<UsuarioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final UsuarioRepository _repository = UsuarioRepository();
  
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _barcodeController = TextEditingController();
  
  int _selectedTipoId = 2; // Default Operador
  bool _isAtivo = true;
  bool _isLoading = true;
  List<Map<String, dynamic>> _tipos = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _tipos = await _repository.getTipos();
    
    if (widget.usuarioId != null) {
      final userMap = await _repository.getById(widget.usuarioId!);
      if (userMap != null) {
        _nomeController.text = userMap['nome'] ?? '';
        _emailController.text = userMap['email'] ?? '';
        _barcodeController.text = userMap['codigo_barra_usuario'] ?? '';
        _selectedTipoId = userMap['codigo_tipo'] ?? 2;
        _isAtivo = userMap['ativo'] == 1;
      }
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final user = Usuario(
        codigoUsuario: widget.usuarioId,
        nome: _nomeController.text,
        email: _emailController.text,
        codigoBarraUsuario: _barcodeController.text,
        codigoTipo: _selectedTipoId,
        ativo: _isAtivo ? 1 : 0,
        criadoEm: widget.usuarioId == null ? DateTime.now().toIso8601String() : null,
        editadoEm: DateTime.now().toIso8601String(),
      );

      if (widget.usuarioId == null) {
        await _repository.insert(user);
      } else {
        await _repository.update(user);
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
        title: Text(widget.usuarioId == null ? 'Novo Usuário' : 'Editar Usuário'),
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
                      decoration: const InputDecoration(labelText: 'Nome Completo'),
                      validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _barcodeController,
                      decoration: InputDecoration(
                        labelText: 'Código de Barras (Crachá)',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner),
                          onPressed: () async {
                            final barcode = await Navigator.push<String>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ScannerScreen(),
                              ),
                            );
                            if (barcode != null) {
                              setState(() {
                                _barcodeController.text = barcode;
                              });
                            }
                          },
                        ),
                      ),
                      validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedTipoId,
                      decoration: const InputDecoration(labelText: 'Tipo de Usuário'),
                      items: _tipos.map((t) => DropdownMenuItem(
                        value: t['codigo_tipo'] as int,
                        child: Text(t['nome']),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedTipoId = val!),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Usuário Ativo'),
                      value: _isAtivo,
                      onChanged: (val) => setState(() => _isAtivo = val),
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
                        child: const Text('SALVAR USUÁRIO'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
