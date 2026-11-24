import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class AppDatabase {
  AppDatabase._(this.db);
  final Database db;
  static final Future<AppDatabase> instance = _open();

  static Future<AppDatabase> _open() async {
    final path = p.join(await getDatabasesPath(), 'makhzani.db');
    final db = await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('CREATE TABLE products(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, barcode TEXT UNIQUE, price REAL NOT NULL DEFAULT 0, quantity INTEGER NOT NULL DEFAULT 0, updated_at TEXT NOT NULL)');
      await db.execute('CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT NOT NULL)');
      await db.execute('CREATE TABLE sales(id INTEGER PRIMARY KEY AUTOINCREMENT, total REAL NOT NULL, created_at TEXT NOT NULL)');
      await db.execute('CREATE TABLE sale_items(id INTEGER PRIMARY KEY AUTOINCREMENT, sale_id INTEGER NOT NULL, product_id INTEGER NOT NULL, quantity INTEGER NOT NULL, unit_price REAL NOT NULL)');
      await db.execute('CREATE TABLE purchases(id INTEGER PRIMARY KEY AUTOINCREMENT, total REAL NOT NULL, created_at TEXT NOT NULL)');
    });
    return AppDatabase._(db);
  }

  Future<List<Map<String, Object?>>> getProducts() => db.query('products', orderBy: 'name COLLATE NOCASE');
  Future<void> addProduct({required String name, required String barcode, required double price, required int quantity}) async {
    await db.insert('products', {'name': name.trim(), 'barcode': barcode.trim().isEmpty ? null : barcode.trim(), 'price': price, 'quantity': quantity, 'updated_at': DateTime.now().toIso8601String()}, conflictAlgorithm: ConflictAlgorithm.replace);
  }
  Future<String?> getSetting(String key) async => (await db.query('settings', where: 'key = ?', whereArgs: [key], limit: 1)).firstOrNull?['value'] as String?;
  Future<void> setSetting(String key, String value) => db.insert('settings', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  Future<List<Map<String, Object?>>> lowStock({int threshold = 5}) => db.query('products', where: 'quantity <= ?', whereArgs: [threshold], orderBy: 'quantity');
}
