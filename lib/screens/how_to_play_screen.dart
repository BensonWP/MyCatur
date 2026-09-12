import 'package:flutter/material.dart';
import '../theme/gold_theme.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cara main',
                style: TextStyle(
                  color: GoldTheme.creamText,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Gerak bidak.',
                style: TextStyle(
                  color: GoldTheme.creamText,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              _PieceRow(
                  glyph: '♙', name: 'Pion', move: 'Maju satu petak, dua dari awal. Makan diagonal.'),
              _PieceRow(
                  glyph: '♘', name: 'Kuda', move: 'Huruf L: dua lurus satu belok. Melompati bidak.'),
              _PieceRow(
                  glyph: '♗', name: 'Gajah', move: 'Diagonal sejauh petak kosong.'),
              _PieceRow(
                  glyph: '♖', name: 'Benteng', move: 'Lurus ke depan, belakang, dan samping.'),
              _PieceRow(
                  glyph: '♕', name: 'Menteri', move: 'Lurus dan diagonal, bidak paling bebas.'),
              _PieceRow(
                  glyph: '♔', name: 'Raja', move: 'Satu petak ke segala arah. Jangan biarkan dimakan.'),
              SizedBox(height: 16),
              Text(
                'Aturan khusus.',
                style: TextStyle(
                  color: GoldTheme.creamText,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              _RuleText(
                  'Rokade: raja dan benteng yang belum bergerak bisa bertukar tempat jika tidak skak dan jalurnya kosong.'),
              _RuleText(
                  'En passant: pion yang maju dua petak bisa dimakan pion lawan seolah maju satu.'),
              _RuleText(
                  'Promosi: pion yang sampai ujung berubah jadi menteri, benteng, gajah, atau kuda.'),
              SizedBox(height: 16),
              Text(
                'Akhir permainan.',
                style: TextStyle(
                  color: GoldTheme.creamText,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              _RuleText(
                  'Skakmat: raja diserang dan tidak bisa lolos. Pemenangnya yang mematikan.'),
              _RuleText(
                  'Stalemate: giliran jalan tapi tidak ada langkah legal dan tidak skak. Hasilnya seri.'),
              _RuleText(
                  'Jam: jika memakai jam dan waktumu habis, kamu kalah.'),
            ],
          ),
        ),
      ),
    );
  }
}

class _PieceRow extends StatelessWidget {
  final String glyph;
  final String name;
  final String move;
  const _PieceRow({
    required this.glyph,
    required this.name,
    required this.move,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            child: Text(
              glyph,
              style: const TextStyle(
                color: GoldTheme.creamText,
                fontSize: 26,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '$name. $move',
              style: const TextStyle(
                color: GoldTheme.creamText,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleText extends StatelessWidget {
  final String text;
  const _RuleText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: GoldTheme.creamText,
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }
}
