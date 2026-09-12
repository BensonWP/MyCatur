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

  /// Glif filled untuk kedua warna. Warna bidak dibedakan lewat
  /// TextStyle di widget papan, supaya konsisten di semua font Android
  /// (glif outline sering fallback ke emoji dan terlihat tipis).
  /// Akhiran \uFE0E (variation selector-15) memaksa presentasi teks:
  /// tanpa itu, font emoji Android merender glif sebagai emoji berwarna
  /// yang mengabaikan TextStyle sepenuhnya.
  String get glyphSolid {
    const solid = {
      PieceType.king: '♚',
      PieceType.queen: '♛',
      PieceType.rook: '♜',
      PieceType.bishop: '♝',
      PieceType.knight: '♞',
      PieceType.pawn: '♟',
    };
    return '${solid[type]!}\uFE0E';
  }
}
