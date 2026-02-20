import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/base_model.dart';
import 'client.dart';

class ClientRepository {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  /// Retorna todos los clientes no eliminados.
  Future<List<Client>> getAll() async {
    final db = await _db;
    final maps = await db.query(
      'clients',
      where: 'is_deleted = 0',
      orderBy: 'name ASC',
    );
    return maps.map(Client.fromMap).toList();
  }

  Future<Client?> getById(int id) async {
    final db = await _db;
    final maps = await db.query('clients', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? Client.fromMap(maps.first) : null;
  }

  /// Verifica si ya existe un cliente activo con ese nombre (ignorando [excludeId]).
  Future<bool> _nameExists(Database db, String name, {int? excludeId}) async {
    final maps = await db.query(
      'clients',
      where: excludeId != null
          ? 'LOWER(name) = LOWER(?) AND is_deleted = 0 AND id != ?'
          : 'LOWER(name) = LOWER(?) AND is_deleted = 0',
      whereArgs: excludeId != null ? [name, excludeId] : [name],
    );
    return maps.isNotEmpty;
  }

  /// Verifica si ya existe un cliente activo con ese taxId (ignorando [excludeId]).
  Future<bool> _taxIdExists(Database db, String taxId, {int? excludeId}) async {
    final maps = await db.query(
      'clients',
      where: excludeId != null
          ? 'LOWER(tax_id) = LOWER(?) AND is_deleted = 0 AND id != ?'
          : 'LOWER(tax_id) = LOWER(?) AND is_deleted = 0',
      whereArgs: excludeId != null ? [taxId, excludeId] : [taxId],
    );
    return maps.isNotEmpty;
  }

  Future<int> insert(Client client) async {
    final db = await _db;
    if (await _nameExists(db, client.name)) {
      throw Exception('Ya existe un cliente con el nombre "${client.name}".');
    }
    if (client.taxId != null &&
        client.taxId!.isNotEmpty &&
        await _taxIdExists(db, client.taxId!)) {
      throw Exception(
        'Ya existe un cliente con la cédula/RIF "${client.taxId}".',
      );
    }
    return db.insert('clients', client.toMap());
  }

  Future<void> update(Client client) async {
    if (client.id == 1) {
      throw Exception('No se puede editar el Consumidor Final predeterminado.');
    }
    final db = await _db;
    if (await _nameExists(db, client.name, excludeId: client.id)) {
      throw Exception('Ya existe un cliente con el nombre "${client.name}".');
    }
    if (client.taxId != null &&
        client.taxId!.isNotEmpty &&
        await _taxIdExists(db, client.taxId!, excludeId: client.id)) {
      throw Exception(
        'Ya existe un cliente con la cédula/RIF "${client.taxId}".',
      );
    }
    await db.update(
      'clients',
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  /// Soft delete: marca is_deleted = 1.
  Future<void> delete(int id) async {
    if (id == 1) {
      throw Exception(
        'No se puede eliminar el Consumidor Final predeterminado.',
      );
    }
    final db = await _db;
    await db.update(
      'clients',
      {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Asegura que existe el cliente por defecto (ID 1, Consumidor Final).
  /// Retorna el ID (debería ser 1, pero por si acaso).
  Future<int> ensureDefaultClient() async {
    final db = await _db;
    // Verificar si existe ID 1 (incluso si está borrado, lo reactivamos)
    final maps = await db.query('clients', where: 'id = 1');
    if (maps.isNotEmpty) {
      final client = Client.fromMap(maps.first);
      if (client.isDeleted) {
        await db.update('clients', {
          'is_deleted': 0,
          'updated_at': DateTime.now().toIso8601String(),
        }, where: 'id = 1');
      }
      return 1;
    }

    // Si no existe, insertar con ID explícito 1
    final now = DateTime.now(); // Usar DateTime para created_at
    // Client.toMap() no permite forzar ID en insert si es autoincrement,
    // pero sqlite permite insertar explícitamente si se especifica.
    // Usamos rawInsert.
    await db.rawInsert(
      '''
      INSERT INTO clients (id, name, tax_id, email, phone, address, is_deleted, created_at, updated_at)
      VALUES (1, 'Consumidor Final', '0', NULL, NULL, NULL, 0, ?, ?)
    ''',
      [BaseModel.formatDate(now), BaseModel.formatDate(now)],
    );

    return 1;
  }
}
