import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/app_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _busy = false;

  String _label(AppProvider app, String ar, String en) =>
      app.locale.languageCode == 'ar' ? ar : en;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(app.text('reports'), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: Text(_label(app, 'تصدير تقارير المخزون والمبيعات', 'Export inventory and sales reports')),
            subtitle: Text(_label(app, 'ملف Excel متعدد الأوراق', 'Multi-sheet Excel workbook')),
            onTap: _busy ? null : () => _exportReports(context),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.table_view),
            title: Text(app.text('template')),
            onTap: _busy ? null : () => _exportTemplate(context),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.upload_file),
            title: Text(app.text('import')),
            onTap: _busy ? null : () => _import(context),
          ),
        ),
        if (_busy) const Center(child: CircularProgressIndicator()),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(_label(app,
              'قالب المنتجات: name, barcode, price, quantity. استخدم ملف .xlsx.',
              'Product template columns: name, barcode, price, quantity (.xlsx).')),
        ),
      ],
    );
  }

  Future<void> _exportReports(BuildContext context) async {
    setState(() => _busy = true);
    try {
      final app = context.read<AppProvider>();
      final excel = Excel.createExcel();
      final inventory = excel['Inventory'];
      inventory.appendRow([
        TextCellValue('name'), TextCellValue('barcode'),
        TextCellValue('price'), TextCellValue('quantity'),
      ]);
      for (final product in await app.database.getProducts()) {
        inventory.appendRow([
          TextCellValue('${product['name']}'),
          TextCellValue('${product['barcode'] ?? ''}'),
          DoubleCellValue((product['price'] as num).toDouble()),
          IntCellValue((product['quantity'] as num).toInt()),
        ]);
      }

      final lowStock = excel['Low stock'];
      lowStock.appendRow([TextCellValue('name'), TextCellValue('barcode'), TextCellValue('quantity')]);
      for (final product in await app.database.lowStock()) {
        lowStock.appendRow([
          TextCellValue('${product['name']}'),
          TextCellValue('${product['barcode'] ?? ''}'),
          IntCellValue((product['quantity'] as num).toInt()),
        ]);
      }

      final salesSheet = excel['Sales'];
      salesSheet.appendRow([
        TextCellValue('sale_id'), TextCellValue('created_at'),
        TextCellValue('total'), TextCellValue('discount'), TextCellValue('payment_method'),
      ]);
      for (final sale in await app.database.getSales()) {
        salesSheet.appendRow([
          IntCellValue(sale['id'] as int), TextCellValue('${sale['created_at']}'),
          DoubleCellValue((sale['total'] as num).toDouble()),
          DoubleCellValue((sale['discount'] as num).toDouble()),
          TextCellValue('${sale['payment_method']}'),
        ]);
      }

      final purchasesSheet = excel['Purchases'];
      purchasesSheet.appendRow([TextCellValue('purchase_id'), TextCellValue('created_at'), TextCellValue('supplier'), TextCellValue('total')]);
      for (final purchase in await app.database.getPurchases()) {
        purchasesSheet.appendRow([
          IntCellValue(purchase['id'] as int), TextCellValue('${purchase['created_at']}'),
          TextCellValue('${purchase['supplier']}'),
          DoubleCellValue((purchase['total'] as num).toDouble()),
        ]);
      }
      await _shareExcel(excel, 'makhzani_reports.xlsx', app.text('app'));
    } catch (error) {
      _showMessage(context, '${context.read<AppProvider>().text('error')}: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportTemplate(BuildContext context) async {
    setState(() => _busy = true);
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Products'];
      sheet.appendRow([
        TextCellValue('name'), TextCellValue('barcode'),
        TextCellValue('price'), TextCellValue('quantity'),
      ]);
      await _shareExcel(excel, 'makhzani_products_template.xlsx', 'Makhzani');
    } catch (error) {
      _showMessage(context, '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareExcel(Excel excel, String filename, String message) async {
    final bytes = excel.encode();
    if (bytes == null) throw StateError('Could not generate Excel workbook');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: message));
  }

  Future<void> _import(BuildContext context) async {
    final app = context.read<AppProvider>();
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    if (picked == null || picked.files.single.bytes == null) return;

    setState(() => _busy = true);
    try {
      final workbook = Excel.decodeBytes(picked.files.single.bytes!);
      final table = workbook.tables['Products'] ?? workbook.tables.values.firstOrNull;
      if (table == null || table.rows.isEmpty) throw const FormatException('Empty workbook');
      final header = table.rows.first.map((cell) => cell?.value?.toString().trim().toLowerCase() ?? '').toList();
      final nameIndex = header.indexOf('name');
      final barcodeIndex = header.indexOf('barcode');
      final priceIndex = header.indexOf('price');
      final quantityIndex = header.indexOf('quantity');
      if ([nameIndex, barcodeIndex, priceIndex, quantityIndex].contains(-1)) {
        throw const FormatException('Required columns: name, barcode, price, quantity');
      }
      var imported = 0;
      for (final row in table.rows.skip(1)) {
        String valueAt(int index) => index < row.length ? row[index]?.value?.toString().trim() ?? '' : '';
        final name = valueAt(nameIndex);
        if (name.isEmpty) continue;
        final price = double.tryParse(valueAt(priceIndex));
        final quantity = int.tryParse(valueAt(quantityIndex));
        if (price == null || price < 0 || quantity == null || quantity < 0) {
          throw FormatException('Invalid price or quantity for $name');
        }
        await app.addProduct(
          name: name,
          barcode: valueAt(barcodeIndex),
          price: price,
          quantity: quantity,
        );
        imported++;
      }
      if (mounted) _showMessage(context, '${app.text('done')}: $imported');
    } catch (error) {
      if (mounted) _showMessage(context, '${app.text('error')}: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
