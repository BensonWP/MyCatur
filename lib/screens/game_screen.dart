import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../chess/ai.dart';
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
    if (widget.vsAi && state.turn != widget.humanColor) {
      _aiMove();
    }
  }

  @override
  void dispose() {
    clockTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  PieceColor get aiColor => widget.humanColor.opposite;

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
    modalOpen = true;
    final choice = await showDialog<PieceType>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GoldTheme.frame,
        title: const Text(
          'Pilih promosi pion',
          style: TextStyle(color: GoldTheme.creamText),
        ),
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
                title: Text(
                  _promoName(t),
                  style: const TextStyle(color: GoldTheme.creamText),
                ),
                onTap: () => Navigator.of(context).pop(t),
              ),
          ],
        ),
      ),
    );
    modalOpen = false;
    if (choice != null) {
      final m = options.firstWhere((e) => e.promotion == choice);
      _doMove(m);
    }
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
    final movingWhite = state.turn == PieceColor.white;
    final mover = state.turn;
    final number = state.fullmove;
    final wasCapture =
        state.at(m.toR, m.toC) != null || m.isEnPassant;
    setState(() {
      state.apply(m);
      lastMove = m;
      lastWasCapture = wasCapture;
      history.add(m.label(number, movingWhite));
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
    final store = StatsStore();
    if (widget.vsAi) {
      final humanScore = winner == null
          ? 0
          : (winner == widget.humanColor ? 1 : -1);
      store.load().then((_) => store.recordAi(
            level: widget.level,
            humanScore: humanScore,
          ));
    } else {
      store.load().then((_) => store.recordTwoPlayer(winner: winner));
    }
  }

  void _onFlag(PieceColor flagged) {
    final winner = flagged.opposite;
    final text = flagged == PieceColor.white
        ? 'Putih kehabisan waktu. Hitam menang.'
        : 'Hitam kehabisan waktu. Putih menang.';
    setState(() => resultText = text);
    _recordResult(winner: winner);
    _showEndDialog(text);
  }

  void _checkEnd() {
    final res = state.result();
    String? text;
    switch (res) {
      case GameResult.whiteWins:
        text = 'Putih menang dengan skakmat.';
        break;
      case GameResult.blackWins:
        text = 'Hitam menang dengan skakmat.';
        break;
      case GameResult.drawStalemate:
        text = 'Seri karena stalemate.';
        break;
      case GameResult.drawFifty:
        text = 'Seri karena 50 langkah tanpa pion atau tangkapan.';
        break;
      case GameResult.drawRepetition:
        text = 'Seri karena posisi berulang tiga kali.';
        break;
      case GameResult.ongoing:
        text = null;
    }
    if (text != null) {
      setState(() => resultText = text);
      if (res == GameResult.whiteWins) {
        _recordResult(winner: PieceColor.white);
      } else if (res == GameResult.blackWins) {
        _recordResult(winner: PieceColor.black);
      } else {
        _recordResult(winner: null);
      }
      _showEndDialog(text);
    }
  }

  void _showEndDialog(String text) {
    modalOpen = true;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GoldTheme.frame,
        title: const Text(
          'Permainan selesai',
          style: TextStyle(color: GoldTheme.creamText),
        ),
        content: Text(
          text,
          style: const TextStyle(color: GoldTheme.creamText),
        ),
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
      selR = selC = null;
      targets = [];
      lastMove = null;
      lastWasCapture = false;
      history.clear();
      resultText = null;
      thinking = false;
      if (settings.clock != ClockOption.tanpa) {
        clock = ChessClock(
          initialMs: settings.clock.initialMs,
          incrementMs: settings.clock.incrementMs,
        );
      } else {
        clock = null;
      }
    });
    if (widget.vsAi && state.turn != widget.humanColor) _aiMove();
  }

  void _openHistory() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: GoldTheme.frame,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Riwayat langkah',
                style: TextStyle(
                  color: GoldTheme.creamText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                history.isEmpty
                    ? 'Belum ada langkah'
                    : '${history.length} langkah',
                style: const TextStyle(
                  color: GoldTheme.creamText,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: history.isEmpty
                    ? const Text(
                        'Belum ada langkah. Mulai dengan memindahkan bidak.',
                        style: TextStyle(
                          color: GoldTheme.creamText,
                          fontSize: 13,
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: history.length,
                        itemBuilder: (context, i) => Text(
                          history[i],
                          style: const TextStyle(
                            color: GoldTheme.creamText,
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tutup'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSettings() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: GoldTheme.frame,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => SafeArea(
        child: StatefulBuilder(
          builder: (context, setSheet) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Pengaturan',
                  style: TextStyle(
                    color: GoldTheme.creamText,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tempo main.',
                  style: TextStyle(
                      color: GoldTheme.creamText, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: Tempo.values.map((t) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: OutlinedButton(
                          onPressed: settings.tempo == t
                              ? null
                              : () {
                                  setSheet(() {});
                                  setState(() => settings.tempo = t);
                                  Navigator.of(context).pop();
                                  _openSettings();
                                },
                          child: Text(t.label),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Jam catur. Mengganti jam memulai ulang permainan.',
                  style: TextStyle(
                      color: GoldTheme.creamText, fontSize: 13),
                ),
                const SizedBox(height: 8),
                for (final c in ClockOption.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton(
                      onPressed: settings.clock == c
                          ? null
                          : () {
                              setState(() => settings.clock = c);
                              Navigator.of(context).pop();
                              _restart();
                            },
                      child: Text(c.label),
                    ),
                  ),
                const SizedBox(height: 4),
                const Text(
                  'Animasi.',
                  style: TextStyle(
                      color: GoldTheme.creamText, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: !settings.animation
                            ? null
                            : () {
                                setState(
                                    () => settings.animation = true);
                                Navigator.of(context).pop();
                              },
                        child: const Text('Aktif'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: settings.animation
                            ? null
                            : () {
                                setState(
                                    () => settings.animation = false);
                                Navigator.of(context).pop();
                              },
                        child: const Text('Mati'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Tutup'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _status {
    final turnText = state.turn == PieceColor.white
        ? 'Giliran Putih'
        : 'Giliran Hitam';
    return resultText ??
        (thinking ? 'Komputer sedang berpikir' : turnText);
  }

  Widget _statusLine() {
    final c = clock;
    final buffer = StringBuffer(_status);
    if (c != null) {
      buffer.write(
          '  Putih ${ChessClock.format(c.whiteMs)} Hitam ${ChessClock.format(c.blackMs)}');
    }
    return Text(
      buffer.toString(),
      style: const TextStyle(
        color: GoldTheme.creamText,
        fontSize: 12,
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
              style: const TextStyle(
                color: GoldTheme.creamText,
                fontSize: 13,
              ),
            ),
          ),
          if (thinking)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
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
            color: GoldTheme.frame,
            tooltip: 'Opsi lain',
            onSelected: (value) {
              if (value == 'baru') {
                _restart();
              } else if (value == 'putar') {
                setState(() => flipped = !flipped);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'baru',
                child: Text('Langkah baru'),
              ),
              PopupMenuItem(
                value: 'putar',
                child: Text('Putar papan'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _portrait() {
    return Column(
      children: [
        _topBar(),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _statusLine(),
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: _board(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _landscape() {
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
                    padding: const EdgeInsets.all(4),
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
                  padding: const EdgeInsets.fromLTRB(0, 6, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _statusLine(),
                      const SizedBox(height: 8),
                      const Text(
                        'Langkah terakhir.',
                        style: TextStyle(
                          color: GoldTheme.creamText,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (recent.isEmpty)
                        const Text(
                          'Belum ada langkah.',
                          style: TextStyle(
                            color: GoldTheme.creamText,
                            fontSize: 13,
                          ),
                        ),
                      for (final h in recent)
                        Text(
                          h,
                          style: const TextStyle(
                            color: GoldTheme.creamText,
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
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
