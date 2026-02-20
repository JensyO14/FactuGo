import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../clients/client.dart';
import 'invoice.dart';
import 'invoice_item.dart';

class InvoiceRepository {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  Future<List<Invoice>> getAll() => getFiltered();

  Future<List<Invoice>> getFiltered({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? statuses,
    int? clientId,
    String? query, // Código de factura
  }) async {
    final db = await _db;

    var where = 'i.is_deleted = 0';
    final List<Object?> args = [];

    if (startDate != null) {
      where += ' AND i.date >= ?';
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      // Ajustar al final del día
      final e = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      where += ' AND i.date <= ?';
      args.add(e.toIso8601String());
    }
    if (statuses != null && statuses.isNotEmpty) {
      final placeholders = List.filled(statuses.length, '?').join(',');
      where += ' AND i.status IN ($placeholders)';
      args.addAll(statuses);
    }
    if (clientId != null) {
      where += ' AND i.client_id = ?';
      args.add(clientId);
    }
    if (query != null && query.isNotEmpty) {
      where += ' AND i.number LIKE ?';
      args.add('%$query%');
    }

    final res = await db.rawQuery('''
      SELECT i.*, 
             c.id as c_id, 
             c.name as c_name, 
             c.tax_id as c_tax_id,
             c.phone as c_phone,
             c.email as c_email,
             c.address as c_address,
             c.created_at as c_created_at,
             c.updated_at as c_updated_at
      FROM invoices i
      LEFT JOIN clients c ON i.client_id = c.id
      WHERE $where
      ORDER BY i.date DESC
    ''', args);

    return res.map((row) {
      final invoice = Invoice.fromMap(row);
      if (row['c_id'] != null) {
        final client = Client(
          id: row['c_id'] as int,
          name: row['c_name'] as String,
          taxId: row['c_tax_id'] as String?,
          phone: row['c_phone'] as String?,
          email: row['c_email'] as String?,
          address: row['c_address'] as String?,
          createdAt: row['c_created_at'] != null
              ? DateTime.parse(row['c_created_at'] as String)
              : DateTime.now(),
          updatedAt: row['c_updated_at'] != null
              ? DateTime.parse(row['c_updated_at'] as String)
              : DateTime.now(),
        );
        return invoice.copyWith(client: client);
      }
      return invoice;
    }).toList();
  }

  Future<Invoice?> getById(int id) async {
    final db = await _db;
    final maps = await db.query('invoices', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? Invoice.fromMap(maps.first) : null;
  }

  Future<List<InvoiceItem>> getItemsFor(int invoiceId) async {
    final db = await _db;
    final res = await db.rawQuery(
      '''
      SELECT ii.*, p.name as product_name
      FROM invoice_items ii
      LEFT JOIN products p ON ii.product_id = p.id
      WHERE ii.invoice_id = ? AND ii.is_deleted = 0
    ''',
      [invoiceId],
    );

    return res.map(InvoiceItem.fromMap).toList();
  }

  /// Inserta factura + items en una transacción atómica.
  Future<int> createWithItems(
    Invoice invoice,
    List<InvoiceItem> items, {
    bool deductStock = true,
  }) async {
    final db = await _db;
    late int invoiceId;
    await db.transaction((txn) async {
      // 1. Insertar factura temporalmente para obtener ID
      // Usamos un número placeholder que luego actualizaremos
      var invoiceMap = invoice.toMap();
      invoiceMap.remove('id'); // Ensure ID is null for auto-increment
      invoiceMap['number'] = 'TEMP';

      invoiceId = await txn.insert('invoices', invoiceMap);

      // 2. Generar número secuencial basado en ID
      // Formato: 000001
      final sequentialNumber = invoiceId.toString().padLeft(6, '0');

      await txn.update(
        'invoices',
        {'number': sequentialNumber},
        where: 'id = ?',
        whereArgs: [invoiceId],
      );

      // 3. Insertar items
      for (final item in items) {
        final newItem = InvoiceItem(
          invoiceId: invoiceId,
          productId: item.productId,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          total: item.total,
          createdAt: item.createdAt,
          updatedAt: item.updatedAt,
        );
        await txn.insert('invoice_items', newItem.toMap());

        // Descontar stock SOLO si se indica
        if (deductStock) {
          await txn.rawUpdate(
            'UPDATE products SET stock = stock - ?, updated_at = ? WHERE id = ?',
            [item.quantity, DateTime.now().toIso8601String(), item.productId],
          );
        }
      }
    });
    return invoiceId;
  }

  Future<void> updateStatus(int id, String status) async {
    final db = await _db;
    await db.update(
      'invoices',
      {'status': status, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> update(Invoice invoice) async {
    final db = await _db;
    await db.update(
      'invoices',
      invoice.toMap(),
      where: 'id = ?',
      whereArgs: [invoice.id],
    );
  }

  /// Anula una factura y revierte el stock de los productos.
  Future<void> cancel(int id) async {
    final db = await _db;
    await db.transaction((txn) async {
      // 1. Obtener items para saber qué stock devolver
      final items = await txn.rawQuery(
        'SELECT product_id, quantity FROM invoice_items WHERE invoice_id = ? AND is_deleted = 0',
        [id],
      );

      // 2. Revertir stock
      for (final item in items) {
        final productId = item['product_id'] as int;
        final quantity = item['quantity'] as num; // int or double

        await txn.rawUpdate(
          'UPDATE products SET stock = stock + ?, updated_at = ? WHERE id = ?',
          [quantity, DateTime.now().toIso8601String(), productId],
        );
      }

      // 3. Actualizar estado de factura
      await txn.update(
        'invoices',
        {'status': 'anulada', 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  /// Soft delete: marca la factura como eliminada.
  Future<void> delete(int id) async {
    final db = await _db;
    await db.update(
      'invoices',
      {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
