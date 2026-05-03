import '../database/database_helper.dart';
import '../models/pedido.dart';
import '../models/produto_pedido.dart';

class PedidoRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insert(Pedido pedido) async {
    final db = await _dbHelper.database;
    return await db.insert('pedido', pedido.toMap());
  }

  Future<List<Map<String, dynamic>>> getAllWithDetails() async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT p.*, s.descricao as status_nome, u.nome as responsavel_nome
      FROM pedido p
      LEFT JOIN status_pedido s ON p.codigo_status_pedido = s.codigo_status_pedido
      LEFT JOIN usuario u ON p.codigo_usuario_responsavel = u.codigo_usuario
      ORDER BY p.criado_em DESC
    ''');
  }

  Future<int> update(Pedido pedido) async {
    final db = await _dbHelper.database;
    return await db.update(
      'pedido',
      pedido.toMap(),
      where: 'codigo_pedido = ?',
      whereArgs: [pedido.codigoPedido],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    await db.delete('produto_pedido', where: 'codigo_pedido = ?', whereArgs: [id]);
    return await db.delete('pedido', where: 'codigo_pedido = ?', whereArgs: [id]);
  }

  Future<int> addItem(ProdutoPedido item) async {
    final db = await _dbHelper.database;
    return await db.insert('produto_pedido', item.toMap());
  }

  Future<List<Map<String, dynamic>>> getItems(int pedidoId) async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT pp.*, pr.nome_produto, pr.sku, pr.cor, pr.tamanho, pr.localizacao, pr.codigo_barra_produto, spr.descricao as status_item
      FROM produto_pedido pp
      JOIN produto pr ON pp.codigo_produto = pr.codigo_produto
      JOIN status_produto_pedido spr ON pp.codigo_status_produto_pedido = spr.codigo_status_produto_pedido
      WHERE pp.codigo_pedido = ?
    ''', [pedidoId]);
  }
}
