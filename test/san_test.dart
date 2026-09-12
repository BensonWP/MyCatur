import 'package:catur/chess/ai.dart';
import 'package:catur/chess/game_state.dart';
import 'package:catur/chess/move.dart';
import 'package:catur/chess/piece.dart';
import 'package:flutter_test/flutter_test.dart';

ChessMove _find(GameState s, bool Function(ChessMove) test, int r, int c) {
  return s.legalMoves(r, c).firstWhere(test);
}

void main() {
  test('SAN scholar mate berakhir Mxf7#', () {
    final s = GameState();
    final seq = [
      _find(s, (m) => m.toR == 4 && m.toC == 4, 6, 4),
    ];
    expect(s.san(seq.single), 'e4');
    s.apply(seq.single);
    ChessMove m = _find(s, (mm) => mm.toR == 3 && mm.toC == 4, 1, 4);
    expect(s.san(m), 'e5');
    s.apply(m);
    m = _find(s, (mm) => mm.toR == 4 && mm.toC == 2, 7, 5);
    expect(s.san(m), 'Gc4');
    s.apply(m);
    m = _find(s, (mm) => mm.toR == 2 && mm.toC == 2, 0, 1);
    expect(s.san(m), 'Kc6');
    s.apply(m);
    m = _find(s, (mm) => mm.toR == 3 && mm.toC == 7, 7, 3);
    expect(s.san(m), 'Mh5');
    s.apply(m);
    m = _find(s, (mm) => mm.toR == 2 && mm.toC == 5, 0, 6);
    expect(s.san(m), 'Kf6');
    s.apply(m);
    m = _find(s, (mm) => mm.toR == 1 && mm.toC == 5, 3, 7);
    expect(s.san(m), 'Mxf7#');
    s.apply(m);
    expect(s.result(), GameResult.whiteWins);
  });

  test('SAN rokade pendek O-O', () {
    final s = GameState();
    for (final a in [
      const ChessMove(fromR: 6, fromC: 4, toR: 4, toC: 4),
      const ChessMove(fromR: 1, fromC: 4, toR: 3, toC: 4),
      const ChessMove(fromR: 7, fromC: 6, toR: 5, toC: 5),
      const ChessMove(fromR: 0, fromC: 1, toR: 2, toC: 2),
      const ChessMove(fromR: 7, fromC: 5, toR: 4, toC: 2),
      const ChessMove(fromR: 0, fromC: 5, toR: 3, toC: 2),
    ]) {
      s.apply(a);
    }
    final m = s.legalMoves(7, 4).firstWhere((e) => e.isCastleKingside);
    expect(s.san(m), 'O-O');
  });

  test('SAN en passant exd6', () {
    final s = GameState();
    s.board = List.generate(8, (_) => List<Piece?>.filled(8, null));
    s.board[0][4] = const Piece(PieceColor.black, PieceType.king);
    s.board[7][4] = const Piece(PieceColor.white, PieceType.king);
    s.board[3][4] = const Piece(PieceColor.white, PieceType.pawn);
    s.board[1][3] = const Piece(PieceColor.black, PieceType.pawn);
    s.turn = PieceColor.black;
    s.apply(const ChessMove(fromR: 1, fromC: 3, toR: 3, toC: 3));
    final m = s.legalMoves(3, 4).firstWhere((e) => e.isEnPassant);
    expect(s.san(m), 'exd6');
  });

  test('SAN promosi a8=M', () {
    final s = GameState();
    s.board = List.generate(8, (_) => List<Piece?>.filled(8, null));
    s.board[2][4] = const Piece(PieceColor.black, PieceType.king);
    s.board[7][4] = const Piece(PieceColor.white, PieceType.king);
    s.board[1][0] = const Piece(PieceColor.white, PieceType.pawn);
    s.turn = PieceColor.white;
    final m = s
        .legalMoves(1, 0)
        .firstWhere((e) => e.promotion == PieceType.queen);
    expect(s.san(m), 'a8=M');
  });

  test('SAN skak Mh5+', () {
    final s = GameState();
    s.board = List.generate(8, (_) => List<Piece?>.filled(8, null));
    s.board[0][4] = const Piece(PieceColor.black, PieceType.king);
    s.board[7][4] = const Piece(PieceColor.white, PieceType.king);
    s.board[7][3] = const Piece(PieceColor.white, PieceType.queen);
    s.turn = PieceColor.white;
    final m = s.legalMoves(7, 3).firstWhere(
        (e) => e.toR == 3 && e.toC == 7 && e.promotion == null);
    expect(s.san(m), 'Mh5+');
  });

  test('Repetisi tiga kali terdeteksi dan terbawa clone', () {
    final s = GameState();
    for (var i = 0; i < 2; i++) {
      s.apply(const ChessMove(fromR: 7, fromC: 6, toR: 5, toC: 5));
      s.apply(const ChessMove(fromR: 0, fromC: 6, toR: 2, toC: 5));
      s.apply(const ChessMove(fromR: 5, fromC: 5, toR: 7, toC: 6));
      s.apply(const ChessMove(fromR: 2, fromC: 5, toR: 0, toC: 6));
    }
    expect(s.result(), GameResult.drawRepetition);
    expect(
        GameState.clone(s).result(), GameResult.drawRepetition);
  });

  test('Lima puluh langkah tanpa pion atau tangkapan seri', () {
    final s = GameState();
    s.board = List.generate(8, (_) => List<Piece?>.filled(8, null));
    s.board[0][4] = const Piece(PieceColor.black, PieceType.king);
    s.board[7][4] = const Piece(PieceColor.white, PieceType.king);
    s.board[7][0] = const Piece(PieceColor.white, PieceType.rook);
    s.turn = PieceColor.white;
    s.halfmove = 100;
    expect(s.result(), GameResult.drawFifty);
  });

  test('AI depth 2 memilih langkah legal', () {
    final s = GameState();
    final m = pickMoveSync(s, 2);
    expect(m, isNotNull);
    final legal = s.allLegalMoves(PieceColor.white);
    expect(
      legal.any((x) =>
          x.fromR == m!.fromR &&
          x.fromC == m.fromC &&
          x.toR == m.toR &&
          x.toC == m.toC),
      true,
    );
  });
}
