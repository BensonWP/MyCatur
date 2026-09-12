import 'dart:async';
import 'package:flutter/material.dart';
import '../chess/ai.dart';
import '../chess/game_state.dart';
import '../chess/move.dart';
import 'animated_board_widget.dart';

/// Papan di halaman awal yang bermain demo sendiri: dua "pemain AI"
/// saling membalas langkah supaya pratinjau terasa hidup.
class DemoBoard extends StatefulWidget {
  final bool animationEnabled;
  const DemoBoard({super.key, this.animationEnabled = true});

  @override
  State<DemoBoard> createState() => _DemoBoardState();
}

class _DemoBoardState extends State<DemoBoard> {
  final GameState _state = GameState();
  ChessMove? _last;
  bool _capture = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer =
        Timer.periodic(const Duration(milliseconds: 1100), (_) => _step());
  }

  // ponytail: Timer, bukan Ticker — Ticker menjadwalkan frame tiap tick
  // sehingga pumpAndSettle di test tidak pernah selesai.
  void _step() {
    if (!mounted || !widget.animationEnabled) return;
    if (!TickerMode.of(context)) return; // layar ini tertutup rute lain
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused) {
      return;
    }
    if (MediaQuery.of(context).disableAnimations) return;
    final move = pickMoveSync(GameState.clone(_state), 1, seed: 42);
    if (move == null) {
      _state.reset();
      _last = null;
    } else {
      _capture = _state.at(move.toR, move.toC) != null || move.isEnPassant;
      _state.apply(move);
      _last = move;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBoardWidget(
        state: _state,
        selectedR: null,
        selectedC: null,
        targets: const [],
        lastMove: _last,
        lastWasCapture: _capture,
        flipped: false,
        calm: true,
        moveDuration: const Duration(milliseconds: 450),
        animationEnabled: widget.animationEnabled,
        onTap: (_, __) {},
      ),
    );
  }
}
