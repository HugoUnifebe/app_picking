import '../database/database_helper.dart';
import '../models/pedido.dart';
import '../models/produto_pedido.dart';

class PedidoRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insert(Pedido pedido) async {
    final db = await _dbHelper.database;
    final Map<String, dynamic> data = pedido.toMap();
    
    // GARANTIA EXTRA: Se por algum motivo o model não gerou a data, 
    // ou o nome da chave divergir, forçamos aqui no repositório.
    data['criado_em'] = DateTime.now().toIso8601String();
    data['editado_em'] = DateTime.now().toIso8601String();
    
    return await db.insert('pedido', data);
  }

  Future<List<Map<String, dynamic>>> getAllWithDetails() async {
    final db = await _dbHelper.database;
    // Selecionamos explicitamente p.criado_em para não haver dúvida
    return await db.rawQuery('''
      SELECT 
        p.codigo_pedido, 
        p.codigo_usuario_responsavel, 
        p.codigo_status_pedido, 
        p.codigo_caixa, 
        p.criado_em, 
        p.editado_em,
        s.descricao as status_nome, 
        s.cor_hex as status_cor, 
        u.nome as responsavel_nome, 
        c.nome_caixa
      FROM pedido p
      LEFT JOIN status_pedido s ON p.codigo_status_pedido = s.codigo_status_pedido
      LEFT JOIN usuario u ON p.codigo_usuario_responsavel = u.codigo_usuario
      LEFT JOIN caixa c ON p.codigo_caixa = c.codigo_caixa
      ORDER BY p.criado_em DESC
    ''');
  }

  Future<Map<String, dynamic>?> getById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT p.*, s.descricao as status_nome, c.nome_caixa
      FROM pedido p
      LEFT JOIN status_pedido s ON p.codigo_status_pedido = s.codigo_status_pedido
      LEFT JOIN caixa c ON p.codigo_caixa = c.codigo_caixa
      WHERE p.codigo_pedido = ?
    ''', [id]);
    
    if (results.isNotEmpty) return results.first;
    return null;
  }

  Future<int> update(Pedido pedido) async {
    final db = await _dbHelper.database;
    final Map<String, dynamic> data = pedido.toMap();
    
    // Na atualização, removemos o criado_em para não sobrescrever o original com NULL
    // se o objeto pedido não o tiver carregado corretamente.
    data.remove('criado_em');
    data['editado_em'] = DateTime.now().toIso8601String();

    return await db.update(
      'pedido',
      data,
      where: 'codigo_pedido = ?',
      whereArgs: [pedido.codigoPedido],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    await db.delete('produto_pedido', where: 'codigo_pedido = ?', whereArgs: [id]);
    return await db.delete('pedido', where: 'codigo_pedido = ?', whereArgs: [id]);
  }

  // --- Lógica de Itens do Pedido (produto_pedido) ---

  Future<void> addItem(int pedidoId, int produtoId) async {
    final db = await _dbHelper.database;
    
    final List<Map<String, dynamic>> maxResult = await db.rawQuery(
      'SELECT MAX(codigo_produto_pedido) as max_id FROM produto_pedido WHERE codigo_pedido = ?',
      [pedidoId]
    );
    
    int nextId = (maxResult.first['max_id'] ?? 0) + 1;

    await db.insert('produto_pedido', {
      'codigo_produto_pedido': nextId,
      'codigo_pedido': pedidoId,
      'codigo_produto': produtoId,
      'codigo_status_produto_pedido': 1, // 1 = "Não está na caixa" (Branco)
    });
  }

  Future<void> removeItem(int pedidoId, int produtoId, int itemSeq) async {
    final db = await _dbHelper.database;
    await db.delete(
      'produto_pedido',
      where: 'codigo_pedido = ? AND codigo_produto = ? AND codigo_produto_pedido = ?',
      whereArgs: [pedidoId, produtoId, itemSeq],
    );
  }

  Future<List<Map<String, dynamic>>> getItems(int pedidoId) async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT pp.*, pr.nome_produto, pr.sku, pr.cor, pr.tamanho, pr.localizacao, spr.descricao as status_item_nome, spr.cor_hex as status_item_cor
      FROM produto_pedido pp
      JOIN produto pr ON pp.codigo_produto = pr.codigo_produto
      JOIN status_produto_pedido spr ON pp.codigo_status_produto_pedido = spr.codigo_status_produto_pedido
      WHERE pp.codigo_pedido = ?
      ORDER BY pp.codigo_produto_pedido ASC
    ''', [pedidoId]);
  }

  Future<List<Map<String, dynamic>>> getStatuses() async {
    final db = await _dbHelper.database;
    return await db.query('status_pedido');
  }

  Future<void> updateItemStatus(int pedidoId, int produtoId, int itemSeq, int statusId) async {
    final db = await _dbHelper.database;
    await db.update(
      'produto_pedido',
      {'codigo_status_produto_pedido': statusId},
      where: 'codigo_pedido = ? AND codigo_produto = ? AND codigo_produto_pedido = ?',
      whereArgs: [pedidoId, produtoId, itemSeq],
    );
  }

  Future<List<Map<String, dynamic>>> getItemStatuses() async {
    final db = await _dbHelper.database;
    return await db.query('status_produto_pedido');
  }
}
