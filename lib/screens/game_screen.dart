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
import '../widgets/sheets.dart';

class GameScreen extends StatefulWidget {
  final bool vsAi;
  final PieceColor humanColor;
  final AiLevel level;
  final GameSettings settings;

  const GameScreen({
    super.key,
    required this.vsAi,
    this.humanColor = PieceColor.white,
    this.level = AiLevel.medium,
    this.settings = const GameSettings(),
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState state;
  final List<GameState> _past = [];
  final List<ChessMove> _moves = [];
  final List<PieceColor> _movers = [];
  final List<bool> _captures = [];
  // Bidak yang dimakan sesuai urutan, untuk baris tangkapan di kartu
  // pemain. Dihapus satu per satu saat undo, dikosongkan saat restart.
  final List<Piece> _captured = [];
  int? selR;
  int? selC;
  List<ChessMove> targets = [];
  ChessMove? lastMove;
  bool lastWasCapture = false;
  final List<String> history = [];
  bool flipped = false;
  bool thinking = false;
  String? resultText;
  ChessClock? clock;
  Timer? clockTimer;
  bool modalOpen = false;
  // Salinan pengaturan di state supaya perubahan tempo/animasi dari
  // sheet Pengaturan langsung berlaku tanpa restart. Jam tetap dari
  // nilai awal karena waktu berjalan tidak bisa diubah di tengah main.
  late GameSettings settings = widget.settings;

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
    _initClock();
    if (widget.vsAi && state.turn != widget.humanColor) {
      _aiMove();
    }
  }

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
                  style: const TextStyle(
                    fontSize: 28,
                    fontFamily: GoldTheme.pieceFont,
                  ),
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
    final Piece? victim = m.isEnPassant
        ? Piece(mover.opposite, PieceType.pawn)
        : state.at(m.toR, m.toC);
    setState(() {
      _past.add(GameState.clone(state));
      _moves.add(m);
      _movers.add(mover);
      _captures.add(wasCapture);
      if (victim != null) _captured.add(victim);
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
    _movers.removeLast();
    if (_captures.removeLast()) _captured.removeLast();
    if (widget.vsAi &&
        restored.turn != widget.humanColor &&
        _past.isNotEmpty) {
      restored = _past.removeLast();
      history.removeLast();
      _moves.removeLast();
      _movers.removeLast();
      if (_captures.removeLast()) _captured.removeLast();
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
      _movers.clear();
      _captures.clear();
      _captured.clear();
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

  /// SAN langkah terakhir warna [color], tanpa nomor. Null bila belum jalan.
  String? _lastSanFor(PieceColor color) {
    for (var i = _moves.length - 1; i >= 0; i--) {
      if (_movers[i] == color) {
        final h = history[i];
        final sp = h.indexOf(' ');
        return sp >= 0 ? h.substring(sp + 1) : h;
      }
    }
    return null;
  }

  /// Bidak lawan yang dimakan [color], termahal dulu.
  List<Piece> _takenBy(PieceColor color) {
    final list =
        _captured.where((p) => p.color == color.opposite).toList();
    list.sort(
        (a, b) => pieceMaterial(b.type).compareTo(pieceMaterial(a.type)));
    return list;
  }

  /// Selisih material [color] dalam pion, dari daftar tangkapan.
  int _materialFor(PieceColor color) {
    var score = 0;
    for (final p in _captured) {
      final v = pieceMaterial(p.type);
      if (p.color == color.opposite) {
        score += v;
      } else {
        score -= v;
      }
    }
    return score ~/ 100;
  }

  /// Glif bidak kecil dua warna seperti di papan (isi + ring), supaya
  /// hitam tetap terbaca di atas walnut dan putih tetap terbaca.
  TextStyle _takenStyle(Piece piece) {
    if (piece.color == PieceColor.white) {
      return const TextStyle(
        fontSize: 15,
        color: GoldTheme.onFrameText,
        shadows: [
          Shadow(color: GoldTheme.ink, offset: Offset(0, 1), blurRadius: 0),
          Shadow(color: GoldTheme.ink, offset: Offset(0, -1), blurRadius: 0),
          Shadow(color: GoldTheme.ink, offset: Offset(1, 0), blurRadius: 0),
          Shadow(color: GoldTheme.ink, offset: Offset(-1, 0), blurRadius: 0),
        ],
      );
    }
    return const TextStyle(
      fontSize: 15,
      color: Color(0xFF14100B),
      shadows: [
        Shadow(
            color: GoldTheme.onFrameText,
            offset: Offset(0, 1),
            blurRadius: 0),
        Shadow(
            color: GoldTheme.onFrameText,
            offset: Offset(0, -1),
            blurRadius: 0),
        Shadow(
            color: GoldTheme.onFrameText,
            offset: Offset(1, 0),
            blurRadius: 0),
        Shadow(
            color: GoldTheme.onFrameText,
            offset: Offset(-1, 0),
            blurRadius: 0),
      ],
    );
  }

  /// Strip pemain satu baris: nama + SAN terakhir, bidak tertangkapan,
  /// dan jam. Pemain aktif: border emas, nama tebal, transisi 250ms.
  Widget _playerStrip(PieceColor color) {
    final active = resultText == null && state.turn == color;
    final isAi = widget.vsAi && color == aiColor;
    final name = widget.vsAi
        ? (color == widget.humanColor ? 'Kamu' : 'Komputer')
        : (color == PieceColor.white ? 'Putih' : 'Hitam');
    final sub = (isAi && thinking && resultText == null)
        ? 'berpikir…'
        : (_lastSanFor(color) ??
            (widget.vsAi
                ? (color == PieceColor.white ? 'Putih' : 'Hitam')
                : 'Menunggu'));
    final taken = _takenBy(color);
    final shown = taken.take(7).toList();
    final rest = taken.length - shown.length;
    final pawns = _materialFor(color);
    final c = clock;
    final ms = c == null
        ? null
        : (color == PieceColor.white ? c.whiteMs : c.blackMs);
    final urgent =
        ms != null && ms < 10000 && ms > 0 && resultText == null;
    const cardName = TextStyle(
      color: GoldTheme.onFrameText,
      fontSize: 15,
    );
    const cardSub = TextStyle(
      color: GoldTheme.onFrameText,
      fontSize: 11,
    );
    const cardClock = TextStyle(
      color: GoldTheme.onFrameText,
      fontWeight: FontWeight.w700,
      fontSize: 18,
    );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(
        horizontal: GoldTheme.gap12,
        vertical: GoldTheme.gap4,
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
                  ? GoldTheme.onFrameText
                  : Colors.black,
              border: Border.all(color: GoldTheme.onFrameText),
            ),
          ),
          const SizedBox(width: GoldTheme.gap8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: cardName.copyWith(
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                Text(sub, style: cardSub),
              ],
            ),
          ),
          if (shown.isNotEmpty || pawns > 0) ...[
            Flexible(
              child: Wrap(
                alignment: WrapAlignment.end,
                children: [
                  for (final p in shown)
                    Text(p.glyphSolid, style: _takenStyle(p)),
                  if (rest > 0) Text('+$rest', style: cardSub),
                  if (pawns > 0) Text(' +$pawns', style: cardSub),
                ],
              ),
            ),
            const SizedBox(width: GoldTheme.gap8),
          ],
          if (ms != null)
            urgent
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: GoldTheme.gap8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: GoldTheme.checkMark,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ChessClock.format(ms),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  )
                : Text(ChessClock.format(ms), style: cardClock),
        ],
      ),
    );
  }

  /// Empat aksi permainan. Dipakai sebagai baris di portrait dan
  /// sebagai Wrap di panel landscape yang sempit.
  List<Widget> _actionButtons() {
    return [
      IconButton(
        icon: const Icon(Icons.arrow_back, size: 20),
        color: GoldTheme.ink,
        tooltip: 'Kembali',
        onPressed: () => Navigator.of(context).pop(),
      ),
      IconButton(
        icon: const Icon(Icons.undo, size: 20),
        color: GoldTheme.ink,
        tooltip: 'Urungkan',
        onPressed: canUndo ? _undo : null,
      ),
      IconButton(
        icon: const Icon(Icons.history, size: 20),
        color: GoldTheme.ink,
        tooltip: 'Riwayat',
        onPressed: _openHistory,
      ),
      PopupMenuButton<String>(
        iconSize: 20,
        color: GoldTheme.frame,
        iconColor: GoldTheme.ink,
        tooltip: 'Opsi lain',
        onSelected: (value) {
          if (value == 'baru') {
            _restart();
          } else if (value == 'putar') {
            setState(() => flipped = !flipped);
          } else if (value == 'menyerah') {
            _resign();
          } else if (value == 'pengaturan') {
            openSettingsSheet(
              context,
              current: settings,
              onApply: (next) => setState(() => settings = next),
            );
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
            value: 'pengaturan',
            child: Text('Pengaturan'),
          ),
          PopupMenuItem(
            value: 'menyerah',
            child: Text('Menyerah'),
          ),
        ],
      ),
    ];
  }

  /// Baris status + aksi di bawah papan. Status dibacakan ulang oleh
  /// pembaca layar setiap berubah (liveRegion); aksi cukup 4 tombol
  /// dan satu menu supaya muat di layar sempit.
  Widget _bottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GoldTheme.gap12,
        GoldTheme.gap4,
        GoldTheme.gap4,
        GoldTheme.gap8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: _statusLine(),
            ),
          ),
          ..._actionButtons(),
        ],
      ),
    );
  }

  Widget _statusLine() {
    final text = Theme.of(context).textTheme;
    if (resultText != null) {
      return Text(resultText!, style: text.titleSmall);
    }
    if (thinking) {
      return Text('Komputer sedang berpikir', style: text.titleSmall);
    }
    final turnGlyph =
        Piece(state.turn, PieceType.king).glyphSolid;
    final check = state.isInCheck(state.turn);
    final label = state.turn == PieceColor.white
        ? 'Giliran Putih'
        : 'Giliran Hitam';
    return Row(
      children: [
        Text(
          turnGlyph,
          style: TextStyle(
            fontSize: 18,
            color: state.turn == PieceColor.white
                ? GoldTheme.frame
                : GoldTheme.ink,
          ),
        ),
        const SizedBox(width: GoldTheme.gap8),
        Expanded(
          child: Text(
            check ? '$label, skak!' : label,
            style: text.titleMedium?.copyWith(
              color: check ? GoldTheme.checkMark : GoldTheme.ink,
            ),
          ),
        ),
      ],
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

  Widget _portrait() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            GoldTheme.gap8,
            GoldTheme.gap8,
            GoldTheme.gap8,
            GoldTheme.gap4,
          ),
          child: _playerStrip(_topColor),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 2,
                vertical: GoldTheme.gap4,
              ),
              child: _board(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            GoldTheme.gap8,
            GoldTheme.gap4,
            GoldTheme.gap8,
            GoldTheme.gap4,
          ),
          child: _playerStrip(_topColor.opposite),
        ),
        _bottomBar(),
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
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 4,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: GoldTheme.gap4,
                    ),
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
                      _playerStrip(_topColor),
                      const SizedBox(height: GoldTheme.gap8),
                      _playerStrip(_topColor.opposite),
                      const SizedBox(height: GoldTheme.gap8),
                      Text('Langkah terakhir', style: text.titleSmall),
                      const SizedBox(height: GoldTheme.gap4),
                      if (recent.isEmpty)
                        Text('Belum ada langkah.', style: text.bodyMedium),
                      for (final h in recent)
                        Text(h, style: text.bodyMedium),
                      const SizedBox(height: GoldTheme.gap8),
                      Semantics(
                        liveRegion: true,
                        child: _statusLine(),
                      ),
                      const SizedBox(height: GoldTheme.gap4),
                      Wrap(children: _actionButtons()),
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
