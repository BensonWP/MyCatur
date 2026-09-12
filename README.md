# MyCatur

Aplikasi catur kayu untuk Android, dibuat dengan Flutter. Main berdua di
satu HP atau lawan komputer offline, dengan aturan lengkap (rokade,
en passant, promosi), jam catur, riwayat notasi SAN, dan statistik di
perangkat. Tema terang ivory dengan papan kayu.

## Jalan cepat

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

Uji widget butuh `flutter test`. Tidak ada backend, tidak ada akun:
semua data (pengaturan, statistik) tersimpan lokal via shared_preferences.

## Struktur

- `lib/chess/` mesin catur murni Dart: `game_state.dart` (aturan +
  notasi SAN huruf Indonesia R/M/B/G/K), `ai.dart` (minimax + quiescence),
  `chess_clock.dart`, `game_settings.dart`, `app_prefs.dart`,
  `stats_store.dart`.
- `lib/screens/` beranda, papan permainan, cara main, statistik, tentang.
- `lib/widgets/animated_board_widget.dart` papan kayu dengan animasi langkah.
- `lib/theme/gold_theme.dart` token desain (warna kayu-emas, teks, spasi).
- `test/` unit mesin + widget layar utama.
