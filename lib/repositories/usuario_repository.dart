import '../database/database_helper.dart';
import '../models/usuario.dart';

class UsuarioRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Usuario?> loginByBarcode(String barcode) async {
    final db = await _dbHelper.database;
    
    // Filtramos especificamente por Supervisor (codigo_tipo = 1)
    final List<Map<String, dynamic>> maps = await db.query(
      'usuario',
      where: 'codigo_barra_usuario = ? AND ativo = 1 AND codigo_tipo = 1',
      whereArgs: [barcode.trim()],
    );

    if (maps.isNotEmpty) {
      return Usuario.fromMap(maps.first);
    }
    return null;
  }

  Future<Usuario?> findOperatorByBarcode(String barcode) async {
    final db = await _dbHelper.database;
    
    // Filtramos especificamente por Operador (codigo_tipo = 2)
    final List<Map<String, dynamic>> maps = await db.query(
      'usuario',
      where: 'codigo_barra_usuario = ? AND ativo = 1 AND codigo_tipo = 2',
      whereArgs: [barcode.trim()],
    );

    if (maps.isNotEmpty) {
      return Usuario.fromMap(maps.first);
    }
    return null;
  }

  // --- CRUD GERAL ---

  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT u.*, ut.nome as tipo_nome 
      FROM usuario u
      JOIN usuario_tipo ut ON u.codigo_tipo = ut.codigo_tipo
      ORDER BY u.nome ASC
    ''');
  }

  Future<Map<String, dynamic>?> getById(int id) async {
    final db = await _dbHelper.database;
    final results = await db.query('usuario', where: 'codigo_usuario = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> insert(Usuario usuario) async {
    final db = await _dbHelper.database;
    return await db.insert('usuario', usuario.toMap());
  }

  Future<int> update(Usuario usuario) async {
    final db = await _dbHelper.database;
    return await db.update(
      'usuario',
      usuario.toMap(),
      where: 'codigo_usuario = ?',
      whereArgs: [usuario.codigoUsuario],
    );
  }

  Future<List<Map<String, dynamic>>> getTipos() async {
    final db = await _dbHelper.database;
    return await db.query('usuario_tipo');
  }
}
