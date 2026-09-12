import 'dart:async';
import 'package:flutter/material.dart';
import '../chess/ai.dart';
import '../chess/game_state.dart';
import '../chess/move.dart';
import '../chess/piece.dart';
import '../theme/gold_theme.dart';
import '../widgets/animated_board_widget.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PieceColor humanColor = PieceColor.white;
  AiLevel level = AiLevel.medium;
  GameState preview = GameState();
  ChessMove? demoMove;
  bool demoCapture = false;
  int visibleBlocks = 0;
  Timer? _entranceTimer;
  Timer? _demoTimer;

  static const int _blockCount = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        setState(() => visibleBlocks = _blockCount);
        return;
      }
      _entranceTimer =
          Timer.periodic(const Duration(milliseconds: 80), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() => visibleBlocks++);
        if (visibleBlocks >= _blockCount) timer.cancel();
      });
      _demoTimer =
          Timer.periodic(const Duration(milliseconds: 1400), (_) {
        _demoStep();
      });
    });
  }

  void _demoStep() {
    if (!mounted) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;
    if (MediaQuery.of(context).disableAnimations) {
      _demoTimer?.cancel();
      return;
    }
    if (preview.result() != GameResult.ongoing) {
      setState(() {
        preview = GameState();
        demoMove = null;
        demoCapture = false;
      });
      return;
    }
    final move = pickMoveSync(
      GameState.clone(preview),
      1,
      seed: DateTime.now().millisecond,
    );
    if (move == null) return;
    setState(() {
      demoCapture =
          preview.at(move.toR, move.toC) != null || move.isEnPassant;
      preview.apply(move);
      demoMove = move;
    });
  }

  @override
  void dispose() {
    _entranceTimer?.cancel();
    _demoTimer?.cancel();
    super.dispose();
  }

  Widget _block(int index, Widget child) {
    final visible = visibleBlocks > index;
    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 0.15),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _block(
                0,
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 8),
                    Text(
                      'MyCatur',
                      style: TextStyle(
                        color: GoldTheme.creamText,
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Papan kayu di HPmu. Main berdua atau lawan komputer offline.',
                      style: TextStyle(
                        color: GoldTheme.creamText,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _block(
                1,
                IgnorePointer(
                  child: AnimatedBoardWidget(
                    state: preview,
                    selectedR: null,
                    selectedC: null,
                    targets: const [],
                    lastMove: demoMove,
                    lastWasCapture: demoCapture,
                    flipped: false,
                    onTap: (_, __) {},
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _block(
                2,
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: GoldTheme.frame,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Lawan komputer',
                        style: TextStyle(
                          color: GoldTheme.creamText,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Atur warna dan level, langsung main.',
                        style: TextStyle(
                          color: GoldTheme.creamText,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed:
                                  humanColor == PieceColor.white
                                      ? null
                                      : () => setState(() =>
                                          humanColor = PieceColor.white),
                              child: const Text('Putih'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed:
                                  humanColor == PieceColor.black
                                      ? null
                                      : () => setState(() =>
                                          humanColor = PieceColor.black),
                              child: const Text('Hitam'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: AiLevel.values.map((l) {
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(right: 8),
                              child: OutlinedButton(
                                onPressed: level == l
                                    ? null
                                    : () =>
                                        setState(() => level = l),
                                child: Text(l.label),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => GameScreen(
                                vsAi: true,
                                humanColor: humanColor,
                                level: level,
                              ),
                            ),
                          );
                        },
                        child: const Text('Mulai lawan komputer'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _block(
                3,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Dua orang, satu HP.',
                      style: TextStyle(
                        color: GoldTheme.creamText,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const GameScreen(vsAi: false),
                          ),
                        );
                      },
                      child: const Text('Main berdua'),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '1. Pilih mode.',
                      style: TextStyle(
                        color: GoldTheme.creamText,
                        fontSize: 13,
                        height: 1.7,
                      ),
                    ),
                    const Text(
                      '2. Atur warna dan level.',
                      style: TextStyle(
                        color: GoldTheme.creamText,
                        fontSize: 13,
                        height: 1.7,
                      ),
                    ),
                    const Text(
                      '3. Mainkan.',
                      style: TextStyle(
                        color: GoldTheme.creamText,
                        fontSize: 13,
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _block(
                4,
                const Text(
                  'Rokade, en passant, dan promosi didukung.',
                  style: TextStyle(
                    color: GoldTheme.creamText,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
