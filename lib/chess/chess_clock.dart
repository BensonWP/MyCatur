import 'piece.dart';

class ChessClock {
  int whiteMs;
  int blackMs;
  final int incrementMs;
  PieceColor? active;
  bool started = false;
  PieceColor? flagged;

  ChessClock({required int initialMs, required this.incrementMs})
      : whiteMs = initialMs,
        blackMs = initialMs;

  void start(PieceColor first) {
    started = true;
    active = first;
  }

  void onMove(PieceColor mover) {
    if (!started || flagged != null) return;
    if (mover == PieceColor.white) {
      whiteMs += incrementMs;
    } else {
      blackMs += incrementMs;
    }
    active = mover.opposite;
  }

  void tick(int ms) {
    if (!started || flagged != null || active == null) return;
    if (active == PieceColor.white) {
      whiteMs -= ms;
      if (whiteMs <= 0) {
        whiteMs = 0;
        flagged = PieceColor.white;
      }
    } else {
      blackMs -= ms;
      if (blackMs <= 0) {
        blackMs = 0;
        flagged = PieceColor.black;
      }
    }
  }

  static String format(int ms) {
    final totalSeconds = (ms / 1000).ceil();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
