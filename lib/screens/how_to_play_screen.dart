import 'package:flutter/material.dart';
import '../theme/gold_theme.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(GoldTheme.gap20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cara main', style: text.headlineSmall),
              const SizedBox(height: GoldTheme.gap16),
              Text('Gerak bidak.',
                  style: text.titleLarge?.copyWith(fontSize: 16)),
              const SizedBox(height: GoldTheme.gap8),
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
              const SizedBox(height: GoldTheme.gap16),
              Text('Aturan khusus.',
                  style: text.titleLarge?.copyWith(fontSize: 16)),
              const SizedBox(height: GoldTheme.gap8),
              _RuleText(
                  'Rokade: raja dan benteng yang belum bergerak bisa bertukar tempat jika tidak skak dan jalurnya kosong.'),
              _RuleText(
                  'En passant: pion yang maju dua petak bisa dimakan pion lawan seolah maju satu.'),
              _RuleText(
                  'Promosi: pion yang sampai ujung berubah jadi menteri, benteng, gajah, atau kuda.'),
              const SizedBox(height: GoldTheme.gap16),
              Text('Akhir permainan.',
                  style: text.titleLarge?.copyWith(fontSize: 16)),
              const SizedBox(height: GoldTheme.gap8),
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
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: GoldTheme.gap8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            child: Text(glyph, style: text.headlineSmall),
          ),
          Expanded(
            child: Text('$name. $move', style: text.bodyMedium),
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
      padding: const EdgeInsets.only(bottom: GoldTheme.gap8),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
