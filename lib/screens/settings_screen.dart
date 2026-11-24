import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    return Scaffold(appBar: AppBar(title: Text(app.text('settings'))), body: ListView(children: [
      ListTile(title: Text(app.text('language')), trailing: DropdownButton<String>(value: app.locale.languageCode, items: [DropdownMenuItem(value: 'ar', child: Text(app.text('arabic'))), DropdownMenuItem(value: 'en', child: Text(app.text('english')))], onChanged: (value) { if (value != null) app.setLanguage(value); })),
      const ListTile(title: Text('البيانات محفوظة محلياً على هذا الجهاز باستخدام SQLite')),
    ]));
  }
}
