import 'package:flutter/material.dart';
import '../chess/ai.dart';
import '../chess/stats_store.dart';
import '../theme/gold_theme.dart';

class StatsScreen extends StatefulWidget {
  /// MainShell memakai IndexedStack: halaman tetap mounted saat tab lain
  /// aktif. Flag ini memicu muat ulang tiap tab Statistik dibuka.
  final bool visible;

  const StatsScreen({super.key, this.visible = true});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final StatsStore store = StatsStore.instance;
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(StatsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) _reload();
  }

  Future<void> _reload() async {
    await store.load();
    if (mounted) setState(() => loaded = true);
  }

  Future<void> _confirmClear() async {
    final choice = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus statistik'),
        content: const Text(
          'Semua catatan menang kalah akan dihapus. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (choice == true) {
      await store.clear();
      if (mounted) setState(() {});
    }
  }

  /// Bar tiga segmen dari data nyata: menang = aksen emas (satu-satunya
  /// aksen, untuk momen kemenangan), seri = krem redup, kalah = netral
  /// gelap. Tidak ada warna di luar sistem token.
  Widget _resultBar({
    required int first,
    required int second,
    required int third,
    required Color firstColor,
    required String caption,
  }) {
    final text = Theme.of(context).textTheme;
    final total = first + second + third;
    if (total == 0) {
      return Text('Belum ada permainan.', style: text.titleSmall);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: [
              if (first > 0)
                Expanded(
                  flex: first,
                  child: Container(height: 8, color: firstColor),
                ),
              if (second > 0)
                Expanded(
                  flex: second,
                  child: Container(
                    height: 8,
                    color: GoldTheme.creamText.withValues(alpha: 0.4),
                  ),
                ),
              if (third > 0)
                Expanded(
                  flex: third,
                  child: Container(
                      height: 8, color: Colors.black.withValues(alpha: 0.6)),
                ),
            ],
          ),
        ),
        const SizedBox(height: GoldTheme.gap4),
        Text(caption, style: text.bodySmall),
      ],
    );
  }

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
              Text('Statistik', style: text.headlineSmall),
              const SizedBox(height: GoldTheme.gap4),
              Text('Catatan di HP ini.', style: text.titleSmall),
              const SizedBox(height: GoldTheme.gap16),
              if (!loaded)
                Text('Memuat catatan.', style: text.bodyMedium)
              else if (store.isEmpty)
                Text(
                  'Belum ada permainan tercatat. Mainkan dulu.',
                  style: text.bodyMedium,
                )
              else ...[
                Text('Lawan komputer.', style: text.titleLarge),
                const SizedBox(height: GoldTheme.gap8),
                for (final level in AiLevel.values)
                  Padding(
                    padding:
                        const EdgeInsets.only(bottom: GoldTheme.gap12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(level.label, style: text.titleMedium),
                        const SizedBox(height: GoldTheme.gap4),
                        _resultBar(
                          first: store.aiWin(level),
                          second: store.aiDraw(level),
                          third: store.aiLoss(level),
                          firstColor: GoldTheme.accent,
                          caption:
                              '${store.aiWin(level)} menang, ${store.aiDraw(level)} seri, ${store.aiLoss(level)} kalah.',
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: GoldTheme.gap16),
                Text('Main berdua.', style: text.titleLarge),
                const SizedBox(height: GoldTheme.gap8),
                Text('Putih', style: text.titleMedium),
                const SizedBox(height: GoldTheme.gap4),
                _resultBar(
                  first: store.twoWhite,
                  second: store.twoDraw,
                  third: store.twoBlack,
                  firstColor: GoldTheme.creamText,
                  caption:
                      'Putih ${store.twoWhite}, Seri ${store.twoDraw}, Hitam ${store.twoBlack}.',
                ),
                const SizedBox(height: GoldTheme.gap16),
                OutlinedButton(
                  onPressed: _confirmClear,
                  child: const Text('Hapus statistik'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
