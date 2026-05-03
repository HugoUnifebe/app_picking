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

  Future<List<Map<String, dynamic>>> getFreeBoxes({int? includeCaixaId}) async {
    final db = await _dbHelper.database;
    
    if (includeCaixaId != null) {
      // Busca caixas 'Livre' OU a caixa específica que já está no pedido (mesmo que esteja 'Ocupado')
      return await db.rawQuery('''
        SELECT c.*, s.descricao as status_nome, s.cor_hex
        FROM caixa c
        JOIN status_caixa s ON c.codigo_status_caixa = s.codigo_status_caixa
        WHERE s.descricao = 'Livre' OR c.codigo_caixa = ?
        ORDER BY c.nome_caixa ASC
      ''', [includeCaixaId]);
    }

    return await db.rawQuery('''
      SELECT c.*, s.descricao as status_nome, s.cor_hex
      FROM caixa c
      JOIN status_caixa s ON c.codigo_status_caixa = s.codigo_status_caixa
      WHERE s.descricao = 'Livre'
      ORDER BY c.nome_caixa ASC
    ''');
  }

  Future<void> updateStatus(int caixaId, int statusId) async {
    final db = await _dbHelper.database;
    await db.update(
      'caixa',
      {'codigo_status_caixa': statusId, 'editado_em': DateTime.now().toIso8601String()},
      where: 'codigo_caixa = ?',
      whereArgs: [caixaId],
    );
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
