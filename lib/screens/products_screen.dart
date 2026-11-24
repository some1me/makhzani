import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    return Column(children: [Padding(padding: const EdgeInsets.all(12), child: Row(children: [Expanded(child: Text(app.text('products'), style: Theme.of(context).textTheme.titleLarge)), FilledButton.icon(onPressed: () => _add(context), icon: const Icon(Icons.add), label: Text(app.text('add')))])), Expanded(child: app.products.isEmpty ? Center(child: Text(app.text('empty'))) : ListView.builder(itemCount: app.products.length, itemBuilder: (_, i) { final p = app.products[i]; return ListTile(leading: const Icon(Icons.inventory_2), title: Text('${p['name']}'), subtitle: Text('${app.text('barcode')}: ${p['barcode'] ?? '-'}  •  ${app.text('stock')}: ${p['quantity']}'), trailing: Text('${p['price']} ر.ي')); }))]);
  }
  Future<void> _add(BuildContext context) async {
    final app = context.read<AppProvider>(); final name = TextEditingController(); final barcode = TextEditingController(); final price = TextEditingController(); final qty = TextEditingController(text: '0');
    final result = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: Text(app.text('add')), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: InputDecoration(labelText: app.text('name'))), TextField(controller: barcode, decoration: InputDecoration(labelText: app.text('barcode'))), TextField(controller: price, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: app.text('price'))), TextField(controller: qty, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: app.text('quantity')))])), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(app.text('cancel'))), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(app.text('save')))]));
    if (result == true && name.text.trim().isNotEmpty) await app.addProduct(name: name.text, barcode: barcode.text, price: double.tryParse(price.text) ?? 0, quantity: int.tryParse(qty.text) ?? 0);
  }
}
