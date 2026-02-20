import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('facturacion_v5.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 3, // v3: expense tables
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Obtener columnas existentes para evitar error "duplicate column"
      final columnsInfo = await db.rawQuery('PRAGMA table_info(business)');
      final existingColumns = columnsInfo
          .map((c) => c['name'] as String)
          .toList();

      Future<void> addIfNotExists(String col, String type) async {
        if (!existingColumns.contains(col)) {
          await db.execute('ALTER TABLE business ADD COLUMN $col $type');
        }
      }

      await addIfNotExists('entity_type', 'TEXT');
      await addIfNotExists('currency', "TEXT DEFAULT 'DOP'");
      await addIfNotExists('timezone', 'TEXT');
      await addIfNotExists('use_inventory', 'INTEGER DEFAULT 1');
      await addIfNotExists('require_stock', 'INTEGER DEFAULT 1');
      await addIfNotExists('allow_negative_stock', 'INTEGER DEFAULT 0');
      await addIfNotExists('low_stock_limit', 'INTEGER DEFAULT 5');
    }
    if (oldVersion < 3) {
      await db.execute('''
CREATE TABLE IF NOT EXISTS expense_categories (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  name         TEXT NOT NULL,
  description  TEXT,
  cloud_id     TEXT,
  is_deleted   INTEGER NOT NULL DEFAULT 0,
  created_at   TEXT NOT NULL,
  updated_at   TEXT NOT NULL
)''');

      await db.execute('''
CREATE TABLE IF NOT EXISTS expenses (
  id                    INTEGER PRIMARY KEY AUTOINCREMENT,
  expense_category_id   INTEGER NOT NULL,
  description           TEXT NOT NULL,
  amount                REAL NOT NULL,
  date                  TEXT NOT NULL,
  notes                 TEXT,
  cloud_id              TEXT,
  is_deleted            INTEGER NOT NULL DEFAULT 0,
  created_at            TEXT NOT NULL,
  updated_at            TEXT NOT NULL,
  FOREIGN KEY (expense_category_id) REFERENCES expense_categories(id) ON DELETE SET NULL
)''');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Shorthand types
    const id = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const txt = 'TEXT NOT NULL';
    const txtNull = 'TEXT';
    const real = 'REAL NOT NULL';
    const integer = 'INTEGER NOT NULL';
    // Sync fields shared by all tables
    const syncFields = '''
  cloud_id     TEXT,
  is_deleted   INTEGER NOT NULL DEFAULT 0,
  created_at   TEXT NOT NULL,
  updated_at   TEXT NOT NULL
''';

    await db.execute('''
CREATE TABLE business (
  id           $id,
  name         $txt,
  address      $txtNull,
  phone        $txtNull,
  email        $txtNull,
  tax_id       $txtNull,
  logo_path    $txtNull,
  entity_type  $txtNull,
  currency     TEXT DEFAULT 'DOP',
  timezone     $txtNull,
  use_inventory INTEGER DEFAULT 1,
  require_stock INTEGER DEFAULT 1,
  allow_negative_stock INTEGER DEFAULT 0,
  low_stock_limit INTEGER DEFAULT 5,
  $syncFields
)''');

    await db.execute('''
CREATE TABLE clients (
  id           $id,
  name         $txt,
  tax_id       $txtNull,
  email        $txtNull,
  phone        $txtNull,
  address      $txtNull,
  $syncFields
)''');

    await db.execute('''
CREATE TABLE categories (
  id           $id,
  name         $txt,
  description  $txtNull,
  $syncFields
)''');

    await db.execute('''
CREATE TABLE products (
  id           $id,
  category_id  INTEGER,
  name         $txt,
  description  $txtNull,
  price        $real,
  stock        $real,
  sku          $txtNull,
  $syncFields,
  FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
)''');

    await db.execute('''
CREATE TABLE invoices (
  id           $id,
  client_id    $integer,
  number       $txt,
  date         $txt,
  subtotal     $real,
  tax          $real,
  total        $real,
  status       $txt,
  payment_method TEXT DEFAULT 'Contado',
  amount_tendered REAL DEFAULT 0.0,
  change_returned REAL DEFAULT 0.0,
  $syncFields,
  FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL
)''');

    await db.execute('''
CREATE TABLE invoice_items (
  id           $id,
  invoice_id   $integer,
  product_id   $integer,
  quantity     $real,
  unit_price   $real,
  total        $real,
  $syncFields,
  FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL
)''');

    await db.execute('''
CREATE TABLE expense_categories (
  id           $id,
  name         $txt,
  description  $txtNull,
  $syncFields
)''');

    await db.execute('''
CREATE TABLE expenses (
  id                    $id,
  expense_category_id   $integer,
  description           $txt,
  amount                $real,
  date                  $txt,
  notes                 $txtNull,
  $syncFields,
  FOREIGN KEY (expense_category_id) REFERENCES expense_categories(id) ON DELETE SET NULL
)''');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
