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
  if (depth <= 0) return evaluateBoard(s);
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
  moves.sort((a, b) {
    final capA = s.at(a.toR, a.toC) != null || a.isEnPassant ? 1 : 0;
    final capB = s.at(b.toR, b.toC) != null || b.isEnPassant ? 1 : 0;
    return capB - capA;
  });
}

ChessMove? computeAiMove(AiRequest req) =>
    pickMoveSync(req.state, req.depth, seed: req.seed);
