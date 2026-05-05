import 'package:flutter/material.dart';
import 'scanner_screen.dart';
import '../repositories/pedido_repository.dart';
import 'picking_execution_screen.dart';
import '../models/usuario.dart';
import '../models/pedido.dart';

class PickingStartScreen extends StatefulWidget {
  final Usuario usuario;
  const PickingStartScreen({super.key, required this.usuario});

  @override
  State<PickingStartScreen> createState() => PickingStartScreenState();
}

class PickingStartScreenState extends State<PickingStartScreen> {
  final PedidoRepository _pedidoRepo = PedidoRepository();

  Future<void> _vincularUsuarioAoPedido(int pedidoId) async {
    final pedidoMap = await _pedidoRepo.getById(pedidoId);
    if (pedidoMap != null) {
      final pedido = Pedido.fromMap(pedidoMap);
      final pedidoAtualizado = Pedido(
        codigoPedido: pedido.codigoPedido,
        codigoUsuarioResponsavel: widget.usuario.codigoUsuario,
        codigoBarraCaixa: pedido.codigoBarraCaixa,
        codigoStatusPedido: pedido.codigoStatusPedido,
        criadoEm: pedido.criadoEm,
        finalizadoEm: pedido.finalizadoEm,
      );
      await _pedidoRepo.update(pedidoAtualizado);
    }
  }

  Future<void> _abrirCaixa() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );

    if (barcode != null) {
      final pedido = await _pedidoRepo.getByBoxBarcode(barcode);
      
      if (pedido != null) {
        if (mounted) {
          if (pedido['codigo_usuario_responsavel'] == null) {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Vincular Responsável'),
                content: const Text('Não há responsável por este pedido. Deseja tornar-se o responsável?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('NÃO'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('SIM'),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await _vincularUsuarioAoPedido(pedido['codigo_pedido']);
            } else {
              return; // Volta para a tela de picking (que é esta mesma tela)
            }
          }

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PickingExecutionScreen(pedidoId: pedido['codigo_pedido']),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Papeleta/Caixa não encontrada!'),
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
      appBar: AppBar(
        title: const Text('Execução de Picking'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inventory, size: 100, color: Color(0xFF003399)),
              const SizedBox(height: 32),
              const Text(
                'Bipe a Papeleta para Iniciar',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Aponte o laser para o código de barras da caixa para abrir a fila de coleta.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 80,
                child: ElevatedButton.icon(
                  onPressed: _abrirCaixa,
                  icon: const Icon(Icons.qr_code_scanner, size: 32),
                  label: const Text('ABRIR CAIXA', style: TextStyle(fontSize: 20)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003399),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
