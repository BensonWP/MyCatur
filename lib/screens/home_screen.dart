import 'dart:async';
import 'package:flutter/material.dart';
import '../chess/ai.dart';
import '../chess/app_prefs.dart';
import '../chess/game_settings.dart';
import '../chess/piece.dart';
import '../theme/gold_theme.dart';
import '../widgets/demo_board.dart';
import '../widgets/sheets.dart';
import 'game_screen.dart';

/// Halaman peluncur: header + pratinjau papan + dua tombol mode.
/// Pilihan per-mode dan pengaturan dibuka sebagai bottom sheet.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PieceColor humanColor = PieceColor.white;
  AiLevel level = AiLevel.medium;
  GameSettings settings = const GameSettings();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await AppPrefs.loadHumanColor();
    final l = await AppPrefs.loadAiLevel();
    final g = await AppPrefs.loadGame();
    if (!mounted) return;
    setState(() {
      humanColor = c;
      level = l;
      settings = g;
    });
  }

  void _openSettings() {
    openSettingsSheet(
      context,
      current: settings,
      onApply: (next) {
        setState(() => settings = next);
        unawaited(AppPrefs.saveGame(next));
      },
    );
  }

  void _openAiSheet() {
    var color = humanColor;
    var lvl = level;
    var clock = settings.clock;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        final text = Theme.of(sheetContext).textTheme;
        String levelHint(AiLevel l) {
          switch (l) {
            case AiLevel.easy:
              return 'Langkah cepat, cocok untuk belajar.';
            case AiLevel.medium:
              return 'Seimbang untuk main santai.';
            case AiLevel.hard:
              return 'Kuat, tapi berpikir lebih lama.';
          }
        }

        return StatefulBuilder(
          builder: (context, setSheetState) {
            void start() {
              Navigator.of(context).pop();
              unawaited(AppPrefs.saveGame(
                GameSettings(
                  tempo: settings.tempo,
                  clock: clock,
                  animation: settings.animation,
                ),
              ));
              unawaited(AppPrefs.savePlayMode(PlayMode.ai));
              unawaited(AppPrefs.saveHome(color, lvl));
              Navigator.of(this.context).push(
                MaterialPageRoute(
                  builder: (_) => GameScreen(
                    vsAi: true,
                    humanColor: color,
                    level: lvl,
                    settings: GameSettings(
                      tempo: settings.tempo,
                      clock: clock,
                      animation: settings.animation,
                    ),
                  ),
                ),
              );
            }

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                          GoldTheme.gap16,
                          GoldTheme.gap16,
                          GoldTheme.gap16,
                          GoldTheme.gap8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Lawan komputer', style: text.titleLarge),
                          const SizedBox(height: GoldTheme.gap16),
                          Text('Warna kamu', style: text.titleSmall),
                          const SizedBox(height: GoldTheme.gap8),
                          chipRow<PieceColor>(
                            values: PieceColor.values,
                            current: color,
                            label: (c) =>
                                '${Piece(c, PieceType.king).glyphSolid} '
                                '${c == PieceColor.white ? 'Putih' : 'Hitam'}',
                            onPick: (c) =>
                                setSheetState(() => color = c),
                          ),
                          const SizedBox(height: GoldTheme.gap4),
                          Text(
                            color == PieceColor.white
                                ? 'Putih jalan duluan.'
                                : 'Hitam di bawah, komputer jalan duluan.',
                            style: text.titleSmall,
                          ),
                          const SizedBox(height: GoldTheme.gap16),
                          Text('Tingkat komputer', style: text.titleSmall),
                          const SizedBox(height: GoldTheme.gap8),
                          chipRow<AiLevel>(
                            values: AiLevel.values,
                            current: lvl,
                            label: (l) => l.label,
                            onPick: (l) => setSheetState(() => lvl = l),
                          ),
                          const SizedBox(height: GoldTheme.gap4),
                          Text(levelHint(lvl), style: text.titleSmall),
                          const SizedBox(height: GoldTheme.gap16),
                          Text('Jam catur', style: text.titleSmall),
                          const SizedBox(height: GoldTheme.gap8),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: GoldTheme.gap8,
                            crossAxisSpacing: GoldTheme.gap8,
                            childAspectRatio: 3.2,
                            children: [
                              for (final c in ClockOption.values)
                                choiceChip(
                                  c.label,
                                  selected: clock == c,
                                  onTap: clock == c
                                      ? null
                                      : () => setSheetState(() => clock = c),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        GoldTheme.gap16,
                        GoldTheme.gap8,
                        GoldTheme.gap16,
                        GoldTheme.gap16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(48, 56),
                            ),
                            onPressed: start,
                            child: const Text(
                              'Mulai lawan komputer',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Batal'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openDuoSheet() {    var clock = settings.clock;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        final text = Theme.of(sheetContext).textTheme;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void start() {
              Navigator.of(context).pop();
              final next = GameSettings(
                tempo: settings.tempo,
                clock: clock,
                animation: settings.animation,
              );
              unawaited(AppPrefs.saveGame(next));
              unawaited(AppPrefs.savePlayMode(PlayMode.duo));
              Navigator.of(this.context).push(
                MaterialPageRoute(
                  builder: (_) => GameScreen(vsAi: false, settings: next),
                ),
              );
            }

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                          GoldTheme.gap16,
                          GoldTheme.gap16,
                          GoldTheme.gap16,
                          GoldTheme.gap8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Main berdua', style: text.titleLarge),
                          const SizedBox(height: GoldTheme.gap16),
                          Text('Jam catur', style: text.titleSmall),
                          const SizedBox(height: GoldTheme.gap8),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: GoldTheme.gap8,
                            crossAxisSpacing: GoldTheme.gap8,
                            childAspectRatio: 3.2,
                            children: [
                              for (final c in ClockOption.values)
                                choiceChip(
                                  c.label,
                                  selected: clock == c,
                                  onTap: clock == c
                                      ? null
                                      : () => setSheetState(() => clock = c),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        GoldTheme.gap16,
                        GoldTheme.gap8,
                        GoldTheme.gap16,
                        GoldTheme.gap16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(48, 56),
                            ),
                            onPressed: start,
                            child: const Text(
                              'Mulai main berdua',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Batal'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
              Row(
                children: [
                  Image.asset(
                    'assets/logo.png',
                    width: 40,
                    height: 40,
                    semanticLabel: 'Logo MyCatur',
                  ),
                  const SizedBox(width: GoldTheme.gap12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MyCatur', style: text.headlineSmall),
                        Text(
                          'Lawan komputer offline atau main berdua satu HP.',
                          style: text.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, size: 22),
                    color: GoldTheme.ink,
                    tooltip: 'Pengaturan',
                    onPressed: _openSettings,
                  ),
                ],
              ),
              const SizedBox(height: GoldTheme.gap16),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Semantics(
                    label: 'Pratinjau papan catur',
                    excludeSemantics: true,
                    child: DemoBoard(
                      animationEnabled: settings.animation,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: GoldTheme.gap20),
              OutlinedButton.icon(
                style: ButtonStyle(
                  backgroundColor:
                      const WidgetStatePropertyAll(GoldTheme.selectedFill),
                  foregroundColor:
                      const WidgetStatePropertyAll(GoldTheme.onSelected),
                  side: const WidgetStatePropertyAll(
                    BorderSide(color: GoldTheme.selectedFill),
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(GoldTheme.radiusButton),
                    ),
                  ),
                  minimumSize: const WidgetStatePropertyAll(Size(48, 56)),
                ),
                onPressed: _openAiSheet,
                icon: Text(
                  Piece(PieceColor.white, PieceType.king).glyphSolid,
                  style: const TextStyle(
                    fontSize: 22,
                    fontFamily: GoldTheme.pieceFont,
                    color: GoldTheme.onSelected,
                  ),
                ),
                label: const Text(
                  'Lawan Komputer',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: GoldTheme.gap8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: GoldTheme.quietBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(GoldTheme.radiusButton),
                  ),
                  minimumSize: const Size(48, 56),
                ),
                onPressed: _openDuoSheet,
                icon: Text(
                  Piece(PieceColor.white, PieceType.pawn).glyphSolid,
                  style: const TextStyle(
                    fontSize: 22,
                    fontFamily: GoldTheme.pieceFont,
                    color: GoldTheme.frame,
                  ),
                ),
                label: const Text(
                  'Main Berdua',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: GoldTheme.gap12),
              Text(
                'Offline • Tanpa iklan',
                textAlign: TextAlign.center,
                style: text.bodySmall,
              ),
              const SizedBox(height: GoldTheme.gap8),
            ],
          ),
        ),
      ),
    );
  }
}
