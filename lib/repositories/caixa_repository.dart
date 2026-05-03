import '../database/database_helper.dart';
import '../models/caixa.dart';

class CaixaRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insert(Caixa caixa) async {
    final db = await _dbHelper.database;
    return await db.insert('caixa', caixa.toMap());
  }

  Future<List<Map<String, dynamic>>> getAllWithDetails() async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT c.*, s.descricao as status_nome, s.cor_hex
      FROM caixa c
      LEFT JOIN status_caixa s ON c.codigo_status_caixa = s.codigo_status_caixa
      ORDER BY c.nome_caixa ASC
    ''');
  }

  Future<int> update(Caixa caixa) async {
    final db = await _dbHelper.database;
    return await db.update(
      'caixa',
      caixa.toMap(),
      where: 'codigo_caixa = ?',
      whereArgs: [caixa.codigoCaixa],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'caixa',
      where: 'codigo_caixa = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getStatuses() async {
    final db = await _dbHelper.database;
    return await db.query('status_caixa');
  }
}
