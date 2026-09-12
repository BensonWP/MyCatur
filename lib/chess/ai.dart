import 'dart:math';
import 'game_state.dart';
import 'move.dart';
import 'piece.dart';

enum AiLevel { easy, medium, hard }

extension AiLevelExt on AiLevel {
  int get depth {
    switch (this) {
      case AiLevel.easy:
        return 1;
      case AiLevel.medium:
        return 2;
      case AiLevel.hard:
        return 3;
    }
  }

  String get label {
    switch (this) {
      case AiLevel.easy:
        return 'Mudah';
      case AiLevel.medium:
        return 'Sedang';
      case AiLevel.hard:
        return 'Sulit';
    }
  }
}

const _values = {
  PieceType.pawn: 100,
  PieceType.knight: 320,
  PieceType.bishop: 330,
  PieceType.rook: 500,
  PieceType.queen: 900,
  PieceType.king: 0,
};

/// Nilai material satu bidak untuk papan skor di kartu pemain.
int pieceMaterial(PieceType t) => _values[t] ?? 0;

int evaluateBoard(GameState s) {
  var score = 0;
  for (var r = 0; r < 8; r++) {
    for (var c = 0; c < 8; c++) {
      final p = s.board[r][c];
      if (p == null) continue;
      var v = _values[p.type]!;
      v += _positional(p, r, c);
      score += p.color == PieceColor.white ? v : -v;
    }
  }
  return score;
}

int _positional(Piece p, int r, int c) {
  final center = (3.5 - (r - 3.5).abs()) + (3.5 - (c - 3.5).abs());
  if (p.type == PieceType.knight || p.type == PieceType.pawn) {
    return (center * 4).round();
  }
  return 0;
}

class AiRequest {
  final GameState state;
  final int depth;
  final int seed;
  AiRequest(this.state, this.depth, this.seed);
}

ChessMove? pickMoveSync(GameState state, int depth, {int seed = 0}) {
  final moves = state.allLegalMoves(state.turn);
  if (moves.isEmpty) return null;
  _orderMoves(state, moves);
  final maximizing = state.turn == PieceColor.white;
  var best = moves.first;
  var bestScore = maximizing ? -1000000 : 1000000;
  final rnd = Random(seed);
  for (final m in moves) {
    final copy = GameState.clone(state);
    copy.apply(m);
    final score = _search(copy, depth - 1, -1000000, 1000000, !maximizing);
    final jitter = seed == 0 ? 0 : rnd.nextInt(15) - 7;
    final s = score + jitter;
    if (maximizing ? s > bestScore : s < bestScore) {
      bestScore = s;
      best = m;
    }
  }
  return best;
}

int _search(GameState s, int depth, int alpha, int beta, bool maximizing) {
  final res = s.result();
  if (res == GameResult.whiteWins) return 100000;
  if (res == GameResult.blackWins) return -100000;
  if (res != GameResult.ongoing) return 0;
  if (depth <= 0) return _quiesce(s, alpha, beta, maximizing, 3);
  final moves = s.allLegalMoves(s.turn);
  if (moves.isEmpty) return evaluateBoard(s);
  _orderMoves(s, moves);
  if (maximizing) {
    var value = -1000000;
    for (final m in moves) {
      final copy = GameState.clone(s);
      copy.apply(m);
      value = max(value, _search(copy, depth - 1, alpha, beta, false));
      alpha = max(alpha, value);
      if (alpha >= beta) break;
    }
    return value;
  } else {
    var value = 1000000;
    for (final m in moves) {
      final copy = GameState.clone(s);
      copy.apply(m);
      value = min(value, _search(copy, depth - 1, alpha, beta, true));
      beta = min(beta, value);
      if (beta <= alpha) break;
    }
    return value;
  }
}

void _orderMoves(GameState s, List<ChessMove> moves) {
  moves.sort((a, b) => _moveScore(s, b).compareTo(_moveScore(s, a)));
}

/// MVV-LVA: korban termahal dulu, penyerang termurah dulu.
/// Promosi dan rokade ikut dihitung agar tidak tenggelam.
int _moveScore(GameState s, ChessMove m) {
  final attacker = s.at(m.fromR, m.fromC);
  final victim = m.isEnPassant
      ? s.at(m.fromR, m.toC)
      : s.at(m.toR, m.toC);
  var score = 0;
  if (victim != null && attacker != null) {
    score = 10000 +
        _values[victim.type]! -
        (_values[attacker.type]! ~/ 16);
  }
  if (m.promotion != null) score += _values[m.promotion!]!;
  if (m.isCastleKingside || m.isCastleQueenside) score += 50;
  return score;
}

/// Quiescence: di daun pohon hanya kejar tangkapan, supaya AI tidak
/// menilai posisi tepat sebelum bidaknya dimakan (horizon effect).
/// Kalau sedang skak, semua langkah penghindar dicari penuh.
int _quiesce(GameState s, int alpha, int beta, bool maximizing, int qd) {
  if (s.isInCheck(s.turn)) {
    final evasions = s.allLegalMoves(s.turn);
    if (evasions.isEmpty) return maximizing ? -100000 : 100000;
    if (qd <= 0) return evaluateBoard(s);
    _orderMoves(s, evasions);
    if (maximizing) {
      var value = -1000000;
      for (final m in evasions) {
        final copy = GameState.clone(s);
        copy.apply(m);
        value = max(value, _quiesce(copy, alpha, beta, false, qd - 1));
        alpha = max(alpha, value);
        if (alpha >= beta) break;
      }
      return value;
    } else {
      var value = 1000000;
      for (final m in evasions) {
        final copy = GameState.clone(s);
        copy.apply(m);
        value = min(value, _quiesce(copy, alpha, beta, true, qd - 1));
        beta = min(beta, value);
        if (beta <= alpha) break;
      }
      return value;
    }
  }
  final stand = evaluateBoard(s);
  if (maximizing) {
    if (stand >= beta) return beta;
    if (stand > alpha) alpha = stand;
  } else {
    if (stand <= alpha) return alpha;
    if (stand < beta) beta = stand;
  }
  if (qd <= 0) return stand;
  final captures = s
      .allLegalMoves(s.turn)
      .where((m) => s.at(m.toR, m.toC) != null || m.isEnPassant)
      .toList();
  _orderMoves(s, captures);
  if (maximizing) {
    for (final m in captures) {
      final copy = GameState.clone(s);
      copy.apply(m);
      alpha = max(alpha, _quiesce(copy, alpha, beta, false, qd - 1));
      if (alpha >= beta) break;
    }
    return alpha;
  } else {
    for (final m in captures) {
      final copy = GameState.clone(s);
      copy.apply(m);
      beta = min(beta, _quiesce(copy, alpha, beta, true, qd - 1));
      if (beta <= alpha) break;
    }
    return beta;
  }
}

ChessMove? computeAiMove(AiRequest req) =>
    pickMoveSync(req.state, req.depth, seed: req.seed);
