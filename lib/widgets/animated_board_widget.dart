import 'package:flutter/material.dart';
import '../chess/game_state.dart';
import '../chess/move.dart';
import '../chess/piece.dart';
import '../theme/gold_theme.dart';

class AnimatedBoardWidget extends StatefulWidget {
  final GameState state;
  final int? selectedR;
  final int? selectedC;
  final List<ChessMove> targets;
  final ChessMove? lastMove;
  final bool lastWasCapture;
  final bool flipped;
  final bool calm;
  final Duration moveDuration;
  final bool animationEnabled;
  final void Function(int r, int c) onTap;

  const AnimatedBoardWidget({
    super.key,
    required this.state,
    required this.selectedR,
    required this.selectedC,
    required this.targets,
    required this.lastMove,
    required this.lastWasCapture,
    required this.flipped,
    this.calm = false,
    this.moveDuration = const Duration(milliseconds: 200),
    this.animationEnabled = true,
    required this.onTap,
  });

  @override
  State<AnimatedBoardWidget> createState() => _AnimatedBoardWidgetState();
}

class _AnimatedBoardWidgetState extends State<AnimatedBoardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fly;
  ChessMove? _flyMove;

  @override
  void initState() {
    super.initState();
    _fly = AnimationController(
      vsync: this,
      duration: widget.moveDuration,
    );
    _fly.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _flyMove = null);
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedBoardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _fly.duration = widget.moveDuration;
    if (widget.lastMove != oldWidget.lastMove && widget.lastMove != null) {
      if (!widget.animationEnabled) return;
      if (widget.moveDuration == Duration.zero) return;
      if (MediaQuery.of(context).disableAnimations) return;
      _flyMove = widget.lastMove;
      _fly.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _fly.dispose();
    super.dispose();
  }

  int _displayRow(int r) => widget.flipped ? 7 - r : r;
  int _displayCol(int c) => widget.flipped ? 7 - c : c;

  TextStyle _pieceStyle(Piece piece, double size) {
    if (piece.color == PieceColor.white) {
      return TextStyle(
        fontSize: size,
        color: GoldTheme.creamText,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.6),
            offset: const Offset(0, 1),
            blurRadius: 1,
          ),
        ],
      );
    }
    // Bidak hitam: glif filled gelap dengan cincin krem supaya terbaca
    // di petak terang maupun gelap.
    const ring = GoldTheme.creamText;
    return TextStyle(
      fontSize: size,
      color: const Color(0xFF14100B),
      shadows: const [
        Shadow(color: ring, offset: Offset(0, 1), blurRadius: 0),
        Shadow(color: ring, offset: Offset(0, -1), blurRadius: 0),
        Shadow(color: ring, offset: Offset(1, 0), blurRadius: 0),
        Shadow(color: ring, offset: Offset(-1, 0), blurRadius: 0),
        Shadow(
          color: Color(0x99000000),
          offset: Offset(0, 1),
          blurRadius: 2,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final checkPos = widget.state.isInCheck(widget.state.turn)
        ? widget.state.kingPos(widget.state.turn)
        : null;
    final frame =
        widget.calm ? GoldTheme.calmFrame : GoldTheme.frame;
    final light =
        widget.calm ? GoldTheme.calmLightSquare : GoldTheme.lightSquare;
    final dark =
        widget.calm ? GoldTheme.calmDarkSquare : GoldTheme.darkSquare;
    final accent =
        widget.calm ? GoldTheme.calmAccent : GoldTheme.accent;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: frame,
        borderRadius: BorderRadius.circular(12),
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final sq = constraints.maxWidth / 8;
            final glyphSize = sq * 0.62;
            return Stack(
              children: [
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                  ),
                  itemCount: 64,
                  itemBuilder: (context, index) {
                    final i = index ~/ 8;
                    final j = index % 8;
                    final r = widget.flipped ? 7 - i : i;
                    final c = widget.flipped ? 7 - j : j;
                    final isLight = (r + c) % 2 == 1;
                    final piece = widget.state.board[r][c];
                    final isSelected =
                        widget.selectedR == r && widget.selectedC == c;
                    final isTarget = widget.targets
                        .any((m) => m.toR == r && m.toC == c);
                    final isLast = widget.lastMove != null &&
                        ((widget.lastMove!.fromR == r &&
                                widget.lastMove!.fromC == c) ||
                            (widget.lastMove!.toR == r &&
                                widget.lastMove!.toC == c));
                    final isCheck = checkPos != null &&
                        checkPos[0] == r &&
                        checkPos[1] == c;
                    return GestureDetector(
                      onTap: () => widget.onTap(r, c),
                      child: Semantics(
                        label: 'Petak ${String.fromCharCode(97 + c)}${8 - r}'
                            '${piece != null ? ', ${piece.glyph}' : ''}'
                            '${isCheck ? ', raja skak' : ''}',
                        button: true,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isLight ? light : dark,
                            border: isSelected
                                ? Border.all(color: accent, width: 3)
                                : null,
                          ),
                          child: Stack(
                            children: [
                              if (isLast)
                                Container(
                                  color: accent.withValues(alpha: 0.28),
                                ),
                              if (isCheck)
                                Container(
                                  color: GoldTheme.checkMark
                                      .withValues(alpha: 0.45),
                                ),
                              if (isTarget && piece == null)
                                Center(
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: 1),
                                    duration:
                                        const Duration(milliseconds: 100),
                                    builder: (context, value, child) {
                                      return Opacity(
                                        opacity: value,
                                        child: child,
                                      );
                                    },
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: accent.withValues(alpha: 0.75),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              if (isTarget && piece != null)
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: accent,
                                      width: 3,
                                    ),
                                  ),
                                ),
                              if (isCheck)
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: TweenAnimationBuilder<double>(
                                    key: ValueKey(widget.lastMove),
                                    tween: Tween(begin: 1.5, end: 1.0),
                                    duration:
                                        const Duration(milliseconds: 200),
                                    builder: (context, value, child) {
                                      return Transform.scale(
                                        scale: value,
                                        child: child,
                                      );
                                    },
                                    child: const Icon(
                                      Icons.warning,
                                      size: 14,
                                      color: Colors.white,
                                      semanticLabel: 'Skak',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                for (var r = 0; r < 8; r++)
                  for (var c = 0; c < 8; c++)
                    if (widget.state.board[r][c] != null &&
                        !(_flyMove != null &&
                            _flyMove!.toR == r &&
                            _flyMove!.toC == c))
                      Positioned(
                        left: _displayCol(c) * sq,
                        top: _displayRow(r) * sq,
                        width: sq,
                        height: sq,
                          child: IgnorePointer(
                            child: Center(
                              child: Text(
                                widget.state.board[r][c]!.glyphSolid,
                              style: _pieceStyle(
                                widget.state.board[r][c]!,
                                glyphSize,
                              ),
                            ),
                          ),
                        ),
                      ),
                if (_flyMove != null)
                  AnimatedBuilder(
                    animation: _fly,
                    builder: (context, child) {
                      final t = Curves.easeOut.transform(_fly.value);
                      final from = Offset(
                        _displayCol(_flyMove!.fromC) * sq,
                        _displayRow(_flyMove!.fromR) * sq,
                      );
                      final to = Offset(
                        _displayCol(_flyMove!.toC) * sq,
                        _displayRow(_flyMove!.toR) * sq,
                      );
                      final pos = Offset.lerp(from, to, t)!;
                      final piece =
                          widget.state.board[_flyMove!.toR][_flyMove!.toC];
                      return Positioned(
                        left: pos.dx,
                        top: pos.dy,
                        width: sq,
                        height: sq,
                        child: IgnorePointer(
                          child: Stack(
                            children: [
                              if (widget.lastWasCapture)
                                Opacity(
                                  opacity: 1 - t,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: GoldTheme.creamText,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              if (piece != null)
                                Center(
                                  child: Text(
                                    piece.glyphSolid,
                                    style: _pieceStyle(piece, glyphSize),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
