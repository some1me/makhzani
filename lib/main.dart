import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'database/database.dart';
import 'providers/app_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar');

  final database = await AppDatabase.instance;
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(database),
      child: const MakhzaniApp(),
    ),
  );
}
