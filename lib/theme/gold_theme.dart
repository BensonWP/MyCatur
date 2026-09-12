import 'package:flutter/material.dart';

// Token Tema Ivory. Latar terang krem-ivori, bingkai papan walnut,
// tinta gelap untuk teks. Emas gelap adalah satu-satunya aksen:
// pilihan, target langkah, tombol primer, dan nav aktif.
class GoldTheme {
  static const background = Color(0xFFF5EDDC);
  static const frame = Color(0xFF7A4E2B);
  static const lightSquare = Color(0xFFEEDBB4);
  static const darkSquare = Color(0xFF7A4E2B);
  static const ink = Color(0xFF241A10);
  static const onFrameText = Color(0xFFF5EBD8);
  // Emas tua: AA (4.9:1) dengan teks krem di tombol primer di atas ivory.
  static const accent = Color(0xFF8A5D14);
  // Emas terang untuk elemen aksen di atas walnut (nav aktif).
  static const navActive = Color(0xFFD9A441);
  static const checkMark = Color(0xFFB3261E);

  // Varian kalem untuk tempo santai. Ivory lebih lembut dan aksen
  // diredupkan agar rasa tenang tanpa mengorbankan kontras.
  static const calmBackground = Color(0xFFFAF4E8);
  static const calmFrame = Color(0xFF855630);
  static const calmLightSquare = Color(0xFFE6D2AE);
  static const calmDarkSquare = Color(0xFF6E4426);
  static const calmAccent = Color(0xFF9A6C1E);

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
      colorScheme: const ColorScheme.light(
        primary: frame,
        onPrimary: onFrameText,
        surface: background,
        onSurface: ink,
      ),
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          color: ink,
          fontWeight: FontWeight.w700,
          fontSize: 36,
        ),
        headlineSmall: TextStyle(
          color: ink,
          fontWeight: FontWeight.w700,
          fontSize: 28,
        ),
        titleLarge: TextStyle(
          color: ink,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        titleMedium: TextStyle(color: ink, fontSize: 16),
        titleSmall: TextStyle(color: ink, fontSize: 13),
        bodyLarge: TextStyle(color: ink, fontSize: 15),
        bodyMedium: TextStyle(color: ink, fontSize: 14, height: 1.5),
        bodySmall: TextStyle(color: ink, fontSize: 12),
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
          color: onFrameText,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        contentTextStyle: const TextStyle(
          color: onFrameText,
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
        textStyle: TextStyle(color: onFrameText, fontSize: 14),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onFrameText,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusButton)),
          minimumSize: const Size(48, 48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: const BorderSide(color: accent),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusButton)),
          minimumSize: const Size(48, 48),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: frame,
        selectedItemColor: navActive,
        unselectedItemColor: onFrameText,
      ),
    );
  }
}
