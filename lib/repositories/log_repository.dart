import '../database/database_helper.dart';
import '../models/log.dart';

class LogRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insert(Log log) async {
    final db = await _dbHelper.database;
    return await db.insert('logs', log.toMap());
  }

  Future<List<Map<String, dynamic>>> getAllFiltered({int? codigoUsuario, String? acao}) async {
    final db = await _dbHelper.database;
    
    String query = '''
      SELECT l.*, u.nome as usuario_nome
      FROM logs l
      JOIN usuario u ON l.codigo_usuario = u.codigo_usuario
    ''';
    
    List<String> conditions = [];
    List<dynamic> args = [];
    
    if (codigoUsuario != null) {
      conditions.add('l.codigo_usuario = ?');
      args.add(codigoUsuario);
    }
    
    if (acao != null && acao.isNotEmpty) {
      conditions.add('l.acao LIKE ?');
      args.add('%$acao%');
    }
    
    if (conditions.isNotEmpty) {
      query += ' WHERE ' + conditions.join(' AND ');
    }
    
    query += ' ORDER BY l.criado_em DESC';
    
    return await db.rawQuery(query, args);
  }
}
