import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'theme/gold_theme.dart';

void main() {
  runApp(const MyCaturApp());
}

class MyCaturApp extends StatelessWidget {
  const MyCaturApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyCatur',
      debugShowCheckedModeBanner: false,
      theme: GoldTheme.theme(),
      home: const SplashScreen(),
    );
  }
}
