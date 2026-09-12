import 'move.dart';
import 'piece.dart';

enum GameResult { ongoing, whiteWins, blackWins, drawStalemate, drawFifty, drawRepetition }

class GameState {
  late List<List<Piece?>> board;
  PieceColor turn = PieceColor.white;
  bool wKingside = true;
  bool wQueenside = true;
  bool bKingside = true;
  bool bQueenside = true;
  int? epR;
  int? epC;
  int halfmove = 0;
  int fullmove = 1;
  final Map<String, int> _positionCounts = {};

  GameState() {
    reset();
  }

  GameState.clone(GameState other) {
    board = [
      for (var r = 0; r < 8; r++) [for (var c = 0; c < 8; c++) other.board[r][c]]
    ];
    turn = other.turn;
    wKingside = other.wKingside;
    wQueenside = other.wQueenside;
    bKingside = other.bKingside;
    bQueenside = other.bQueenside;
    epR = other.epR;
    epC = other.epC;
    halfmove = other.halfmove;
    fullmove = other.fullmove;
    _positionCounts.addAll(other._positionCounts);
  }

  void reset() {
    board = List.generate(8, (_) => List<Piece?>.filled(8, null));
    const back = [
      PieceType.rook,
      PieceType.knight,
      PieceType.bishop,
      PieceType.queen,
      PieceType.king,
      PieceType.bishop,
      PieceType.knight,
      PieceType.rook,
    ];
    for (var c = 0; c < 8; c++) {
      board[0][c] = Piece(PieceColor.black, back[c]);
      board[1][c] = const Piece(PieceColor.black, PieceType.pawn);
      board[6][c] = const Piece(PieceColor.white, PieceType.pawn);
      board[7][c] = Piece(PieceColor.white, back[c]);
    }
    turn = PieceColor.white;
    wKingside = wQueenside = bKingside = bQueenside = true;
    epR = epC = null;
    halfmove = 0;
    fullmove = 1;
    _positionCounts
      ..clear()
      ..[positionKey()] = 1;
  }

  static bool inBounds(int r, int c) => r >= 0 && r < 8 && c >= 0 && c < 8;

  Piece? at(int r, int c) => inBounds(r, c) ? board[r][c] : null;

  List<int>? kingPos(PieceColor color) {
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        final p = board[r][c];
        if (p != null && p.color == color && p.type == PieceType.king) {
          return [r, c];
        }
      }
    }
    return null;
  }

  bool isAttacked(int r, int c, PieceColor by) {
    for (var i = 0; i < 8; i++) {
      for (var j = 0; j < 8; j++) {
        final p = board[i][j];
        if (p == null || p.color != by) continue;
        if (_pseudoAttacks(p, i, j, r, c)) return true;
      }
    }
    return false;
  }

  bool _pseudoAttacks(Piece p, int r, int c, int tr, int tc) {
    final dr = tr - r;
    final dc = tc - c;
    switch (p.type) {
      case PieceType.pawn:
        final dir = p.color == PieceColor.white ? -1 : 1;
        return dr == dir && (dc == 1 || dc == -1);
      case PieceType.knight:
        return (dr.abs() == 2 && dc.abs() == 1) ||
            (dr.abs() == 1 && dc.abs() == 2);
      case PieceType.king:
        return dr.abs() <= 1 && dc.abs() <= 1 && (dr != 0 || dc != 0);
      case PieceType.bishop:
        if (dr.abs() != dc.abs() || dr == 0) return false;
        return _pathClear(r, c, tr, tc);
      case PieceType.rook:
        if (dr != 0 && dc != 0) return false;
        if (dr == 0 && dc == 0) return false;
        return _pathClear(r, c, tr, tc);
      case PieceType.queen:
        if (dr == 0 && dc == 0) return false;
        if (dr == 0 || dc == 0 || dr.abs() == dc.abs()) {
          return _pathClear(r, c, tr, tc);
        }
        return false;
    }
  }

  bool _pathClear(int r, int c, int tr, int tc) {
    final dr = (tr - r).sign;
    final dc = (tc - c).sign;
    var i = r + dr;
    var j = c + dc;
    while (i != tr || j != tc) {
      if (board[i][j] != null) return false;
      i += dr;
      j += dc;
    }
    return true;
  }

  bool isInCheck(PieceColor color) {
    final k = kingPos(color);
    if (k == null) return false;
    return isAttacked(k[0], k[1], color.opposite);
  }

  List<ChessMove> pseudoMoves(int r, int c) {
    final p = at(r, c);
    if (p == null) return [];
    final out = <ChessMove>[];
    void addSlide(List<List<int>> dirs) {
      for (final d in dirs) {
        var i = r + d[0];
        var j = c + d[1];
        while (inBounds(i, j)) {
          final t = board[i][j];
          if (t == null) {
            out.add(ChessMove(fromR: r, fromC: c, toR: i, toC: j));
          } else {
            if (t.color != p.color) {
              out.add(ChessMove(fromR: r, fromC: c, toR: i, toC: j));
            }
            break;
          }
          i += d[0];
          j += d[1];
        }
      }
    }

    switch (p.type) {
      case PieceType.pawn:
        final dir = p.color == PieceColor.white ? -1 : 1;
        final start = p.color == PieceColor.white ? 6 : 1;
        final lastRank = p.color == PieceColor.white ? 0 : 7;
        if (at(r + dir, c) == null && inBounds(r + dir, c)) {
          if (r + dir == lastRank) {
            for (final pr in [
              PieceType.queen,
              PieceType.rook,
              PieceType.bishop,
              PieceType.knight
            ]) {
              out.add(ChessMove(
                  fromR: r, fromC: c, toR: r + dir, toC: c, promotion: pr));
            }
          } else {
            out.add(ChessMove(fromR: r, fromC: c, toR: r + dir, toC: c));
            if (r == start && at(r + 2 * dir, c) == null) {
              out
                  .add(ChessMove(fromR: r, fromC: c, toR: r + 2 * dir, toC: c));
            }
          }
        }
        for (final dc in [-1, 1]) {
          final i = r + dir;
          final j = c + dc;
          if (!inBounds(i, j)) continue;
          final t = board[i][j];
          if (t != null && t.color != p.color) {
            if (i == lastRank) {
              for (final pr in [
                PieceType.queen,
                PieceType.rook,
                PieceType.bishop,
                PieceType.knight
              ]) {
                out.add(ChessMove(
                    fromR: r, fromC: c, toR: i, toC: j, promotion: pr));
              }
            } else {
              out.add(ChessMove(fromR: r, fromC: c, toR: i, toC: j));
            }
          }
          if (epR == i && epC == j) {
            out.add(ChessMove(
                fromR: r, fromC: c, toR: i, toC: j, isEnPassant: true));
          }
        }
        break;
      case PieceType.knight:
        for (final d in [
          [2, 1],
          [2, -1],
          [-2, 1],
          [-2, -1],
          [1, 2],
          [1, -2],
          [-1, 2],
          [-1, -2]
        ]) {
          final i = r + d[0];
          final j = c + d[1];
          if (!inBounds(i, j)) continue;
          final t = board[i][j];
          if (t == null || t.color != p.color) {
            out.add(ChessMove(fromR: r, fromC: c, toR: i, toC: j));
          }
        }
        break;
      case PieceType.bishop:
        addSlide([
          [1, 1],
          [1, -1],
          [-1, 1],
          [-1, -1]
        ]);
        break;
      case PieceType.rook:
        addSlide([
          [1, 0],
          [-1, 0],
          [0, 1],
          [0, -1]
        ]);
        break;
      case PieceType.queen:
        addSlide([
          [1, 0],
          [-1, 0],
          [0, 1],
          [0, -1],
          [1, 1],
          [1, -1],
          [-1, 1],
          [-1, -1]
        ]);
        break;
      case PieceType.king:
        for (var i = -1; i <= 1; i++) {
          for (var j = -1; j <= 1; j++) {
            if (i == 0 && j == 0) continue;
            final tr = r + i;
            final tc = c + j;
            if (!inBounds(tr, tc)) continue;
            final t = board[tr][tc];
            if (t == null || t.color != p.color) {
              out.add(ChessMove(fromR: r, fromC: c, toR: tr, toC: tc));
            }
          }
        }
        final home = p.color == PieceColor.white ? 7 : 0;
        final inCheck = isInCheck(p.color);
        if (r == home && c == 4 && !inCheck) {
          final ks = p.color == PieceColor.white ? wKingside : bKingside;
          final qs = p.color == PieceColor.white ? wQueenside : bQueenside;
          if (ks &&
              board[home][5] == null &&
              board[home][6] == null &&
              !isAttacked(home, 5, p.color.opposite) &&
              !isAttacked(home, 6, p.color.opposite)) {
            final rook = board[home][7];
            if (rook != null &&
                rook.type == PieceType.rook &&
                rook.color == p.color) {
              out.add(ChessMove(
                  fromR: r,
                  fromC: c,
                  toR: home,
                  toC: 6,
                  isCastleKingside: true));
            }
          }
          if (qs &&
              board[home][1] == null &&
              board[home][2] == null &&
              board[home][3] == null &&
              !isAttacked(home, 3, p.color.opposite) &&
              !isAttacked(home, 2, p.color.opposite)) {
            final rook = board[home][0];
            if (rook != null &&
                rook.type == PieceType.rook &&
                rook.color == p.color) {
              out.add(ChessMove(
                  fromR: r,
                  fromC: c,
                  toR: home,
                  toC: 2,
                  isCastleQueenside: true));
            }
          }
        }
        break;
    }
    return out;
  }

  List<ChessMove> legalMoves(int r, int c) {
    final p = at(r, c);
    if (p == null || p.color != turn) return [];
    return pseudoMoves(r, c).where((m) {
      final copy = GameState.clone(this);
      copy._apply(m);
      return !copy.isInCheck(p.color);
    }).toList();
  }

  List<ChessMove> allLegalMoves(PieceColor color) {
    final out = <ChessMove>[];
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        final p = board[r][c];
        if (p == null || p.color != color) continue;
        for (final m in pseudoMoves(r, c)) {
          final copy = GameState.clone(this);
          copy._apply(m);
          if (!copy.isInCheck(color)) out.add(m);
        }
      }
    }
    return out;
  }

  bool get hasAnyLegalMove => allLegalMoves(turn).isNotEmpty;

  void apply(ChessMove m) {
    _apply(m);
    if (turn == PieceColor.black) {
      turn = PieceColor.white;
    } else {
      turn = PieceColor.black;
      fullmove++;
    }
    final key = positionKey();
    _positionCounts[key] = (_positionCounts[key] ?? 0) + 1;
  }

  void _apply(ChessMove m) {
    final p = board[m.fromR][m.fromC];
    if (p == null) return;
    final target = board[m.toR][m.toC];
    final isCapture = target != null || m.isEnPassant;
    final isPawn = p.type == PieceType.pawn;

    if (m.isCastleKingside) {
      final home = p.color == PieceColor.white ? 7 : 0;
      board[home][6] = p;
      board[home][4] = null;
      board[home][5] = board[home][7];
      board[home][7] = null;
    } else if (m.isCastleQueenside) {
      final home = p.color == PieceColor.white ? 7 : 0;
      board[home][2] = p;
      board[home][4] = null;
      board[home][3] = board[home][0];
      board[home][0] = null;
    } else {
      if (m.isEnPassant) {
        board[m.fromR][m.toC] = null;
      }
      final placed = m.promotion != null
          ? Piece(p.color, m.promotion!)
          : p;
      board[m.toR][m.toC] = placed;
      board[m.fromR][m.fromC] = null;
    }

    if (p.type == PieceType.king) {
      if (p.color == PieceColor.white) {
        wKingside = wQueenside = false;
      } else {
        bKingside = bQueenside = false;
      }
    }
    if (p.type == PieceType.rook) {
      if (p.color == PieceColor.white && m.fromR == 7) {
        if (m.fromC == 0) wQueenside = false;
        if (m.fromC == 7) wKingside = false;
      }
      if (p.color == PieceColor.black && m.fromR == 0) {
        if (m.fromC == 0) bQueenside = false;
        if (m.fromC == 7) bKingside = false;
      }
      if (m.toR == 7 && m.toC == 0) wQueenside = false;
      if (m.toR == 7 && m.toC == 7) wKingside = false;
      if (m.toR == 0 && m.toC == 0) bQueenside = false;
      if (m.toR == 0 && m.toC == 7) bKingside = false;
    }

    epR = epC = null;
    if (p.type == PieceType.pawn && (m.toR - m.fromR).abs() == 2) {
      epR = (m.fromR + m.toR) ~/ 2;
      epC = m.fromC;
    }

    halfmove = (isPawn || isCapture) ? 0 : halfmove + 1;
  }

  String positionKey() {
    final sb = StringBuffer();
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        final p = board[r][c];
        if (p == null) {
          sb.write('.');
        } else {
          final ch = _fenChar(p.type);
          sb.write(p.color == PieceColor.white ? ch.toUpperCase() : ch);
        }
      }
    }
    sb.write(turn == PieceColor.white ? 'w' : 'b');
    sb.write('$wKingside$wQueenside$bKingside$bQueenside');
    sb.write('${epR ?? '-'},${epC ?? '-'}');
    return sb.toString();
  }

  static String _fenChar(PieceType t) {
    switch (t) {
      case PieceType.king:
        return 'k';
      case PieceType.queen:
        return 'q';
      case PieceType.rook:
        return 'r';
      case PieceType.bishop:
        return 'b';
      case PieceType.knight:
        return 'n';
      case PieceType.pawn:
        return 'p';
    }
  }

  static const _sanLetter = {
    PieceType.king: 'R',
    PieceType.queen: 'M',
    PieceType.rook: 'B',
    PieceType.bishop: 'G',
    PieceType.knight: 'K',
    PieceType.pawn: '',
  };

  /// Notasi SAN dengan huruf Indonesia (R/M/B/G/K).
  /// Panggil sebelum [apply]: memakai papan pra-langkah untuk
  /// disambiguasi dan papan pasca-langkah untuk sufiks skak/mat.
  String san(ChessMove m) {
    if (m.isCastleKingside) return 'O-O${_checkSuffix(m)}';
    if (m.isCastleQueenside) return 'O-O-O${_checkSuffix(m)}';
    final p = board[m.fromR][m.fromC];
    if (p == null) return m.squareTo;
    final capture = board[m.toR][m.toC] != null || m.isEnPassant;
    final sb = StringBuffer();
    if (p.type == PieceType.pawn) {
      if (capture) {
        sb.write(String.fromCharCode(97 + m.fromC));
        sb.write('x');
      }
      sb.write(m.squareTo);
      if (m.promotion != null) {
        sb.write('=${_sanLetter[m.promotion]!}');
      }
    } else {
      sb.write(_sanLetter[p.type]!);
      sb.write(_disambiguation(p, m));
      if (capture) sb.write('x');
      sb.write(m.squareTo);
    }
    sb.write(_checkSuffix(m));
    return sb.toString();
  }

  String _disambiguation(Piece p, ChessMove m) {
    var sameFile = false;
    var sameRank = false;
    var clash = false;
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        if (r == m.fromR && c == m.fromC) continue;
        final q = board[r][c];
        if (q == null || q.color != p.color || q.type != p.type) continue;
        final reaches = pseudoMoves(r, c).any((x) =>
            x.toR == m.toR && x.toC == m.toC && x.promotion == m.promotion);
        if (!reaches) continue;
        final copy = GameState.clone(this);
        copy._apply(ChessMove(fromR: r, fromC: c, toR: m.toR, toC: m.toC));
        if (copy.isInCheck(p.color)) continue;
        clash = true;
        if (c == m.fromC) sameFile = true;
        if (r == m.fromR) sameRank = true;
      }
    }
    if (!clash) return '';
    if (!sameFile) return String.fromCharCode(97 + m.fromC);
    if (!sameRank) return '${8 - m.fromR}';
    return '${String.fromCharCode(97 + m.fromC)}${8 - m.fromR}';
  }

  String _checkSuffix(ChessMove m) {
    final copy = GameState.clone(this);
    copy._apply(m);
    final enemy = turn.opposite;
    if (!copy.isInCheck(enemy)) return '';
    return copy.allLegalMoves(enemy).isEmpty ? '#' : '+';
  }

  GameResult result() {
    final moves = allLegalMoves(turn);
    if (moves.isEmpty) {
      if (isInCheck(turn)) {
        return turn == PieceColor.white
            ? GameResult.blackWins
            : GameResult.whiteWins;
      }
      return GameResult.drawStalemate;
    }
    if (halfmove >= 100) return GameResult.drawFifty;
    if ((_positionCounts[positionKey()] ?? 0) >= 3) {
      return GameResult.drawRepetition;
    }
    return GameResult.ongoing;
  }
}
