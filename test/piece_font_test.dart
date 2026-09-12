import 'package:catur/chess/game_state.dart';
import 'package:catur/theme/gold_theme.dart';
import 'package:catur/widgets/animated_board_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Semua Text bidak di papan harus memakai font ChessGlyphs yang
  // di-bundle, supaya tidak ada fallback ke font emoji device yang
  // warnanya di luar kendali aplikasi (kasus: pion hitam-putih
  // terlihat sama).
  testWidgets('Glif bidak papan memakai font ChessGlyphs', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: GoldTheme.theme(),
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: AnimatedBoardWidget(
              state: GameState(),
              selectedR: null,
              selectedC: null,
              targets: const [],
              lastMove: null,
              lastWasCapture: false,
              flipped: false,
              onTap: (_, __) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final pawnTexts = tester
        .widgetList<Text>(find.textContaining('♟'))
        .where((t) => t.style?.fontFamily != null)
        .toList();
    expect(pawnTexts, isNotEmpty);
    for (final t in pawnTexts) {
      expect(t.style!.fontFamily, GoldTheme.pieceFont);
    }
    // Papan awal: 16 pion x 2 lapis (stroke + fill) = 32 Text pion.
    expect(pawnTexts.length, 32);
  });
}
