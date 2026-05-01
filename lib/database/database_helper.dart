import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'picking_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    // Tabela Usuario Tipo (Originalmente chamada de pedido no SQL enviado)
    await db.execute('''
      CREATE TABLE usuario_tipo (
        codigo_tipo INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE usuario (
        codigo_usuario INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT,
        email TEXT,
        codigo_barra_usuario TEXT,
        codigo_tipo INTEGER,
        ativo INTEGER NOT NULL DEFAULT 1,
        criado_em TEXT,
        editado_em TEXT,
        FOREIGN KEY (codigo_tipo) REFERENCES usuario_tipo(codigo_tipo)
      )
    ''');

    await db.execute('''
      CREATE TABLE logs (
        codigo_log INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo_usuario INTEGER,
        FOREIGN KEY (codigo_usuario) REFERENCES usuario(codigo_usuario)
      )
    ''');

    await db.execute('''
      CREATE TABLE status_caixa (
        codigo_status_caixa INTEGER PRIMARY KEY AUTOINCREMENT,
        descricao TEXT,
        cor_hex TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE caixa (
        codigo_caixa INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo_status_caixa INTEGER,
        localizacao TEXT,
        criado_em TEXT,
        editado_em TEXT,
        FOREIGN KEY (codigo_status_caixa) REFERENCES status_caixa(codigo_status_caixa)
      )
    ''');

    await db.execute('''
      CREATE TABLE status_pedido (
        codigo_status_pedido INTEGER PRIMARY KEY AUTOINCREMENT,
        descricao TEXT,
        cor_hex TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE pedido (
        codigo_pedido INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo_usuario_responsavel INTEGER,
        codigo_status_pedido INTEGER,
        criado_em TEXT,
        editado_em TEXT,
        FOREIGN KEY (codigo_status_pedido) REFERENCES status_pedido(codigo_status_pedido),
        FOREIGN KEY (codigo_usuario_responsavel) REFERENCES usuario(codigo_usuario)
      )
    ''');

    await db.execute('''
      CREATE TABLE status_produto_pedido (
        codigo_status_produto_pedido INTEGER PRIMARY KEY AUTOINCREMENT,
        descricao TEXT,
        cor_hex TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE produto (
        codigo_produto INTEGER PRIMARY KEY AUTOINCREMENT,
        sku TEXT,
        cor TEXT,
        tamanho TEXT,
        quantidade_disponivel INTEGER,
        variacao TEXT,
        localizacao TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE produto_pedido (
        codigo_produto_pedido INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo_pedido INTEGER,
        codigo_produto INTEGER,
        codigo_status_produto_pedido INTEGER,
        FOREIGN KEY (codigo_pedido) REFERENCES pedido(codigo_pedido),
        FOREIGN KEY (codigo_produto) REFERENCES produto(codigo_produto),
        FOREIGN KEY (codigo_status_produto_pedido) REFERENCES status_produto_pedido(codigo_status_produto_pedido)
      )
    ''');
  }
}
