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
}
