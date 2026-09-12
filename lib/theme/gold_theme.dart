import 'package:flutter/material.dart';

// Token Emas Pesta. Emas diambil dari mahkota logo, dipakai sebagai
// satu-satunya aksen untuk pilihan, tombol primer, dan nav aktif.
class GoldTheme {
  static const background = Color(0xFF171006);
  static const frame = Color(0xFF3E2A1A);
  static const lightSquare = Color(0xFFF0DDAE);
  static const darkSquare = Color(0xFF7A4E2B);
  static const creamText = Color(0xFFF7ECD4);
  static const darkText = Color(0xFF1A120B);
  static const accent = Color(0xFFF2B705);
  static const checkMark = Color(0xFFB3261E);

  // Varian kalem untuk tempo santai. Latar digelapkan dan emas
  // diredupkan agar rasa tenang tanpa mengorbankan kontras.
  static const calmBackground = Color(0xFF100C07);
  static const calmFrame = Color(0xFF2A1D11);
  static const calmLightSquare = Color(0xFFD9C49C);
  static const calmDarkSquare = Color(0xFF5F3B22);
  static const calmAccent = Color(0xFFC9960A);

  // Skala spasi. Kelipatan 4, dipakai di semua layar agar ritme konsisten.
  static const gap4 = 4.0;
  static const gap8 = 8.0;
  static const gap12 = 12.0;
  static const gap16 = 16.0;
  static const gap20 = 20.0;
  static const gap24 = 24.0;
  static const radiusCard = 12.0;
  static const radiusButton = 8.0;

  static ThemeData theme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        onPrimary: darkText,
        surface: background,
        onSurface: creamText,
      ),
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          color: creamText,
          fontWeight: FontWeight.w700,
          fontSize: 36,
        ),
        headlineSmall: TextStyle(
          color: creamText,
          fontWeight: FontWeight.w700,
          fontSize: 28,
        ),
        titleLarge: TextStyle(
          color: creamText,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        titleMedium: TextStyle(color: creamText, fontSize: 16),
        titleSmall: TextStyle(color: creamText, fontSize: 13),
        bodyLarge: TextStyle(color: creamText, fontSize: 15),
        bodyMedium: TextStyle(color: creamText, fontSize: 14, height: 1.5),
        bodySmall: TextStyle(color: creamText, fontSize: 12),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: frame,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
        titleTextStyle: const TextStyle(
          color: creamText,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        contentTextStyle: const TextStyle(
          color: creamText,
          fontSize: 14,
          height: 1.5,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: frame,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusCard)),
        ),
        showDragHandle: true,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: frame,
        textStyle: TextStyle(color: creamText, fontSize: 14),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: darkText,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusButton)),
          minimumSize: const Size(48, 48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: creamText,
          side: const BorderSide(color: creamText),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusButton)),
          minimumSize: const Size(48, 48),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: frame,
        selectedItemColor: accent,
        unselectedItemColor: creamText,
      ),
    );
  }
}
