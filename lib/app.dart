import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

class MakhzaniApp extends StatelessWidget {
  const MakhzaniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مخزني',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'YE'),
      supportedLocales: const [Locale('ar', 'YE')],
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1565C0),
        fontFamily: null,
      ),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      home: const HomeScreen(),
    );
  }
}
