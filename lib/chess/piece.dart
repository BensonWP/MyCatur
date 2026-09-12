enum PieceColor { white, black }

extension PieceColorExt on PieceColor {
  PieceColor get opposite =>
      this == PieceColor.white ? PieceColor.black : PieceColor.white;
}

enum PieceType { king, queen, rook, bishop, knight, pawn }

class Piece {
  final PieceColor color;
  final PieceType type;
  const Piece(this.color, this.type);

  String get glyph {
    const white = {
      PieceType.king: '♔',
      PieceType.queen: '♕',
      PieceType.rook: '♖',
      PieceType.bishop: '♗',
      PieceType.knight: '♘',
      PieceType.pawn: '♙',
    };
    const black = {
      PieceType.king: '♚',
      PieceType.queen: '♛',
      PieceType.rook: '♜',
      PieceType.bishop: '♝',
      PieceType.knight: '♞',
      PieceType.pawn: '♟',
    };
    return color == PieceColor.white ? white[type]! : black[type]!;
  }
}
