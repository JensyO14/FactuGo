import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import 'category.dart';

class CategoryRepository {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  Future<List<Category>> getAll() async {
    final db = await _db;
    final maps = await db.query(
      'categories',
      where: 'is_deleted = 0',
      orderBy: 'name ASC',
    );
    return maps.map(Category.fromMap).toList();
  }

  Future<Category?> getById(int id) async {
    final db = await _db;
    final maps = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? Category.fromMap(maps.first) : null;
  }

  Future<int> insert(Category category) async {
    final db = await _db;
    return db.insert('categories', category.toMap());
  }

  Future<void> update(Category category) async {
    final db = await _db;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.update(
      'categories',
      {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
