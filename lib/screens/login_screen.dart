import 'package:flutter/material.dart';
import 'scanner_screen.dart';
import '../repositories/usuario_repository.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final UsuarioRepository _usuarioRepo = UsuarioRepository();
  bool _isLoading = false;

  void _handleLogin() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );

    if (barcode != null) {
      setState(() => _isLoading = true);
      
      final usuario = await _usuarioRepo.loginByBarcode(barcode);
      
      setState(() => _isLoading = false);

      if (usuario != null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainScreen(usuarioLogado: usuario),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Acesso restrito a Supervisores ou usuário não encontrado!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo_kyly.png', height: 80, errorBuilder: (context, error, stackTrace) => const Icon(Icons.warehouse, size: 80, color: Color(0xFF003399))),
              const SizedBox(height: 48),
              const Text(
                'Bem-vindo ao Picking',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF003399)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Escaneie seu crachá para entrar',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: _handleLogin,
                    icon: const Icon(Icons.qr_code_scanner, size: 28),
                    label: const Text('ESCANEAR CRACHÁ', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003399),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
