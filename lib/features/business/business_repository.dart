import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import 'business_profile.dart';

class BusinessRepository {
  final _db = DatabaseHelper.instance.database;

  /// Obtiene el perfil de negocio único.
  /// Si no existe, retorna null.
  Future<BusinessProfile?> get() async {
    final db = await _db;
    final maps = await db.query('business', limit: 1);
    if (maps.isNotEmpty) {
      return BusinessProfile.fromMap(maps.first);
    }
    return null;
  }

  /// Guarda el perfil. Si ya existe (id != null), actualiza.
  /// Si no existe, inserta.
  Future<void> save(BusinessProfile profile) async {
    final db = await _db;

    // Check if exists
    final existing = await get();

    if (existing != null) {
      // Update existing
      final toUpdate = profile.copyWith(id: existing.id);
      await db.update(
        'business',
        toUpdate.toMap(),
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    } else {
      // Insert new
      await db.insert('business', profile.toMap());
    }
  }
}
