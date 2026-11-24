import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class PurchasesScreen extends StatelessWidget {
  const PurchasesScreen({super.key});
  @override
  Widget build(BuildContext context) { final app = context.watch<AppProvider>(); return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.shopping_cart_outlined, size: 56), const SizedBox(height: 12), Text(app.text('purchases')), const Text('إدارة فواتير الموردين ستضاف في تحديث لاحق.') ])); }
}
