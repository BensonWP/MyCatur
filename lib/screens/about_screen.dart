import 'package:flutter/material.dart';
import '../theme/gold_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(GoldTheme.gap20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: GoldTheme.gap24),
              Image.asset(
                'assets/logo.png',
                width: 120,
                height: 120,
                semanticLabel: 'Logo MyCatur',
              ),
              const SizedBox(height: GoldTheme.gap16),
              Text('MyCatur', style: text.headlineSmall),
              const SizedBox(height: GoldTheme.gap4),
              Text('Versi 1.0.0.', style: text.titleSmall),
              const SizedBox(height: GoldTheme.gap12),
              Text(
                'Main catur berdua di satu HP atau lawan komputer offline, dengan aturan lengkap dan jam catur.',
                textAlign: TextAlign.center,
                style: text.bodyMedium,
              ),
              const SizedBox(height: GoldTheme.gap12),
              Text('Dibuat dengan Flutter.', style: text.titleSmall),
            ],
          ),
        ),
      ),
    );
  }
}
