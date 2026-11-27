import 'package:flutter/material.dart';
import '../database/database.dart';

class AppProvider extends ChangeNotifier {
  AppProvider(this.database);
  final AppDatabase database;
  Locale _locale = const Locale('ar');
  Locale get locale => _locale;
  List<Map<String, Object?>> products = [];
  final Map<int, int> cart = {};

  Future<void> loadData() async {
    _locale = Locale(await database.getSetting('language') ?? 'ar');
    await refreshProducts(notify: false);
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    await database.setSetting('language', language);
    _locale = Locale(language);
    notifyListeners();
  }

  Future<void> refreshProducts({bool notify = true}) async {
    products = await database.getProducts();
    if (notify) notifyListeners();
  }

  Future<void> addProduct({required String name, required String barcode, required double price, required int quantity}) async {
    await database.addProduct(name: name, barcode: barcode, price: price, quantity: quantity);
    await refreshProducts();
  }

  void addToCart(Map<String, Object?> product) {
    final id = product['id'] as int;
    final next = (cart[id] ?? 0) + 1;
    if (next > (product['quantity'] as int)) throw StateError('Insufficient stock');
    cart[id] = next;
    notifyListeners();
  }

  void changeCartQuantity(int productId, int amount) {
    final product = products.firstWhere((item) => item['id'] == productId);
    final next = (cart[productId] ?? 0) + amount;
    if (next <= 0) {
      cart.remove(productId);
    } else if (next <= (product['quantity'] as int)) {
      cart[productId] = next;
    }
    notifyListeners();
  }

  void clearCart() {
    cart.clear();
    notifyListeners();
  }

  double get cartSubtotal => cart.entries.fold(0, (sum, entry) {
    final product = products.firstWhere((item) => item['id'] == entry.key);
    return sum + (product['price'] as num).toDouble() * entry.value;
  });

  Future<int> checkout({double discount = 0, String paymentMethod = 'cash'}) async {
    final id = await database.checkout(
      quantities: Map<int, int>.of(cart),
      discount: discount,
      paymentMethod: paymentMethod,
    );
    cart.clear();
    await refreshProducts(notify: false);
    notifyListeners();
    return id;
  }

  Future<int> recordPurchase({
    required Map<int, int> quantities,
    required Map<int, double> costs,
    required String supplier,
  }) async {
    final id = await database.recordPurchase(
      quantities: quantities,
      costs: costs,
      supplier: supplier,
    );
    await refreshProducts();
    return id;
  }

  String text(String key) {
    final en = _locale.languageCode == 'en';
    const values = <String, List<String>>{
      'app': ['مخزني', 'Makhzani'],
      'sales': ['البيع', 'Sales'],
      'products': ['المنتجات', 'Products'],
      'purchases': ['المشتريات', 'Purchases'],
      'reports': ['التقارير', 'Reports'],
      'settings': ['الإعدادات', 'Settings'],
      'language': ['اللغة', 'Language'],
      'arabic': ['العربية', 'Arabic'],
      'english': ['الإنجليزية', 'English'],
      'inventory_report': ['تصدير تقرير المخزون Excel', 'Export inventory report to Excel'],
      'template': ['تنزيل نموذج المنتجات Excel', 'Download product Excel template'],
      'import': ['استيراد المنتجات من Excel', 'Import products from Excel'],
      'name': ['اسم المنتج', 'Product name'],
      'barcode': ['الباركود', 'Barcode'],
      'price': ['سعر البيع', 'Selling price'],
      'quantity': ['الكمية', 'Quantity'],
      'add': ['إضافة منتج', 'Add product'],
      'save': ['حفظ', 'Save'],
      'empty': ['لا توجد منتجات بعد', 'No products yet'],
      'done': ['تم بنجاح', 'Completed'],
      'cancel': ['إلغاء', 'Cancel'],
      'stock': ['المخزون', 'Stock'],
      'scan': ['مسح باركود', 'Scan barcode'],
      'checkout': ['إتمام البيع', 'Complete sale'],
      'cart': ['سلة البيع', 'Cart'],
      'discount': ['الخصم', 'Discount'],
      'payment': ['طريقة الدفع', 'Payment method'],
      'cash': ['نقداً', 'Cash'],
      'card': ['بطاقة', 'Card'],
      'total': ['الإجمالي', 'Total'],
      'supplier': ['المورد', 'Supplier'],
      'record_purchase': ['تسجيل مشتريات', 'Record purchase'],
      'low_stock': ['مخزون منخفض', 'Low stock'],
      'no_products': ['أضف منتجات للبدء', 'Add products to get started'],
      'error': ['خطأ', 'Error'],
      'search': ['بحث', 'Search'],
    };
    final pair = values[key];
    return pair == null ? key : pair[en ? 1 : 0];
  }
}
