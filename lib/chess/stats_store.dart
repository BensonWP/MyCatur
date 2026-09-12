import 'package:shared_preferences/shared_preferences.dart';
import 'ai.dart';
import 'piece.dart';

class StatsStore {
  static const _aiWin = 'ai_win_';
  static const _aiDraw = 'ai_draw_';
  static const _aiLoss = 'ai_loss_';
  static const _twoWhite = 'two_white';
  static const _twoBlack = 'two_black';
  static const _twoDraw = 'two_draw';

  final Map<String, int> _values = {};

  int _get(String key) => _values[key] ?? 0;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    for (final level in AiLevel.values) {
      final name = level.name;
      _values[_aiWin + name] = prefs.getInt(_aiWin + name) ?? 0;
      _values[_aiDraw + name] = prefs.getInt(_aiDraw + name) ?? 0;
      _values[_aiLoss + name] = prefs.getInt(_aiLoss + name) ?? 0;
    }
    _values[_twoWhite] = prefs.getInt(_twoWhite) ?? 0;
    _values[_twoBlack] = prefs.getInt(_twoBlack) ?? 0;
    _values[_twoDraw] = prefs.getInt(_twoDraw) ?? 0;
  }

  Future<void> _add(String key) async {
    _values[key] = _get(key) + 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, _values[key]!);
  }

  Future<void> recordAi({
    required AiLevel level,
    required int humanScore,
  }) async {
    if (humanScore > 0) {
      await _add(_aiWin + level.name);
    } else if (humanScore == 0) {
      await _add(_aiDraw + level.name);
    } else {
      await _add(_aiLoss + level.name);
    }
  }

  Future<void> recordTwoPlayer({required PieceColor? winner}) async {
    if (winner == null) {
      await _add(_twoDraw);
    } else if (winner == PieceColor.white) {
      await _add(_twoWhite);
    } else {
      await _add(_twoBlack);
    }
  }

  Future<void> clear() async {
    _values.clear();
    final prefs = await SharedPreferences.getInstance();
    for (final level in AiLevel.values) {
      await prefs.remove(_aiWin + level.name);
      await prefs.remove(_aiDraw + level.name);
      await prefs.remove(_aiLoss + level.name);
    }
    await prefs.remove(_twoWhite);
    await prefs.remove(_twoBlack);
    await prefs.remove(_twoDraw);
  }

  int aiWin(AiLevel level) => _get(_aiWin + level.name);
  int aiDraw(AiLevel level) => _get(_aiDraw + level.name);
  int aiLoss(AiLevel level) => _get(_aiLoss + level.name);
  int get twoWhite => _get(_twoWhite);
  int get twoBlack => _get(_twoBlack);
  int get twoDraw => _get(_twoDraw);

  bool get isEmpty =>
      _values.values.every((v) => v == 0);
}
