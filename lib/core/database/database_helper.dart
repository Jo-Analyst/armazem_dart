import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static const _databaseName = 'armazem.db';
  static const _databaseVersion = 2;

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migração destrutiva: apaga e recria as tabelas com o novo esquema.
    // Necessário pois a estrutura de produtos e movimentacoes mudou de forma
    // incompatível (remoção de campos em produtos, adição/renomeação em movimentacoes).
    await db.execute('PRAGMA foreign_keys = OFF');
    await db.execute('DROP TABLE IF EXISTS movimentacoes');
    await db.execute('DROP TABLE IF EXISTS produtos');
    await db.execute('DROP TABLE IF EXISTS categorias');
    await db.execute('PRAGMA foreign_keys = ON');
    await _createTables(db);
  }

  Future<void> _createTables(Database db) async {
    // Categorias — id sem AUTOINCREMENT conforme especificação
    await db.execute('''
      CREATE TABLE categorias (
        id INTEGER PRIMARY KEY,
        nome TEXT NOT NULL UNIQUE
      )
    ''');

    // Produtos — sem quantidade nem unidade_medida (saldo é dinâmico)
    await db.execute('''
      CREATE TABLE produtos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        categoria_id INTEGER NOT NULL,
        FOREIGN KEY (categoria_id) REFERENCES categorias (id) ON DELETE CASCADE
      )
    ''');

    // Movimentações — data_entrada, data_saida e unidade_medida obrigatórios/opcionais
    await db.execute('''
      CREATE TABLE movimentacoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        produto_id INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        quantidade REAL NOT NULL,
        unidade_medida TEXT NOT NULL,
        data_entrada TEXT,
        data_saida TEXT,
        observacao TEXT,
        FOREIGN KEY (produto_id) REFERENCES produtos (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<String> getDatabasePath() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, _databaseName);
  }
}
