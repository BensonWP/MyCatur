import 'package:catur/chess/ai.dart';
import 'package:catur/chess/game_state.dart';
import 'package:catur/chess/move.dart';
import 'package:catur/chess/piece.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Langkah awal putih berjumlah 20', () {
    final s = GameState();
    expect(s.allLegalMoves(PieceColor.white).length, 20);
  });

  test('Skakmat bodoh terdeteksi', () {
    final s = GameState();
    s.apply(const ChessMove(fromR: 6, fromC: 5, toR: 5, toC: 5));
    s.apply(const ChessMove(fromR: 1, fromC: 4, toR: 3, toC: 4));
    s.apply(const ChessMove(fromR: 6, fromC: 6, toR: 4, toC: 6));
    s.apply(const ChessMove(fromR: 0, fromC: 3, toR: 4, toC: 7));
    expect(s.result(), GameResult.blackWins);
  });

  test('Promosi pion tersedia', () {
    final s = GameState();
    s.board = List.generate(8, (_) => List<Piece?>.filled(8, null));
    s.board[0][4] = const Piece(PieceColor.black, PieceType.king);
    s.board[7][4] = const Piece(PieceColor.white, PieceType.king);
    s.board[1][0] = const Piece(PieceColor.white, PieceType.pawn);
    s.turn = PieceColor.white;
    final moves = s.legalMoves(1, 0);
    expect(moves.where((m) => m.promotion != null).length, 4);
  });

  test('AI memilih langkah legal', () {
    final s = GameState();
    final m = pickMoveSync(s, 1);
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

  test('Rokade tersedia di posisi awal yang dilonggarkan', () {
    final s = GameState();
    s.board[7][5] = null;
    s.board[7][6] = null;
    final moves = s.legalMoves(7, 4);
    expect(moves.any((m) => m.isCastleKingside), true);
  });

  test('En passant tersedia', () {
    final s = GameState();
    s.board = List.generate(8, (_) => List<Piece?>.filled(8, null));
    s.board[0][4] = const Piece(PieceColor.black, PieceType.king);
    s.board[7][4] = const Piece(PieceColor.white, PieceType.king);
    s.board[3][4] = const Piece(PieceColor.white, PieceType.pawn);
    s.board[1][3] = const Piece(PieceColor.black, PieceType.pawn);
    s.turn = PieceColor.black;
    s.apply(const ChessMove(fromR: 1, fromC: 3, toR: 3, toC: 3));
    final moves = s.legalMoves(3, 4);
    expect(moves.any((m) => m.isEnPassant), true);
  });
}
