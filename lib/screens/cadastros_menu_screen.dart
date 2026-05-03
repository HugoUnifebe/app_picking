import 'package:flutter/material.dart';
import 'produto_list_screen.dart';
import 'caixa_list_screen.dart';

class CadastrosMenuScreen extends StatelessWidget {
  const CadastrosMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastros e Gestão'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMenuTile(
            context,
            icon: Icons.inventory_2,
            title: 'Produtos',
            subtitle: 'Gerenciar catálogo de produtos e EANs',
            color: Colors.blue,
            destination: const ProdutoListScreen(),
          ),
          const SizedBox(height: 12),
          _buildMenuTile(
            context,
            icon: Icons.inventory,
            title: 'Caixas',
            subtitle: 'Configurar localizações e status de caixas',
            color: Colors.orange,
            destination: const CaixaListScreen(),
          ),
          const SizedBox(height: 12),
          _buildMenuTile(
            context,
            icon: Icons.list_alt,
            title: 'Pedidos',
            subtitle: 'Visualizar e criar novos pedidos de picking',
            color: Colors.green,
            destination: const PlaceholderScreen(title: 'Pedidos'),
          ),
          const SizedBox(height: 12),
          _buildMenuTile(
            context,
            icon: Icons.history,
            title: 'Ver Logs',
            subtitle: 'Histórico de atividades do sistema',
            color: Colors.red,
            destination: const PlaceholderScreen(title: 'Logs'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Widget destination,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        },
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Funcionalidade $title em desenvolvimento')),
    );
  }
}
