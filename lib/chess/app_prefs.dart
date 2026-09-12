import 'package:shared_preferences/shared_preferences.dart';
import 'ai.dart';
import 'game_settings.dart';
import 'piece.dart';

/// Mode permainan terakhir. Disimpan agar beranda bisa menawarkan
/// "Ulangi" tanpa lewat layar setup.
enum PlayMode { ai, duo }

/// Muat/simpan preferensi antar sesi. Kunci dibaca defensif: indeks enum
/// dijaga dengan modulo supaya tidak crash kalau urutan enum berubah.
class AppPrefs {
  static const _tempo = 'tempo';
  static const _clock = 'clock';
  static const _animation = 'animation';
  static const _humanColor = 'human_color';
  static const _aiLevel = 'ai_level';
  static const _playMode = 'play_mode';

  static Future<GameSettings> loadGame() async {
    final p = await SharedPreferences.getInstance();
    return GameSettings(
      tempo: Tempo.values[(p.getInt(_tempo) ?? Tempo.santai.index) %
          Tempo.values.length],
      clock: ClockOption
          .values[(p.getInt(_clock) ?? ClockOption.tanpa.index) %
              ClockOption.values.length],
      animation: p.getBool(_animation) ?? true,
    );
  }

  static Future<void> saveGame(GameSettings s) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_tempo, s.tempo.index);
    await p.setInt(_clock, s.clock.index);
    await p.setBool(_animation, s.animation);
  }

  static Future<PieceColor> loadHumanColor() async {
    final p = await SharedPreferences.getInstance();
    return PieceColor
        .values[(p.getInt(_humanColor) ?? PieceColor.white.index) %
            PieceColor.values.length];
  }

  static Future<AiLevel> loadAiLevel() async {
    final p = await SharedPreferences.getInstance();
    return AiLevel.values[(p.getInt(_aiLevel) ?? AiLevel.medium.index) %
        AiLevel.values.length];
  }

  static Future<void> saveHome(PieceColor color, AiLevel level) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_humanColor, color.index);
    await p.setInt(_aiLevel, level.index);
  }

  static Future<PlayMode?> loadPlayMode() async {
    final p = await SharedPreferences.getInstance();
    final i = p.getInt(_playMode);
    if (i == null || i < 0 || i >= PlayMode.values.length) return null;
    return PlayMode.values[i];
  }

  static Future<void> savePlayMode(PlayMode mode) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_playMode, mode.index);
  }
}
