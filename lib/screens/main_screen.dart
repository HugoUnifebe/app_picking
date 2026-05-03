import 'package:flutter/material.dart';
import 'cadastros_menu_screen.dart';
import '../models/usuario.dart';
import 'scanner_screen.dart';
import '../repositories/usuario_repository.dart';

class MainScreen extends StatefulWidget {
  final Usuario usuarioLogado;
  const MainScreen({super.key, required this.usuarioLogado});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late Usuario _usuarioAtual;
  final UsuarioRepository _usuarioRepo = UsuarioRepository();

  @override
  void initState() {
    super.initState();
    _usuarioAtual = widget.usuarioLogado;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Função para trocar de usuário (Supervisor -> Operador)
  void _trocarParaOperador() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );

    if (barcode != null) {
      final operador = await _usuarioRepo.findOperatorByBarcode(barcode);
      
      if (operador != null) {
        setState(() {
          _usuarioAtual = operador;
          _selectedIndex = 0; // Volta para a home ao trocar
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Logado como Operador: ${operador.nome}')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Operador não encontrado ou código inválido!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definimos as telas aqui para garantir que o _usuarioAtual seja passado corretamente
    final List<Widget> screens = [
      HomeScreen(
        usuario: _usuarioAtual, 
        onSwitchUser: _usuarioAtual.codigoTipo == 1 ? _trocarParaOperador : null,
      ),
      const CadastrosMenuScreen(),
      const PlaceholderScreen(title: 'Picking'),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF003399),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cadastros'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_basket), label: 'Picking'),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final Usuario usuario;
  final VoidCallback? onSwitchUser;

  const HomeScreen({
    super.key, 
    required this.usuario, 
    this.onSwitchUser,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/logo_kyly.png',
          height: 40,
          errorBuilder: (context, error, stackTrace) => const Text('Grupo KYLY'),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/');
            },
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFFF5F5F5),
                child: Icon(
                  usuario.codigoTipo == 1 ? Icons.admin_panel_settings : Icons.person, 
                  size: 60, 
                  color: const Color(0xFF003399)
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Olá, ${usuario.nome}!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF003399),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                usuario.codigoTipo == 1 ? 'Perfil: Supervisor' : 'Perfil: Operador',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              
              // Botão de Trocar para Operador (SÓ APARECE SE FOR SUPERVISOR)
              if (onSwitchUser != null)
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: onSwitchUser,
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('LIBERAR OPERADOR', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                
              const SizedBox(height: 16),
              const Text(
                'Utilize o menu inferior para acessar as funcionalidades.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
