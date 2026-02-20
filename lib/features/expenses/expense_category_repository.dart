import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import 'expense_category.dart';

class ExpenseCategoryRepository {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  Future<List<ExpenseCategory>> getAll() async {
    final db = await _db;
    final maps = await db.query(
      'expense_categories',
      where: 'is_deleted = 0',
      orderBy: 'name ASC',
    );
    return maps.map(ExpenseCategory.fromMap).toList();
  }

  Future<ExpenseCategory?> getById(int id) async {
    final db = await _db;
    final maps = await db.query(
      'expense_categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps.isNotEmpty ? ExpenseCategory.fromMap(maps.first) : null;
  }

  Future<int> insert(ExpenseCategory category) async {
    final db = await _db;
    return db.insert('expense_categories', category.toMap());
  }

  Future<void> update(ExpenseCategory category) async {
    final db = await _db;
    await db.update(
      'expense_categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.update(
      'expense_categories',
      {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
