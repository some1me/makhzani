import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/app_provider.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(app.text('reports'), style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 12),
      Card(child: ListTile(leading: const Icon(Icons.download), title: Text(app.text('inventory_report')), onTap: () => _export(context, false))),
      Card(child: ListTile(leading: const Icon(Icons.table_view), title: Text(app.text('template')), onTap: () => _export(context, true))),
      Card(child: ListTile(leading: const Icon(Icons.upload_file), title: Text(app.text('import')), onTap: () => _import(context))),
      const Padding(padding: EdgeInsets.all(12), child: Text('نموذج المنتجات: name, barcode, price, quantity. يرجى حفظه بصيغة .xlsx.')),
    ]);
  }
  Future<void> _export(BuildContext context, bool template) async {
    final app = context.read<AppProvider>(); final excel = Excel.createExcel(); final sheet = excel['Products'];
    sheet.appendRow([TextCellValue('name'), TextCellValue('barcode'), TextCellValue('price'), TextCellValue('quantity')]);
    if (!template) for (final p in app.products) { sheet.appendRow([TextCellValue('${p['name']}'), TextCellValue('${p['barcode'] ?? ''}'), DoubleCellValue((p['price'] as num).toDouble()), IntCellValue((p['quantity'] as num).toInt())]); }
    final bytes = excel.encode(); if (bytes == null) return;
    final dir = await getTemporaryDirectory(); final file = File('${dir.path}/${template ? 'makhzani_products_template' : 'makhzani_inventory'}.xlsx'); await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: app.text('app')));
  }
  Future<void> _import(BuildContext context) async {
    final app = context.read<AppProvider>();
    final picked = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx'], withData: true);
    if (picked == null || picked.files.single.bytes == null) return;
    try {
      final workbook = Excel.decodeBytes(picked.files.single.bytes!); final rows = workbook.tables.values.first.rows;
      for (final row in rows.skip(1)) {
        final values = row.map((cell) => cell?.value?.toString().trim() ?? '').toList();
        if (values.length < 4 || values[0].isEmpty) continue;
        await app.addProduct(name: values[0], barcode: values[1], price: double.tryParse(values[2]) ?? 0, quantity: int.tryParse(values[3]) ?? 0);
      }
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(app.text('done'))));
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر قراءة ملف Excel. تحقق من استخدام النموذج المعتمد.')));
    }
  }
}
