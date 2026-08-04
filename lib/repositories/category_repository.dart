import '../core/database/database_helper.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final DatabaseHelper _dbHelper;

  CategoryRepository(this._dbHelper);

  Future<int> insert(CategoryModel category) async {
    final db = await _dbHelper.database;
    
    // Check if category with same name (case-insensitive) already exists
    final existing = await db.query(
      'categories',
      where: 'LOWER(name) = LOWER(?)',
      whereArgs: [category.name.trim()],
    );
    
    if (existing.isNotEmpty) {
      throw Exception('Uma categoria com este nome já existe.');
    }
    
    return await db.insert('categories', category.toMap());
  }

  Future<List<CategoryModel>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => CategoryModel.fromMap(maps[i]));
  }

  Future<int> update(CategoryModel category) async {
    final db = await _dbHelper.database;
    
    // Check if another category with same name (case-insensitive) already exists
    final existing = await db.query(
      'categories',
      where: 'LOWER(name) = LOWER(?) AND id != ?',
      whereArgs: [category.name.trim(), category.id],
    );
    
    if (existing.isNotEmpty) {
      throw Exception('Uma categoria com este nome já existe.');
    }
    
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}
