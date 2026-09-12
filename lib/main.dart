import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'chess/stats_store.dart';
import 'screens/splash_screen.dart';
import 'theme/gold_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StatsStore.instance.load();
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
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
