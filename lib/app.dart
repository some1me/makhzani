import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';

class MakhzaniApp extends StatelessWidget {
  const MakhzaniApp({super.key});
  @override
  Widget build(BuildContext context) => Consumer<AppProvider>(
    builder: (context, app, _) => MaterialApp(
      title: 'مخزني', debugShowCheckedModeBanner: false,
      locale: app.locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF1565C0)),
      builder: (context, child) => Directionality(
        textDirection: app.locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        child: child!,
      ),
      home: const HomeScreen(),
    ),
  );
}
