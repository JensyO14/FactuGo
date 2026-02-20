import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import 'expense.dart';

class ExpenseRepository {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  Future<List<Expense>> getAll() async {
    final db = await _db;
    final maps = await db.rawQuery('''
      SELECT e.*, ec.name AS category_name
      FROM expenses e
      LEFT JOIN expense_categories ec ON ec.id = e.expense_category_id
      WHERE e.is_deleted = 0
      ORDER BY e.date DESC
    ''');
    return maps.map(Expense.fromMap).toList();
  }

  Future<int> insert(Expense expense) async {
    final db = await _db;
    return db.insert('expenses', expense.toMap());
  }

  Future<void> update(Expense expense) async {
    final db = await _db;
    await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.update(
      'expenses',
      {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
