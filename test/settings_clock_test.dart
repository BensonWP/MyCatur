import 'package:catur/chess/chess_clock.dart';
import 'package:catur/chess/game_settings.dart';
import 'package:catur/chess/piece.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Jam berdetak di sisi aktif dan bendera jatuh', () {
    final clock = ChessClock(initialMs: 1000, incrementMs: 0);
    clock.start(PieceColor.white);
    clock.tick(600);
    expect(clock.whiteMs, 400);
    expect(clock.blackMs, 1000);
    clock.tick(500);
    expect(clock.flagged, PieceColor.white);
  });

  test('Increment ditambah dan giliran pindah', () {
    final clock = ChessClock(initialMs: 180000, incrementMs: 2000);
    clock.start(PieceColor.white);
    clock.onMove(PieceColor.white);
    expect(clock.whiteMs, 182000);
    expect(clock.active, PieceColor.black);
  });

  test('Format jam menit detik', () {
    expect(ChessClock.format(300000), '5:00');
    expect(ChessClock.format(182000), '3:02');
  });

  test('Tempo santai lebih kalem dan lambat', () {
    final santai = GameSettings(tempo: Tempo.santai);
    final cepat = GameSettings(tempo: Tempo.cepat);
    expect(santai.calm, true);
    expect(cepat.calm, false);
    expect(
      santai.moveDuration.inMilliseconds,
      greaterThan(cepat.moveDuration.inMilliseconds),
    );
    expect(santai.aiDelay.inMilliseconds, greaterThan(0));
    expect(cepat.aiDelay, Duration.zero);
  });

  test('Animasi mati berarti durasi nol', () {
    final s = GameSettings(animation: false);
    expect(s.moveDuration, Duration.zero);
  });
}
