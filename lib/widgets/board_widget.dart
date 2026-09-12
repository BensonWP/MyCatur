import 'package:flutter/material.dart';
import '../chess/game_state.dart';
import '../chess/move.dart';
import '../chess/piece.dart';
import '../theme/gold_theme.dart';

class BoardWidget extends StatelessWidget {
  final GameState state;
  final int? selectedR;
  final int? selectedC;
  final List<ChessMove> targets;
  final ChessMove? lastMove;
  final bool flipped;
  final void Function(int r, int c) onTap;

  const BoardWidget({
    super.key,
    required this.state,
    required this.selectedR,
    required this.selectedC,
    required this.targets,
    required this.lastMove,
    required this.flipped,
    required this.onTap,
  });

  int _row(int i) => flipped ? 7 - i : i;
  int _col(int j) => flipped ? 7 - j : j;

  @override
  Widget build(BuildContext context) {
    final checkPos = state.isInCheck(state.turn)
        ? state.kingPos(state.turn)
        : null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GoldTheme.frame,
        borderRadius: BorderRadius.circular(12),
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
          ),
          itemCount: 64,
          itemBuilder: (context, index) {
            final i = index ~/ 8;
            final j = index % 8;
            final r = _row(i);
            final c = _col(j);
            final isLight = (r + c) % 2 == 1;
            final piece = state.board[r][c];
            final isSelected = selectedR == r && selectedC == c;
            final isTarget =
                targets.any((m) => m.toR == r && m.toC == c);
            final isLast = lastMove != null &&
                ((lastMove!.fromR == r && lastMove!.fromC == c) ||
                    (lastMove!.toR == r && lastMove!.toC == c));
            final isCheck =
                checkPos != null && checkPos[0] == r && checkPos[1] == c;

            return GestureDetector(
              onTap: () => onTap(r, c),
              child: Semantics(
                label: 'Petak ${String.fromCharCode(97 + c)}${8 - r}'
                    '${piece != null ? ', ${piece.glyph}' : ''}'
                    '${isCheck ? ', raja skak' : ''}',
                button: true,
                child: Container(
                  decoration: BoxDecoration(
                    color: isLight
                        ? GoldTheme.lightSquare
                        : GoldTheme.darkSquare,
                    border: isSelected
                        ? Border.all(color: GoldTheme.accent, width: 3)
                        : null,
                  ),
                  child: Stack(
                    children: [
                      if (isLast)
                        Container(
                            color: GoldTheme.accent.withValues(alpha: 0.28)),
                      if (isCheck)
                        Container(
                          color: GoldTheme.checkMark.withValues(alpha: 0.45),
                        ),
                      Center(
                        child: piece == null
                            ? null
                            : Text(
                                piece.glyph,
                                style: TextStyle(
                                  fontSize: 30,
                                  color: piece.color == PieceColor.white
                                      ? GoldTheme.creamText
                                      : GoldTheme.darkText,
                                  shadows: [
                                    Shadow(
                                      color: piece.color == PieceColor.white
                                          ? Colors.black.withValues(alpha: 0.6)
                                          : Colors.white.withValues(alpha: 0.35),
                                      offset: const Offset(0, 1),
                                      blurRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      if (isTarget && piece == null)
                        Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: GoldTheme.accent.withValues(alpha: 0.75),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      if (isTarget && piece != null)
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: GoldTheme.accent,
                              width: 3,
                            ),
                          ),
                        ),
                      if (isCheck)
                        const Positioned(
                          top: 2,
                          right: 2,
                          child: Icon(
                            Icons.warning,
                            size: 14,
                            color: Colors.white,
                            semanticLabel: 'Skak',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
