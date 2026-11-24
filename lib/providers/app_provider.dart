import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../database/database.dart';

class AppProvider extends ChangeNotifier {
  AppProvider(this.database);
  final AppDatabase database;
  Locale _locale = const Locale('ar');
  Locale get locale => _locale;
  List<Map<String, Object?>> products = [];

  Future<void> loadData() async {
    final language = await database.getSetting('language') ?? 'ar';
    _locale = Locale(language);
    products = await database.getProducts();
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    await database.setSetting('language', language);
    _locale = Locale(language);
    notifyListeners();
  }

  Future<void> refreshProducts() async {
    products = await database.getProducts();
    notifyListeners();
  }

  Future<void> addProduct({required String name, required String barcode, required double price, required int quantity}) async {
    await database.addProduct(name: name, barcode: barcode, price: price, quantity: quantity);
    await refreshProducts();
  }

  String text(String key) {
    final ar = _locale.languageCode == 'ar';
    const values = {
      'app': ['مخزني', 'Makhzani'], 'sales': ['البيع', 'Sales'],
      'products': ['المنتجات', 'Products'], 'purchases': ['المشتريات', 'Purchases'],
      'reports': ['التقارير', 'Reports'], 'settings': ['الإعدادات', 'Settings'],
      'language': ['اللغة', 'Language'], 'arabic': ['العربية', 'Arabic'],
      'english': ['الإنجليزية', 'English'], 'inventory_report': ['تصدير تقرير المخزون Excel', 'Export inventory report to Excel'],
      'template': ['تنزيل نموذج المنتجات Excel', 'Download product Excel template'],
      'import': ['استيراد المنتجات من Excel', 'Import products from Excel'],
      'name': ['اسم المنتج', 'Product name'], 'barcode': ['الباركود', 'Barcode'],
      'price': ['سعر البيع', 'Selling price'], 'quantity': ['الكمية', 'Quantity'],
      'add': ['إضافة منتج', 'Add product'], 'save': ['حفظ', 'Save'],
      'empty': ['لا توجد منتجات بعد', 'No products yet'], 'done': ['تم بنجاح', 'Done'],
      'cancel': ['إلغاء', 'Cancel'], 'stock': ['المخزون', 'Stock'],
    };
    final pair = values[key];
    return pair == null ? key : pair[ar ? 0 : 1];
  }
}
