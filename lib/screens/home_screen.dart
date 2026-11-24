import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'pos_screen.dart';
import 'products_screen.dart';
import 'purchases_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AppProvider>().loadData()); }
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final screens = [PosScreen(), ProductsScreen(), PurchasesScreen(), ReportsScreen()];
    return Scaffold(
      appBar: AppBar(title: Text(app.text('app')), actions: [IconButton(tooltip: app.text('settings'), icon: const Icon(Icons.settings), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))) ]),
      body: screens[_index],
      bottomNavigationBar: NavigationBar(selectedIndex: _index, onDestinationSelected: (i) => setState(() => _index = i), destinations: [
        NavigationDestination(icon: const Icon(Icons.point_of_sale), label: app.text('sales')),
        NavigationDestination(icon: const Icon(Icons.inventory_2), label: app.text('products')),
        NavigationDestination(icon: const Icon(Icons.shopping_cart), label: app.text('purchases')),
        NavigationDestination(icon: const Icon(Icons.bar_chart), label: app.text('reports')),
      ]),
    );
  }
}
