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
  final TextEditingController _search = TextEditingController();
  final TextEditingController _discount = TextEditingController(text: '0');
  String _payment = 'cash';

  @override
  void dispose() {
    _search.dispose();
    _discount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final query = _search.text.toLowerCase();
    final matches = app.products.where((product) {
      final searchable = '${product['name']} ${product['barcode'] ?? ''}'.toLowerCase();
      return searchable.contains(query);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: app.text('search'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: app.text('scan'),
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: () async {
                  final code = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BarcodeScannerScreen(),
                    ),
                  );
                  if (code == null || !mounted) return;
                  final product = app.products
                      .where((item) => item['barcode'] == code)
                      .firstOrNull;
                  if (product == null) {
                    setState(() => _search.text = code);
                    return;
                  }
                  try {
                    app.addToCart(product);
                  } catch (error) {
                    _message(error.toString());
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: matches.isEmpty
              ? Center(child: Text(app.text('no_products')))
              : ListView.builder(
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final product = matches[index];
                    final stock = product['quantity'] as int;
                    return ListTile(
                      title: Text('${product['name']}'),
                      subtitle: Text('${app.text('stock')}: $stock'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${product['price']} ر.ي'),
                          IconButton(
                            icon: const Icon(Icons.add_shopping_cart),
                            onPressed: stock <= 0
                                ? null
                                : () {
                                    try {
                                      app.addToCart(product);
                                    } catch (error) {
                                      _message(error.toString());
                                    }
                                  },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        Card(
          margin: const EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    '${app.text('cart')} (${app.cart.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ...app.cart.entries.map((entry) {
                  final product = app.products.firstWhere(
                    (item) => item['id'] == entry.key,
                  );
                  return ListTile(
                    dense: true,
                    title: Text('${product['name']}'),
                    subtitle: Text('${product['price']} × ${entry.value}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => app.changeCartQuantity(entry.key, -1),
                          icon: const Icon(Icons.remove),
                        ),
                        Text('${entry.value}'),
                        IconButton(
                          onPressed: () => app.changeCartQuantity(entry.key, 1),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  );
                }),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _discount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: app.text('discount'),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _payment,
                      items: [
                        DropdownMenuItem(
                          value: 'cash',
                          child: Text(app.text('cash')),
                        ),
                        DropdownMenuItem(
                          value: 'card',
                          child: Text(app.text('card')),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _payment = value ?? 'cash'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(app.text('total')),
                    Text(
                      '${(app.cartSubtotal - (double.tryParse(_discount.text) ?? 0)).clamp(0, double.infinity).toStringAsFixed(2)} ر.ي',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: app.cart.isEmpty
                        ? null
                        : () async {
                            try {
                              await app.checkout(
                                discount: double.tryParse(_discount.text) ?? 0,
                                paymentMethod: _payment,
                              );
                              _discount.text = '0';
                              if (mounted) _message(app.text('done'));
                            } catch (error) {
                              _message(error.toString());
                            }
                          },
                    icon: const Icon(Icons.check),
                    label: Text(app.text('checkout')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
