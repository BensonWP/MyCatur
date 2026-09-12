import 'dart:async';
import 'package:flutter/material.dart';
import '../chess/ai.dart';
import '../chess/app_prefs.dart';
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
  Timer? _demoTimer;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) return;
      _demoTimer =
          Timer.periodic(const Duration(milliseconds: 1400), (_) {
        _demoStep();
      });
    });
  }

  Future<void> _loadPrefs() async {
    final color = await AppPrefs.loadHumanColor();
    final aiLevel = await AppPrefs.loadAiLevel();
    if (!mounted) return;
    setState(() {
      humanColor = color;
      level = aiLevel;
    });
  }

  void _savePrefs() => unawaited(AppPrefs.saveHome(humanColor, level));

  void _demoStep() {
    if (!mounted) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;
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
    _demoTimer?.cancel();
    super.dispose();
  }

  void _startAiGame() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          vsAi: true,
          humanColor: humanColor,
          level: level,
        ),
      ),
    );
  }

  void _startTwoPlayerGame() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const GameScreen(vsAi: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(GoldTheme.gap20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: GoldTheme.gap8),
              Text('MyCatur', style: text.displaySmall),
              const SizedBox(height: GoldTheme.gap8),
              Text(
                'Papan kayu di HPmu. Main berdua atau lawan komputer offline.',
                style: text.bodyLarge,
              ),
              const SizedBox(height: GoldTheme.gap20),
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
              const SizedBox(height: GoldTheme.gap20),
              Container(
                padding: const EdgeInsets.all(GoldTheme.gap16),
                decoration: BoxDecoration(
                  color: GoldTheme.frame,
                  borderRadius:
                      BorderRadius.circular(GoldTheme.radiusCard),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Lawan komputer', style: text.titleLarge),
                    const SizedBox(height: GoldTheme.gap4),
                    Text(
                      'Atur warna dan level, langsung main.',
                      style: text.titleSmall,
                    ),
                    const SizedBox(height: GoldTheme.gap12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                humanColor == PieceColor.white
                                    ? null
                                    : () {
                                        setState(() => humanColor =
                                            PieceColor.white);
                                        _savePrefs();
                                      },
                            child: const Text('Putih'),
                          ),
                        ),
                        const SizedBox(width: GoldTheme.gap12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                humanColor == PieceColor.black
                                    ? null
                                    : () {
                                        setState(() => humanColor =
                                            PieceColor.black);
                                        _savePrefs();
                                      },
                            child: const Text('Hitam'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: GoldTheme.gap8),
                    Row(
                      children: AiLevel.values.map((l) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                                right: GoldTheme.gap8),
                            child: OutlinedButton(
                              onPressed: level == l
                                  ? null
                                  : () {
                                      setState(() => level = l);
                                      _savePrefs();
                                    },
                              child: Text(l.label),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: GoldTheme.gap12),
                    ElevatedButton(
                      onPressed: _startAiGame,
                      child: const Text('Mulai lawan komputer'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: GoldTheme.gap12),
              Text(
                'Dua orang, satu HP. Rokade, en passant, dan promosi didukung.',
                style: text.titleSmall,
              ),
              const SizedBox(height: GoldTheme.gap8),
              OutlinedButton(
                onPressed: _startTwoPlayerGame,
                child: const Text('Main berdua'),
              ),
              const SizedBox(height: GoldTheme.gap8),
            ],
          ),
        ),
      ),
    );
  }
}
