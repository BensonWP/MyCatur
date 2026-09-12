import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/gold_theme.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _go();
        return;
      }
      _timer = Timer(const Duration(milliseconds: 900), _go);
    });
  }

  void _go() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.of(context).disableAnimations;
    return Scaffold(
      backgroundColor: GoldTheme.background,
      body: Center(
        child: Semantics(
          label: 'MyCatur sedang dibuka',
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: reduced ? 1.0 : 0.8, end: 1.0),
            duration: Duration(milliseconds: reduced ? 0 : 500),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(scale: value, child: child),
              );
            },
            child: Image.asset(
              'logo.png',
              width: 160,
              height: 160,
              semanticLabel: 'Logo MyCatur',
            ),
          ),
        ),
      ),
    );
  }
}
