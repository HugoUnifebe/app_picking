import '../database/database_helper.dart';
import '../models/produto.dart';

class ProdutoRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insert(Produto produto) async {
    final db = await _dbHelper.database;
    return await db.insert('produto', produto.toMap());
  }

  Future<List<Produto>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('produto');

    return List.generate(maps.length, (i) {
      return Produto.fromMap(maps[i]);
    });
  }

  Future<Produto?> getByBarcode(String barcode) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'produto',
      where: 'codigo_barra_produto = ?',
      whereArgs: [barcode],
    );

    if (maps.isNotEmpty) {
      return Produto.fromMap(maps.first);
    }
    return null;
  }

  Future<Produto?> getBySku(String sku) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'produto',
      where: 'sku = ?',
      whereArgs: [sku],
    );

    if (maps.isNotEmpty) {
      return Produto.fromMap(maps.first);
    }
    return null;
  }

  Future<int> update(Produto produto) async {
    final db = await _dbHelper.database;
    return await db.update(
      'produto',
      produto.toMap(),
      where: 'codigo_produto = ?',
      whereArgs: [produto.codigoProduto],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'produto',
      where: 'codigo_produto = ?',
      whereArgs: [id],
    );
  }
}
