import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'barcode_scanner_screen.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});
  @override
  State<PosScreen> createState() => _PosScreenState();
}
class _PosScreenState extends State<PosScreen> {
  final _search = TextEditingController();
  final _discount = TextEditingController(text: '0');
  String _payment = 'cash';
  @override
  void dispose() { _search.dispose(); _discount.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final query = _search.text.toLowerCase();
    final matches = app.products.where((p) => '${p['name']} ${p['barcode'] ?? ''}'.toLowerCase().contains(query)).toList();
    return Column(children: [
      Padding(padding: const EdgeInsets.all(12), child: Row(children: [Expanded(child: TextField(controller: _search, onChanged: (_) => setState(() {}), decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: app.text('search'), border: const OutlineInputBorder()))), const SizedBox(width: 8), IconButton.filledTonal(onPressed: () async { final code = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const BarcodeScannerScreen())); if (code != null && mounted) { final product = app.products.where((p) => p['barcode'] == code).firstOrNull; if (product != null) { try { app.addToCart(product); } catch (e) { _message(e.toString()); } } else { setState(() => _search.text = code); } } }, icon: const Icon(Icons.qr_code_scanner), tooltip: app.text('scan'))])),
      Expanded(child: matches.isEmpty ? Center(child: Text(app.text('no_products'))) : ListView.builder(itemCount: matches.length, itemBuilder: (_, i) { final p = matches[i]; return ListTile(title: Text('${p['name']}'), subtitle: Text('${app.text('stock')}: ${p['quantity']}'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text('${p['price']} ر.ي'), IconButton(onPressed: (p['quantity'] as int) > 0 ? () { try { app.addToCart(p); } catch (e) { _message(e.toString()); } } : null, icon: const Icon(Icons.add_shopping_cart))])); })),
      Card(margin: const EdgeInsets.all(12), child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [Align(alignment: Alignment.centerRight, child: Text('${app.text('cart')} (${app.cart.length})', style: Theme.of(context).textTheme.titleMedium)), ...app.cart.entries.map((entry) { final p = app.products.firstWhere((x) => x['id'] == entry.key); return ListTile(dense: true, title: Text('${p['name']}'), subtitle: Text('${p['price']} × ${entry.value}'), trailing: Wrap(children: [IconButton(onPressed: () => app.changeCartQuantity(entry.key, -1), icon: const Icon(Icons.remove)), Text('${entry.value}'), IconButton(onPressed: () => app.changeCartQuantity(entry.key, 1), icon: const Icon(Icons.add))])); }), Row(children: [Expanded(child: TextField(controller: _discount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: app.text('discount')))), const SizedBox(width: 12), DropdownButton<String>(value: _payment, items: [DropdownMenuItem(value: 'cash', child: Text(app.text('cash'))), DropdownMenuItem(value: 'card', child: Text(app.text('card')))], onChanged: (v) => setState(() => _payment = v ?? 'cash'))]), const SizedBox(height: 8), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(app.text('total')), Text('${(app.cartSubtotal - (double.tryParse(_discount.text) ?? 0)).clamp(0, double.infinity).toStringAsFixed(2)} ر.ي')]), const SizedBox(height: 8), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: app.cart.isEmpty ? null : () async { try { await app.checkout(discount: double.tryParse(_discount.text) ?? 0, paymentMethod: _payment); _discount.text = '0'; _message(app.text('done')); } catch (e) { _message(e.toString()); } }, icon: const Icon(Icons.check), label: Text(app.text('checkout')))]),]))),
    ]);
  }
  void _message(String message) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message))); }
}
