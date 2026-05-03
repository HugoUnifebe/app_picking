import 'package:flutter/material.dart';
import 'cadastros_menu_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Lista de telas principais da barra inferior
  final List<Widget> _screens = [
    const HomeScreen(),
    const CadastrosMenuScreen(), // Agrupador de cadastros
    const PlaceholderScreen(title: 'Picking'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
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
  const HomeScreen({super.key});

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
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warehouse, size: 100, color: Colors.grey),
            const SizedBox(height: 20),
            Text(
              'Sistema de Picking',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF003399),
                  ),
            ),
            const SizedBox(height: 10),
            const Text('Selecione uma opção no menu inferior'),
          ],
        ),
      ),
    );
  }
}
