import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../core/database/database_helper.dart';
import '../clients/client.dart';
import '../invoices/invoice.dart';

class DashboardStats {
  final double dailySales;
  final double monthlySales;
  final int pendingCount;
  final int lowStockCount;

  const DashboardStats({
    required this.dailySales,
    required this.monthlySales,
    required this.pendingCount,
    required this.lowStockCount,
  });
}

class SalesPoint {
  final String label;
  final double amount;

  const SalesPoint(this.label, this.amount);
}

class DashboardRepository {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  Future<DashboardStats> getStats({bool useInventory = false}) async {
    final db = await _db;
    final now = DateTime.now();

    // 1. Daily Sales
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
    final endOfDay = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
    ).toIso8601String();

    final dailyRes = await db.rawQuery(
      '''
      SELECT SUM(total) as total 
      FROM invoices 
      WHERE date >= ? AND date <= ? AND status = 'pagada' AND is_deleted = 0
    ''',
      [startOfDay, endOfDay],
    );

    final dailySales = (dailyRes.first['total'] as num?)?.toDouble() ?? 0.0;

    // 2. Monthly Sales
    final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
    // endOfMonth is handled by just checking >= startOfMonth and <= endOfDay (which is today)
    // or we can just say >= startOfMonth.

    final monthlyRes = await db.rawQuery(
      '''
      SELECT SUM(total) as total 
      FROM invoices 
      WHERE date >= ? AND status = 'pagada' AND is_deleted = 0
    ''',
      [startOfMonth],
    );

    final monthlySales = (monthlyRes.first['total'] as num?)?.toDouble() ?? 0.0;

    // 3. Pending Count
    final pendingRes = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM invoices 
      WHERE status = 'pendiente' AND is_deleted = 0
    ''');

    final pendingCount = Sqflite.firstIntValue(pendingRes) ?? 0;

    // 4. Low Stock Count
    int lowStockCount = 0;
    if (useInventory) {
      final stockRes = await db.rawQuery(
        '''
        SELECT COUNT(*) as count 
        FROM products 
        WHERE stock <= 5
      ''',
      ); // Assuming 5 is the threshold for now, or we can make it configurable later
      lowStockCount = Sqflite.firstIntValue(stockRes) ?? 0;
    }

    return DashboardStats(
      dailySales: dailySales,
      monthlySales: monthlySales,
      pendingCount: pendingCount,
      lowStockCount: lowStockCount,
    );
  }

  Future<List<SalesPoint>> getWeeklySales() async {
    final db = await _db;
    final now = DateTime.now();
    final List<SalesPoint> points = [];

    // Last 7 days including today
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final start = DateTime(day.year, day.month, day.day).toIso8601String();
      final end = DateTime(
        day.year,
        day.month,
        day.day,
        23,
        59,
        59,
      ).toIso8601String();

      final res = await db.rawQuery(
        '''
        SELECT SUM(total) as total 
        FROM invoices 
        WHERE date >= ? AND date <= ? AND status = 'pagada' AND is_deleted = 0
      ''',
        [start, end],
      );

      final total = (res.first['total'] as num?)?.toDouble() ?? 0.0;

      // Label: Mon, Tue, etc. or just day number
      // Let's use weekday name abbreviation in Spanish
      final weekdays = [
        'L',
        'M',
        'M',
        'J',
        'V',
        'S',
        'D',
      ]; // Lun, Mar, Mie, Jue, Vie, Sab, Dom
      // weekday is 1..7 (Mon..Sun)
      final label = weekdays[day.weekday - 1];

      points.add(SalesPoint(label, total));
    }

    return points;
  }

  Future<List<Invoice>> getRecentInvoices() async {
    final db = await _db;
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
      WHERE i.is_deleted = 0
      ORDER BY i.date DESC
      LIMIT 5
    ''');

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
          isDeleted:
              false, // Assuming active in this join context or we can add c.is_deleted to query
        );
        return invoice.copyWith(client: client);
      }
      return invoice;
    }).toList();
  }
}
