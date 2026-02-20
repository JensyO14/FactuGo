import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import 'product.dart';

class ProductRepository {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  Future<List<Product>> getAll() async {
    final db = await _db;
    final maps = await db.query(
      'products',
      where: 'is_deleted = 0',
      orderBy: 'name ASC',
    );
    return maps.map(Product.fromMap).toList();
  }

  Future<List<Product>> getByCategory(int categoryId) async {
    final db = await _db;
    final maps = await db.query(
      'products',
      where: 'category_id = ? AND is_deleted = 0',
      whereArgs: [categoryId],
      orderBy: 'name ASC',
    );
    return maps.map(Product.fromMap).toList();
  }

  Future<Product?> getById(int id) async {
    final db = await _db;
    final maps = await db.query('products', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? Product.fromMap(maps.first) : null;
  }

  /// Verifica si ya existe un producto activo con ese nombre (ignorando [excludeId]).
  Future<bool> _nameExists(Database db, String name, {int? excludeId}) async {
    final maps = await db.query(
      'products',
      where: excludeId != null
          ? 'LOWER(name) = LOWER(?) AND is_deleted = 0 AND id != ?'
          : 'LOWER(name) = LOWER(?) AND is_deleted = 0',
      whereArgs: excludeId != null ? [name, excludeId] : [name],
    );
    return maps.isNotEmpty;
  }

  Future<int> insert(Product product) async {
    final db = await _db;
    if (await _nameExists(db, product.name)) {
      throw Exception('Ya existe un producto con el nombre "${product.name}".');
    }
    return db.insert('products', product.toMap());
  }

  Future<void> update(Product product) async {
    final db = await _db;
    if (await _nameExists(db, product.name, excludeId: product.id)) {
      throw Exception('Ya existe un producto con el nombre "${product.name}".');
    }
    await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.update(
      'products',
      {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> addStock(int id, int quantity) async {
    final db = await _db;
    await db.rawUpdate(
      'UPDATE products SET stock = stock + ?, updated_at = ? WHERE id = ?',
      [quantity, DateTime.now().toIso8601String(), id],
    );
  }
}
