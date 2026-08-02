import '../core/database/database_helper.dart';
import '../models/product_model.dart';

class ProductRepository {
  final DatabaseHelper _dbHelper;

  ProductRepository(this._dbHelper);

  Future<int> insert(ProductModel product) async {
    final db = await _dbHelper.database;
    return await db.insert('products', product.toMap());
  }

  Future<List<ProductModel>> getAll({String? search, int? categoryId}) async {
    final db = await _dbHelper.database;

    // Saldo calculado dinamicamente como SUM(ENTRADA) - SUM(SAIDA)
    // Unidade exibida = unit_of_measurement da movimentação de ENTRADA mais recente
    String query = '''
      SELECT 
        p.id,
        p.name,
        p.category_id,
        p.volume,
        c.name AS category_name,
        CASE 
          WHEN p.volume IS NOT NULL AND p.volume != '' 
            THEN p.name || ' (' || p.volume || ')'
          ELSE p.name 
        END AS description,
        COALESCE(
          (SELECT SUM(m.quantity) FROM movements m 
           WHERE m.product_id = p.id AND m.type = 'ENTRADA'), 0.0
        ) - COALESCE(
          (SELECT SUM(m.quantity) FROM movements m 
           WHERE m.product_id = p.id AND m.type = 'SAIDA'), 0.0
        ) AS saldo,
        (SELECT m2.unit_of_measurement FROM movements m2 
         WHERE m2.product_id = p.id AND m2.type = 'ENTRADA'
         ORDER BY m2.data_entry DESC LIMIT 1) AS unit_of_measurement
      FROM products p
      INNER JOIN categories c ON p.category_id = c.id
    ''';

    final List<dynamic> args = [];
    final List<String> whereClauses = [];

    if (search != null && search.isNotEmpty) {
      whereClauses.add('(p.name LIKE ? OR p.volume LIKE ?)');
      args.add('%$search%');
      args.add('%$search%');
    }

    if (categoryId != null) {
      whereClauses.add('p.category_id = ?');
      args.add(categoryId);
    }

    if (whereClauses.isNotEmpty) {
      query += ' WHERE ${whereClauses.join(' AND ')}';
    }

    query += ' ORDER BY p.name ASC';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, args);
    return List.generate(maps.length, (i) => ProductModel.fromMap(maps[i]));
  }

  Future<ProductModel?> getById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT 
        p.id,
        p.name,
        p.category_id,
        p.volume,
        c.name AS category_name,
        COALESCE(
          (SELECT SUM(m.quantity) FROM movements m 
           WHERE m.product_id = p.id AND m.type = 'ENTRADA'), 0.0
        ) - COALESCE(
          (SELECT SUM(m.quantity) FROM movements m 
           WHERE m.product_id = p.id AND m.type = 'SAIDA'), 0.0
        ) AS saldo,
        (SELECT m2.unit_of_measurement FROM movements m2 
         WHERE m2.product_id = p.id AND m2.type = 'ENTRADA'
         ORDER BY m2.data_entry DESC LIMIT 1) AS unit_of_measurement
      FROM products p
      INNER JOIN categories c ON p.category_id = c.id
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
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }
}
