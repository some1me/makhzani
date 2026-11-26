import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._(this.db);
  final Database db;
  static final Future<AppDatabase> instance = _open();

  static Future<AppDatabase> _open() async {
    final path = p.join(await getDatabasesPath(), 'makhzani.db');
    final database = await openDatabase(path, version: 2, onCreate: _create, onUpgrade: _upgrade);
    return AppDatabase._(database);
  }

  static Future<void> _create(Database db, int version) async {
    await db.execute('CREATE TABLE products(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, barcode TEXT UNIQUE, price REAL NOT NULL DEFAULT 0, quantity INTEGER NOT NULL DEFAULT 0, updated_at TEXT NOT NULL)');
    await db.execute('CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT NOT NULL)');
    await db.execute('CREATE TABLE sales(id INTEGER PRIMARY KEY AUTOINCREMENT, total REAL NOT NULL, created_at TEXT NOT NULL, discount REAL NOT NULL DEFAULT 0, payment_method TEXT NOT NULL DEFAULT \'cash\')');
    await db.execute('CREATE TABLE sale_items(id INTEGER PRIMARY KEY AUTOINCREMENT, sale_id INTEGER NOT NULL, product_id INTEGER NOT NULL, quantity INTEGER NOT NULL, unit_price REAL NOT NULL)');
    await db.execute('CREATE TABLE purchases(id INTEGER PRIMARY KEY AUTOINCREMENT, total REAL NOT NULL, created_at TEXT NOT NULL, supplier TEXT NOT NULL DEFAULT \'\')');
    await db.execute('CREATE TABLE purchase_items(id INTEGER PRIMARY KEY AUTOINCREMENT, purchase_id INTEGER NOT NULL, product_id INTEGER NOT NULL, quantity INTEGER NOT NULL, unit_cost REAL NOT NULL)');
    await db.execute('CREATE TABLE stock_movements(id INTEGER PRIMARY KEY AUTOINCREMENT, product_id INTEGER NOT NULL, kind TEXT NOT NULL, quantity INTEGER NOT NULL, reference TEXT NOT NULL, note TEXT NOT NULL DEFAULT \'\', created_at TEXT NOT NULL)');
    await db.execute('CREATE INDEX idx_products_barcode ON products(barcode)');
    await db.execute('CREATE INDEX idx_sales_created ON sales(created_at)');
  }

  static Future<void> _upgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE sales ADD COLUMN discount REAL NOT NULL DEFAULT 0");
      await db.execute("ALTER TABLE sales ADD COLUMN payment_method TEXT NOT NULL DEFAULT 'cash'");
      await db.execute("ALTER TABLE purchases ADD COLUMN supplier TEXT NOT NULL DEFAULT ''");
      await db.execute('CREATE TABLE purchase_items(id INTEGER PRIMARY KEY AUTOINCREMENT, purchase_id INTEGER NOT NULL, product_id INTEGER NOT NULL, quantity INTEGER NOT NULL, unit_cost REAL NOT NULL)');
      await db.execute("CREATE TABLE stock_movements(id INTEGER PRIMARY KEY AUTOINCREMENT, product_id INTEGER NOT NULL, kind TEXT NOT NULL, quantity INTEGER NOT NULL, reference TEXT NOT NULL, note TEXT NOT NULL DEFAULT '', created_at TEXT NOT NULL)");
      await db.execute('CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sales_created ON sales(created_at)');
    }
  }

  Future<List<Map<String, Object?>>> getProducts({String? query}) async {
    if (query == null || query.trim().isEmpty) return db.query('products', orderBy: 'name COLLATE NOCASE');
    final term = '%${query.trim()}%';
    return db.query('products', where: 'name LIKE ? OR barcode LIKE ?', whereArgs: [term, term], orderBy: 'name COLLATE NOCASE');
  }

  Future<Map<String, Object?>?> findProductByBarcode(String barcode) async {
    final rows = await db.query('products', where: 'barcode = ?', whereArgs: [barcode.trim()], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> addProduct({required String name, required String barcode, required double price, required int quantity}) async {
    if (name.trim().isEmpty) throw ArgumentError('Product name is required');
    if (price < 0 || quantity < 0) throw ArgumentError('Price and quantity cannot be negative');
    final code = barcode.trim();
    await db.insert('products', {
      'name': name.trim(), 'barcode': code.isEmpty ? null : code, 'price': price,
      'quantity': quantity, 'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: code.isEmpty ? ConflictAlgorithm.abort : ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    final rows = await db.query('settings', columns: ['value'], where: 'key = ?', whereArgs: [key], limit: 1);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }
  Future<void> setSetting(String key, String value) => db.insert('settings', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  Future<List<Map<String, Object?>>> lowStock({int threshold = 5}) => db.query('products', where: 'quantity <= ?', whereArgs: [threshold], orderBy: 'quantity');

  Future<int> checkout({required Map<int, int> quantities, required double discount, required String paymentMethod}) async {
    if (quantities.isEmpty) throw StateError('Cart is empty');
    if (discount < 0) throw ArgumentError('Discount cannot be negative');
    return db.transaction((txn) async {
      double subtotal = 0;
      final items = <Map<String, Object?>>[];
      for (final entry in quantities.entries) {
        if (entry.value <= 0) throw ArgumentError('Quantity must be positive');
        final rows = await txn.query('products', where: 'id = ?', whereArgs: [entry.key], limit: 1);
        if (rows.isEmpty) throw StateError('Product no longer exists');
        final product = rows.first;
        if ((product['quantity'] as int) < entry.value) throw StateError('Insufficient stock for ${product['name']}');
        final price = (product['price'] as num).toDouble();
        subtotal += price * entry.value;
        items.add({'product_id': entry.key, 'quantity': entry.value, 'unit_price': price});
      }
      if (discount > subtotal) throw ArgumentError('Discount exceeds subtotal');
      final saleId = await txn.insert('sales', {'total': subtotal - discount, 'discount': discount, 'payment_method': paymentMethod, 'created_at': DateTime.now().toIso8601String()});
      for (final item in items) {
        final productId = item['product_id'] as int;
        final quantity = item['quantity'] as int;
        final changed = await txn.rawUpdate('UPDATE products SET quantity = quantity - ?, updated_at = ? WHERE id = ? AND quantity >= ?', [quantity, DateTime.now().toIso8601String(), productId, quantity]);
        if (changed != 1) throw StateError('Stock changed during checkout');
        await txn.insert('sale_items', {...item, 'sale_id': saleId});
        await txn.insert('stock_movements', {'product_id': productId, 'kind': 'sale', 'quantity': -quantity, 'reference': 'sale:$saleId', 'created_at': DateTime.now().toIso8601String()});
      }
      return saleId;
    });
  }

  Future<int> recordPurchase({required Map<int, int> quantities, required Map<int, double> costs, required String supplier}) async {
    if (quantities.isEmpty) throw StateError('Purchase has no items');
    return db.transaction((txn) async {
      double total = 0;
      for (final entry in quantities.entries) {
        final quantity = entry.value;
        final cost = costs[entry.key] ?? 0;
        if (quantity <= 0 || cost < 0) throw ArgumentError('Invalid purchase item');
        final exists = await txn.query('products', columns: ['id'], where: 'id = ?', whereArgs: [entry.key], limit: 1);
        if (exists.isEmpty) throw StateError('Product not found');
        total += quantity * cost;
      }
      final purchaseId = await txn.insert('purchases', {'total': total, 'supplier': supplier.trim(), 'created_at': DateTime.now().toIso8601String()});
      for (final entry in quantities.entries) {
        final quantity = entry.value;
        final cost = costs[entry.key] ?? 0;
        await txn.insert('purchase_items', {'purchase_id': purchaseId, 'product_id': entry.key, 'quantity': quantity, 'unit_cost': cost});
        await txn.rawUpdate('UPDATE products SET quantity = quantity + ?, updated_at = ? WHERE id = ?', [quantity, DateTime.now().toIso8601String(), entry.key]);
        await txn.insert('stock_movements', {'product_id': entry.key, 'kind': 'purchase', 'quantity': quantity, 'reference': 'purchase:$purchaseId', 'created_at': DateTime.now().toIso8601String()});
      }
      return purchaseId;
    });
  }

  Future<List<Map<String, Object?>>> getSales() => db.query('sales', orderBy: 'created_at DESC');
  Future<List<Map<String, Object?>>> getPurchases() => db.query('purchases', orderBy: 'created_at DESC');
  Future<void> close() => db.close();
}
