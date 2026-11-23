import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import 'pos_screen.dart';
import 'products_screen.dart';
import 'purchases_screen.dart';
import 'reports_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final _screens = const [
    PosScreen(),
    ProductsScreen(),
    PurchasesScreen(),
    ReportsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.point_of_sale), label: 'البيع'),
          NavigationDestination(icon: Icon(Icons.inventory_2), label: 'المنتجات'),
          NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'المشتريات'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'التقارير'),
        ],
      ),
    );
  }
}
