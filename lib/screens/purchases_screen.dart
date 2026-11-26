import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});
  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}
class _PurchasesScreenState extends State<PurchasesScreen> {
  final Map<int, int> _quantities = {};
  final Map<int, double> _costs = {};
  final _supplier = TextEditingController();
  @override
  void dispose() { _supplier.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    return Column(children: [Padding(padding: const EdgeInsets.all(16), child: TextField(controller: _supplier, decoration: InputDecoration(labelText: app.text('supplier')))), Expanded(child: app.products.isEmpty ? Center(child: Text(app.text('no_products'))) : ListView.builder(itemCount: app.products.length, itemBuilder: (_, i) { final p = app.products[i]; final id = p['id'] as int; return ListTile(title: Text('${p['name']}'), subtitle: Text('${app.text('stock')}: ${p['quantity']}'), trailing: SizedBox(width: 150, child: Row(children: [Expanded(child: TextField(keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Qty'), onChanged: (v) => _quantities[id] = int.tryParse(v) ?? 0)), Expanded(child: TextField(keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(hintText: 'Cost'), onChanged: (v) => _costs[id] = double.tryParse(v) ?? 0))]))); })), Padding(padding: const EdgeInsets.all(16), child: SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () async { final quantities = Map<int, int>.from(_quantities)..removeWhere((_, q) => q <= 0); if (quantities.isEmpty) return; try { await app.recordPurchase(quantities: quantities, costs: _costs, supplier: _supplier.text); _quantities.clear(); _costs.clear(); _supplier.clear(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(app.text('done')))); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); } }, icon: const Icon(Icons.save), label: Text(app.text('record_purchase'))))) ]);
  }
}
