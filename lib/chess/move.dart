import 'piece.dart';

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

  String get squareFrom => _square(fromR, fromC);
  String get squareTo => _square(toR, toC);

  static String _square(int r, int c) =>
      '${String.fromCharCode(97 + c)}${8 - r}';

  String label(int number, bool isWhiteMove) {
    final promo = promotion != null ? '=${_promoLetter(promotion!)}' : '';
    return '$number. ${isWhiteMove ? '' : '... '}$squareFrom $squareTo$promo';
  }

  static String _promoLetter(PieceType t) {
    switch (t) {
      case PieceType.queen:
        return 'M';
      case PieceType.rook:
        return 'B';
      case PieceType.knight:
        return 'K';
      case PieceType.bishop:
        return 'G';
      case PieceType.king:
      case PieceType.pawn:
        return '';
    }
  }
}
