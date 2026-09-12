# MyCatur

Aplikasi catur kayu untuk Android, dibuat dengan Flutter. Beranda
menampilkan papan demo yang bermain sendiri; dua tombol mode membuka
lembar bawah: "Lawan Komputer" (pilih warna Putih / Hitam, tingkat
kesulitan, jam catur) atau "Main Berdua" (pilih jam catur, langsung
mulai).

Layar permainan tanpa bar atas: strip pemain (nama, langkah terakhir
notasi SAN, bidak tertangkap + selisih material, jam catur), papan
maksimal hampir selebar layar, strip status giliran/skak, dan baris
aksi (kembali, urungkan, riwayat, menu: main baru, putar papan,
pengaturan, menyerah).

Aturan lengkap (rokade, en passant, promosi, repetisi tiga kali,
50 langkah), notasi SAN huruf Indonesia (R/M/B/G/K), AI minimax +
quiescence 3 tingkat yang berjalan di isolate, dan jam catur (tanpa
jam, kilat 3+2, cepat 5+0, santai 10+0). Hasil permainan dicatat ke
statistik lokal; tidak ada layar statistik. Offline penuh, semua data
(pengaturan, statistik) tersimpan lokal via shared_preferences.
Tidak ada backend, tidak ada akun.

Tema terang ivory dengan papan kayu. Bidak memakai font ChessGlyphs
(`assets/fonts`, lisensi OFL di `OFL.txt`) agar tampil konsisten di
semua perangkat Android. Animasi langkah menghormati pengaturan
sistem (reduced motion mematikan demo dan animasi).

## Jalan cepat

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

## Struktur

- `lib/chess/` mesin catur murni Dart: `game_state.dart` (aturan +
  notasi SAN huruf Indonesia R/M/B/G/K), `ai.dart` (minimax + quiescence),
  `chess_clock.dart`, `game_settings.dart`, `app_prefs.dart`,
  `stats_store.dart`.
- `lib/screens/` splash, beranda (demo + lembar mode), permainan.
- `lib/widgets/` `animated_board_widget.dart` (papan kayu + animasi
  langkah), `demo_board.dart` (demo main-sendiri di beranda),
  `sheets.dart` (lembar mode + pengaturan).
- `lib/theme/gold_theme.dart` token desain (warna kayu-emas, teks, spasi).
- `assets/fonts/ChessGlyphs.ttf` font bidak (OFL).
- `test/` 35 test: unit mesin (aturan, SAN, AI, jam) + widget layar.
