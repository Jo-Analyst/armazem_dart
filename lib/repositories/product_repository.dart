import '../core/database/database_helper.dart';
import '../models/product_model.dart';

class ProductRepository {
  final DatabaseHelper _dbHelper;

  ProductRepository(this._dbHelper);

  Future<int> insert(ProductModel product) async {
    final db = await _dbHelper.database;
    return await db.insert('produtos', product.toMap());
  }

  Future<List<ProductModel>> getAll({String? search, int? categoryId}) async {
    final db = await _dbHelper.database;

    // Saldo calculado dinamicamente como SUM(ENTRADA) - SUM(SAIDA)
    // Unidade exibida = unidade_medida da movimentação de ENTRADA mais recente
    String query = '''
      SELECT 
        p.id,
        p.nome,
        p.categoria_id,
        p.volume,
        c.nome AS categoria_nome,
        COALESCE(
          (SELECT SUM(m.quantidade) FROM movimentacoes m 
           WHERE m.produto_id = p.id AND m.tipo = 'ENTRADA'), 0.0
        ) - COALESCE(
          (SELECT SUM(m.quantidade) FROM movimentacoes m 
           WHERE m.produto_id = p.id AND m.tipo = 'SAIDA'), 0.0
        ) AS saldo,
        (SELECT m2.unidade_medida FROM movimentacoes m2 
         WHERE m2.produto_id = p.id AND m2.tipo = 'ENTRADA'
         ORDER BY m2.data_entrada DESC LIMIT 1) AS unidade_saldo
      FROM produtos p
      INNER JOIN categorias c ON p.categoria_id = c.id
    ''';

    final List<dynamic> args = [];
    final List<String> whereClauses = [];

    if (search != null && search.isNotEmpty) {
      whereClauses.add('(p.nome LIKE ? OR p.volume LIKE ?)');
      args.add('%$search%');
      args.add('%$search%');
    }

    if (categoryId != null) {
      whereClauses.add('p.categoria_id = ?');
      args.add(categoryId);
    }

    if (whereClauses.isNotEmpty) {
      query += ' WHERE ${whereClauses.join(' AND ')}';
    }

    query += ' ORDER BY p.nome ASC';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, args);
    return List.generate(maps.length, (i) => ProductModel.fromMap(maps[i]));
  }

  Future<ProductModel?> getById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT 
        p.id,
        p.nome,
        p.categoria_id,
        p.volume,
        c.nome AS categoria_nome,
        COALESCE(
          (SELECT SUM(m.quantidade) FROM movimentacoes m 
           WHERE m.produto_id = p.id AND m.tipo = 'ENTRADA'), 0.0
        ) - COALESCE(
          (SELECT SUM(m.quantidade) FROM movimentacoes m 
           WHERE m.produto_id = p.id AND m.tipo = 'SAIDA'), 0.0
        ) AS saldo,
        (SELECT m2.unidade_medida FROM movimentacoes m2 
         WHERE m2.produto_id = p.id AND m2.tipo = 'ENTRADA'
         ORDER BY m2.data_entrada DESC LIMIT 1) AS unidade_saldo
      FROM produtos p
      INNER JOIN categorias c ON p.categoria_id = c.id
      WHERE p.id = ?
    ''',
      [id],
    );

    if (maps.isEmpty) return null;
    return ProductModel.fromMap(maps.first);
  }

  Future<int> update(ProductModel product) async {
    final db = await _dbHelper.database;
    return await db.update(
      'produtos',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('produtos', where: 'id = ?', whereArgs: [id]);
  }
}
