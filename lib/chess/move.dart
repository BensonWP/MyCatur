import 'piece.dart' show PieceType;

class ChessMove {
  final int fromR;
  final int fromC;
  final int toR;
  final int toC;
  final PieceType? promotion;
  final bool isCastleKingside;
  final bool isCastleQueenside;
  final bool isEnPassant;

  const ChessMove({
    required this.fromR,
    required this.fromC,
    required this.toR,
    required this.toC,
    this.promotion,
    this.isCastleKingside = false,
    this.isCastleQueenside = false,
    this.isEnPassant = false,
  });

  String get squareTo => _square(toR, toC);

  static String _square(int r, int c) =>
      '${String.fromCharCode(97 + c)}${8 - r}';
}
