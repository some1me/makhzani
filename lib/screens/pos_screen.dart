import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class PosScreen extends StatelessWidget {
  const PosScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    return ListView(padding: const EdgeInsets.all(16), children: [Text(app.text('sales'), style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 8), const Text('اختر المنتجات من القائمة لإضافتها إلى فاتورة البيع. إدارة السلة وإتمام الدفع ضمن المرحلة التالية.'), const SizedBox(height: 12), ...app.products.map((p) => Card(child: ListTile(title: Text('${p['name']}'), subtitle: Text('${p['quantity']} متوفر'), trailing: Text('${p['price']} ر.ي'))))]);
  }
}
