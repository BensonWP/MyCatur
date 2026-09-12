import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../chess/ai.dart';
import '../chess/app_prefs.dart';
import '../chess/chess_clock.dart';
import '../chess/game_settings.dart';
import '../chess/game_state.dart';
import '../chess/move.dart';
import '../chess/piece.dart';
import '../chess/stats_store.dart';
import '../theme/gold_theme.dart';
import '../widgets/animated_board_widget.dart';

class GameScreen extends StatefulWidget {
  final bool vsAi;
  final PieceColor humanColor;
  final AiLevel level;

  const GameScreen({
    super.key,
    required this.vsAi,
    this.humanColor = PieceColor.white,
    this.level = AiLevel.medium,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState state;
  final List<GameState> _past = [];
  final List<ChessMove> _moves = [];
  final List<bool> _captures = [];
  int? selR;
  int? selC;
  List<ChessMove> targets = [];
  ChessMove? lastMove;
  bool lastWasCapture = false;
  final List<String> history = [];
  bool flipped = false;
  bool thinking = false;
  String? resultText;
  GameSettings settings = GameSettings();
  ChessClock? clock;
  Timer? clockTimer;
  bool modalOpen = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    state = GameState();
    flipped = widget.vsAi && widget.humanColor == PieceColor.black;
    clockTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final c = clock;
      if (c == null || resultText != null || modalOpen) return;
      setState(() {
        c.tick(100);
        if (c.flagged != null) _onFlag(c.flagged!);
      });
    });
    _loadSettings();
    if (widget.vsAi && state.turn != widget.humanColor) {
      _aiMove();
    }
  }

  Future<void> _loadSettings() async {
    final s = await AppPrefs.loadGame();
    if (!mounted) return;
    setState(() {
      settings = s;
      if (history.isEmpty && resultText == null) _initClock();
    });
  }

  void _saveSettings() => unawaited(AppPrefs.saveGame(settings));

  void _initClock() {
    if (settings.clock == ClockOption.tanpa) {
      clock = null;
    } else {
      clock = ChessClock(
        initialMs: settings.clock.initialMs,
        incrementMs: settings.clock.incrementMs,
      );
    }
  }

  @override
  void dispose() {
    clockTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  PieceColor get aiColor => widget.humanColor.opposite;

  /// Warna pemain yang duduk di sisi atas layar (mengikuti putaran papan).
  PieceColor get _topColor =>
      flipped ? PieceColor.white : PieceColor.black;

  bool get canUndo => _past.isNotEmpty && !thinking && resultText == null;

  void _onTap(int r, int c) {
    if (thinking || resultText != null) return;
    if (widget.vsAi && state.turn != widget.humanColor) return;
    final piece = state.at(r, c);
    if (selR != null && targets.any((m) => m.toR == r && m.toC == c)) {
      final options =
          targets.where((m) => m.toR == r && m.toC == c).toList();
      if (options.length > 1) {
        _askPromotion(options);
      } else {
        _doMove(options.first);
      }
      return;
    }
    if (piece != null && piece.color == state.turn) {
      setState(() {
        selR = r;
        selC = c;
        targets = state.legalMoves(r, c);
      });
    } else {
      setState(() {
        selR = selC = null;
        targets = [];
      });
    }
  }

  Future<void> _askPromotion(List<ChessMove> options) async {
    final choice = await showDialog<PieceType>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih promosi pion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final t in [
              PieceType.queen,
              PieceType.rook,
              PieceType.bishop,
              PieceType.knight
            ])
              ListTile(
                leading: Text(
                  _promoGlyph(t, state.turn),
                  style: const TextStyle(fontSize: 28),
                ),
                title: Text(_promoName(t)),
                onTap: () => Navigator.of(context).pop(t),
              ),
          ],
        ),
      ),
    );
    if (choice != null && mounted) {
      final m = options.firstWhere((e) => e.promotion == choice);
      _doMove(m);
    }
  }

  static String _promoGlyph(PieceType t, PieceColor color) {
    return Piece(color, t).glyphSolid;
  }

  static String _promoName(PieceType t) {
    switch (t) {
      case PieceType.queen:
        return 'Menteri';
      case PieceType.rook:
        return 'Benteng';
      case PieceType.bishop:
        return 'Gajah';
      case PieceType.knight:
        return 'Kuda';
      case PieceType.king:
      case PieceType.pawn:
        return '';
    }
  }

  void _doMove(ChessMove m) {
    if (resultText != null) return;
    final movingWhite = state.turn == PieceColor.white;
    final mover = state.turn;
    final number = state.fullmove;
    final sanText = state.san(m);
    final wasCapture =
        state.at(m.toR, m.toC) != null || m.isEnPassant;
    setState(() {
      _past.add(GameState.clone(state));
      _moves.add(m);
      _captures.add(wasCapture);
      state.apply(m);
      lastMove = m;
      lastWasCapture = wasCapture;
      history.add(movingWhite ? '$number. $sanText' : '$number... $sanText');
      selR = selC = null;
      targets = [];
      final c = clock;
      if (c != null) {
        if (!c.started) c.start(mover);
        c.onMove(mover);
      }
    });
    _checkEnd();
    if (resultText == null && widget.vsAi && state.turn != widget.humanColor) {
      _aiMove();
    }
  }

  void _undo() {
    if (!canUndo) return;
    var restored = _past.removeLast();
    history.removeLast();
    _moves.removeLast();
    _captures.removeLast();
    if (widget.vsAi &&
        restored.turn != widget.humanColor &&
        _past.isNotEmpty) {
      restored = _past.removeLast();
      history.removeLast();
      _moves.removeLast();
      _captures.removeLast();
    }
    setState(() {
      state = restored;
      lastMove = _moves.isEmpty ? null : _moves.last;
      lastWasCapture = _captures.isEmpty ? false : _captures.last;
      selR = selC = null;
      targets = [];
    });
    if (widget.vsAi && state.turn != widget.humanColor) _aiMove();
  }

  Future<void> _resign() async {
    if (resultText != null || thinking) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Menyerah?'),
        content: const Text('Kekalahan dicatat ke statistik.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Menyerah'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final winner = widget.vsAi ? aiColor : state.turn.opposite;
    _finishGame(
      text: winner == PieceColor.white
          ? 'Putih menang karena lawan menyerah.'
          : 'Hitam menang karena lawan menyerah.',
      winner: winner,
    );
  }

  Future<void> _aiMove() async {
    setState(() => thinking = true);
    if (settings.aiDelay > Duration.zero) {
      await Future.delayed(settings.aiDelay);
      if (!mounted || resultText != null) {
        if (mounted) setState(() => thinking = false);
        return;
      }
    }
    final snapshot = GameState.clone(state);
    final depth = widget.level.depth;
    final seed =
        widget.level == AiLevel.easy ? DateTime.now().millisecond : 0;
    final move =
        await compute(computeAiMove, AiRequest(snapshot, depth, seed));
    if (!mounted) return;
    setState(() => thinking = false);
    if (move == null) {
      _checkEnd();
      return;
    }
    _doMove(move);
  }

  void _recordResult({required PieceColor? winner}) {
    if (widget.vsAi) {
      final humanScore = winner == null
          ? 0
          : (winner == widget.humanColor ? 1 : -1);
      unawaited(StatsStore.instance.recordAi(
        level: widget.level,
        humanScore: humanScore,
      ));
    } else {
      unawaited(StatsStore.instance.recordTwoPlayer(winner: winner));
    }
  }

  void _finishGame({required String text, required PieceColor? winner}) {
    setState(() => resultText = text);
    _recordResult(winner: winner);
    _showEndDialog(text);
  }

  void _onFlag(PieceColor flagged) {
    _finishGame(
      text: flagged == PieceColor.white
          ? 'Putih kehabisan waktu. Hitam menang.'
          : 'Hitam kehabisan waktu. Putih menang.',
      winner: flagged.opposite,
    );
  }

  void _checkEnd() {
    final res = state.result();
    switch (res) {
      case GameResult.whiteWins:
        _finishGame(text: 'Putih menang dengan skakmat.', winner: PieceColor.white);
      case GameResult.blackWins:
        _finishGame(text: 'Hitam menang dengan skakmat.', winner: PieceColor.black);
      case GameResult.drawStalemate:
        _finishGame(text: 'Seri karena stalemate.', winner: null);
      case GameResult.drawFifty:
        _finishGame(
            text: 'Seri karena 50 langkah tanpa pion atau tangkapan.',
            winner: null);
      case GameResult.drawRepetition:
        _finishGame(
            text: 'Seri karena posisi berulang tiga kali.', winner: null);
      case GameResult.ongoing:
        break;
    }
  }

  void _showEndDialog(String text) {
    modalOpen = true;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permainan selesai'),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Kembali'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _restart();
            },
            child: const Text('Main lagi'),
          ),
        ],
      ),
    ).then((_) => modalOpen = false);
  }

  void _restart() {
    setState(() {
      state = GameState();
      _past.clear();
      _moves.clear();
      _captures.clear();
      selR = selC = null;
      targets = [];
      lastMove = null;
      lastWasCapture = false;
      history.clear();
      resultText = null;
      thinking = false;
      _initClock();
    });
    if (widget.vsAi && state.turn != widget.humanColor) _aiMove();
  }

  void _openHistory() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        final text = Theme.of(context).textTheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(GoldTheme.gap16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Riwayat langkah', style: text.titleLarge),
                const SizedBox(height: GoldTheme.gap4),
                Text(
                  history.isEmpty
                      ? 'Belum ada langkah'
                      : '${history.length} langkah',
                  style: text.titleSmall,
                ),
                const SizedBox(height: GoldTheme.gap12),
                Flexible(
                  child: history.isEmpty
                      ? Text(
                          'Belum ada langkah. Mulai dengan memindahkan bidak.',
                          style: text.bodyMedium,
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: history.length,
                          itemBuilder: (context, i) => Text(
                            history[i],
                            style: text.bodyMedium,
                          ),
                        ),
                ),
                const SizedBox(height: GoldTheme.gap8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Tutup'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openSettings() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        final text = Theme.of(context).textTheme;
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setSheet) => SingleChildScrollView(
              padding: const EdgeInsets.all(GoldTheme.gap16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Pengaturan', style: text.titleLarge),
                  const SizedBox(height: GoldTheme.gap12),
                  Text('Tempo main.', style: text.titleSmall),
                  const SizedBox(height: GoldTheme.gap8),
                  Row(
                    children: Tempo.values.map((t) {
                      return Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets.only(right: GoldTheme.gap8),
                          child: OutlinedButton(
                            onPressed: settings.tempo == t
                                ? null
                                : () {
                                    setSheet(() {});
                                    setState(() => settings.tempo = t);
                                    _saveSettings();
                                    Navigator.of(context).pop();
                                    _openSettings();
                                  },
                            child: Text(t.label),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: GoldTheme.gap12),
                  Text(
                    'Jam catur. Mengganti jam memulai ulang permainan.',
                    style: text.titleSmall,
                  ),
                  const SizedBox(height: GoldTheme.gap8),
                  for (final c in ClockOption.values)
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: GoldTheme.gap8),
                      child: OutlinedButton(
                        onPressed: settings.clock == c
                            ? null
                            : () {
                                setState(() => settings.clock = c);
                                _saveSettings();
                                Navigator.of(context).pop();
                                _restart();
                              },
                        child: Text(c.label),
                      ),
                    ),
                  const SizedBox(height: GoldTheme.gap4),
                  Text('Animasi.', style: text.titleSmall),
                  const SizedBox(height: GoldTheme.gap8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: !settings.animation
                              ? null
                              : () {
                                  setState(
                                      () => settings.animation = true);
                                  _saveSettings();
                                  Navigator.of(context).pop();
                                },
                          child: const Text('Aktif'),
                        ),
                      ),
                      const SizedBox(width: GoldTheme.gap8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: settings.animation
                              ? null
                              : () {
                                  setState(
                                      () => settings.animation = false);
                                  _saveSettings();
                                  Navigator.of(context).pop();
                                },
                          child: const Text('Mati'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: GoldTheme.gap8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String get _status {
    if (resultText != null) return resultText!;
    if (thinking) return 'Komputer sedang berpikir';
    return state.turn == PieceColor.white ? 'Giliran Putih' : 'Giliran Hitam';
  }

  Widget _playerCard(PieceColor color) {
    final text = Theme.of(context).textTheme;
    final c = clock;
    final active = resultText == null && state.turn == color;
    final name = widget.vsAi
        ? (color == widget.humanColor ? 'Kamu' : 'Komputer')
        : (color == PieceColor.white ? 'Putih' : 'Hitam');
    final side =
        color == PieceColor.white ? 'Putih' : 'Hitam';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GoldTheme.gap12,
        vertical: GoldTheme.gap8,
      ),
      decoration: BoxDecoration(
        color: GoldTheme.frame,
        borderRadius: BorderRadius.circular(GoldTheme.radiusCard),
        border: Border.all(
          color: active ? GoldTheme.accent : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color == PieceColor.white
                  ? GoldTheme.creamText
                  : Colors.black,
              border: Border.all(color: GoldTheme.creamText),
            ),
          ),
          const SizedBox(width: GoldTheme.gap8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name, style: text.titleMedium),
              if (widget.vsAi) Text(side, style: text.bodySmall),
            ],
          ),
          const Spacer(),
          if (c != null)
            Text(
              ChessClock.format(
                color == PieceColor.white ? c.whiteMs : c.blackMs,
              ),
              style: text.titleLarge,
            ),
        ],
      ),
    );
  }

  Widget _board() {
    return AnimatedBoardWidget(
      state: state,
      selectedR: selR,
      selectedC: selC,
      targets: targets,
      lastMove: lastMove,
      lastWasCapture: lastWasCapture,
      flipped: flipped,
      calm: settings.calm,
      moveDuration: settings.moveDuration,
      animationEnabled: settings.animation,
      onTap: _onTap,
    );
  }

  Widget _topBar() {
    final text = Theme.of(context).textTheme;
    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            color: GoldTheme.creamText,
            tooltip: 'Kembali',
            visualDensity: VisualDensity.compact,
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              widget.vsAi ? 'Lawan komputer' : 'Main berdua',
              style: text.titleSmall,
            ),
          ),
          if (thinking)
            const Padding(
              padding: EdgeInsets.only(right: GoldTheme.gap4),
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.undo, size: 20),
            color: GoldTheme.creamText,
            tooltip: 'Urungkan',
            visualDensity: VisualDensity.compact,
            onPressed: canUndo ? _undo : null,
          ),
          IconButton(
            icon: const Icon(Icons.history, size: 20),
            color: GoldTheme.creamText,
            tooltip: 'Riwayat',
            visualDensity: VisualDensity.compact,
            onPressed: _openHistory,
          ),
          IconButton(
            icon: const Icon(Icons.settings, size: 20),
            color: GoldTheme.creamText,
            tooltip: 'Pengaturan',
            visualDensity: VisualDensity.compact,
            onPressed: _openSettings,
          ),
          PopupMenuButton<String>(
            iconSize: 20,
            tooltip: 'Opsi lain',
            onSelected: (value) {
              if (value == 'baru') {
                _restart();
              } else if (value == 'putar') {
                setState(() => flipped = !flipped);
              } else if (value == 'menyerah') {
                _resign();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'baru',
                child: Text('Main baru'),
              ),
              PopupMenuItem(
                value: 'putar',
                child: Text('Putar papan'),
              ),
              PopupMenuItem(
                value: 'menyerah',
                child: Text('Menyerah'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _portrait() {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        _topBar(),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            GoldTheme.gap8,
            GoldTheme.gap8,
            GoldTheme.gap8,
            GoldTheme.gap4,
          ),
          child: _playerCard(_topColor),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(GoldTheme.gap4),
              child: _board(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            GoldTheme.gap8,
            GoldTheme.gap4,
            GoldTheme.gap8,
            GoldTheme.gap8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _playerCard(_topColor.opposite),
              const SizedBox(height: GoldTheme.gap4),
              Text(_status, style: text.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _landscape() {
    final text = Theme.of(context).textTheme;
    final recent = history.length <= 3
        ? history
        : history.sublist(history.length - 3);
    return Column(
      children: [
        _topBar(),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(GoldTheme.gap4),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _board(),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    0,
                    GoldTheme.gap8,
                    GoldTheme.gap8,
                    GoldTheme.gap8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _playerCard(_topColor),
                      const SizedBox(height: GoldTheme.gap8),
                      _playerCard(_topColor.opposite),
                      const SizedBox(height: GoldTheme.gap8),
                      Text(_status, style: text.bodySmall),
                      const SizedBox(height: GoldTheme.gap8),
                      Text('Langkah terakhir.', style: text.titleSmall),
                      const SizedBox(height: GoldTheme.gap4),
                      if (recent.isEmpty)
                        Text('Belum ada langkah.', style: text.bodyMedium),
                      for (final h in recent)
                        Text(h, style: text.bodyMedium),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: settings.background,
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            if (orientation == Orientation.landscape) {
              return _landscape();
            }
            return _portrait();
          },
        ),
      ),
    );
  }
}
