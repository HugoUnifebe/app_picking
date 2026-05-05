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
    // Tabela Usuario Tipo
    await db.execute('''
      CREATE TABLE usuario_tipo (
        codigo_tipo INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT
      )
    ''');

    await db.insert('usuario_tipo', {'nome': 'Supervisor'});
    await db.insert('usuario_tipo', {'nome': 'Operador'});

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

    await db.insert('usuario', {
      'nome': 'Supervisor',
      'email': 'supervisor@picking.com',
      'codigo_barra_usuario': '1234567899992',
      'codigo_tipo': 1,
      'ativo': 1,
      'criado_em': DateTime.now().toIso8601String(),
    });

    await db.insert('usuario', {
      'nome': 'Operador',
      'email': 'operador@picking.com',
      'codigo_barra_usuario': '9876543211118',
      'codigo_tipo': 2,
      'ativo': 1,
      'criado_em': DateTime.now().toIso8601String(),
    });

    await db.execute('''
      CREATE TABLE logs (
        codigo_log INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo_usuario INTEGER,
        FOREIGN KEY (codigo_usuario) REFERENCES usuario(codigo_usuario)
      )
    ''');

    await db.execute('''
      CREATE TABLE status_pedido (
        codigo_status_pedido INTEGER PRIMARY KEY AUTOINCREMENT,
        descricao TEXT,
        cor_hex TEXT
      )
    ''');

    await db.insert('status_pedido', {'descricao': 'Aguardando início de picking', 'cor_hex': 'FFA500'});
    await db.insert('status_pedido', {'descricao': 'Em andamento', 'cor_hex': '0000FF'});
    await db.insert('status_pedido', {'descricao': 'Finalizado', 'cor_hex': '008000'});

    await db.execute('''
      CREATE TABLE pedido (
        codigo_pedido INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo_usuario_responsavel INTEGER,
        codigo_barra_caixa TEXT,
        codigo_status_pedido INTEGER,
        criado_em TEXT,
        editado_em TEXT,
        finalizado_em TEXT,
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

    await db.insert('status_produto_pedido', {'descricao': 'Não está na caixa', 'cor_hex': 'FFFFFF'}); // Branco
    await db.insert('status_produto_pedido', {'descricao': 'Na caixa', 'cor_hex': 'FFD700'});        // Amarelo/Dourado
    await db.insert('status_produto_pedido', {'descricao': 'Entregue', 'cor_hex': '4CAF50'});        // Verde

    await db.execute('''
      CREATE TABLE produto (
        codigo_produto INTEGER PRIMARY KEY AUTOINCREMENT,
        nome_produto TEXT NOT NULL,
        codigo_barra_produto TEXT,
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
        codigo_produto_pedido INTEGER,
        codigo_pedido INTEGER,
        codigo_produto INTEGER,
        codigo_status_produto_pedido INTEGER,
        PRIMARY KEY (codigo_produto_pedido, codigo_pedido, codigo_produto),
        FOREIGN KEY (codigo_pedido) REFERENCES pedido(codigo_pedido),
        FOREIGN KEY (codigo_produto) REFERENCES produto(codigo_produto),
        FOREIGN KEY (codigo_status_produto_pedido) REFERENCES status_produto_pedido(codigo_status_produto_pedido)
      )
    ''');
  }
}
