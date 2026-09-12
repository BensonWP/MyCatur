import 'package:flutter/material.dart';
import '../theme/gold_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Image.asset(
                'logo.png',
                width: 120,
                height: 120,
                semanticLabel: 'Logo MyCatur',
              ),
              const SizedBox(height: 16),
              const Text(
                'MyCatur',
                style: TextStyle(
                  color: GoldTheme.creamText,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Versi 1.0.0.',
                style: TextStyle(
                    color: GoldTheme.creamText, fontSize: 13),
              ),
              const SizedBox(height: 12),
              const Text(
                'Main catur berdua di satu HP atau lawan komputer offline, dengan aturan lengkap dan jam catur.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: GoldTheme.creamText,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Dibuat dengan Flutter.',
                style: TextStyle(
                    color: GoldTheme.creamText, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
