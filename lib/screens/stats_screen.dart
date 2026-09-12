import 'package:flutter/material.dart';
import '../chess/ai.dart';
import '../chess/stats_store.dart';
import '../theme/gold_theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final StatsStore store = StatsStore();
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    store.load().then((_) {
      if (mounted) setState(() => loaded = true);
    });
  }

  Future<void> _confirmClear() async {
    final choice = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GoldTheme.frame,
        title: const Text(
          'Hapus statistik',
          style: TextStyle(color: GoldTheme.creamText),
        ),
        content: const Text(
          'Semua catatan menang kalah akan dihapus. Lanjutkan?',
          style: TextStyle(color: GoldTheme.creamText),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Statistik',
                style: TextStyle(
                  color: GoldTheme.creamText,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Catatan di HP ini.',
                style: TextStyle(
                    color: GoldTheme.creamText, fontSize: 13),
              ),
              const SizedBox(height: 16),
              if (!loaded)
                const Text(
                  'Memuat catatan.',
                  style: TextStyle(
                      color: GoldTheme.creamText, fontSize: 14),
                )
              else if (store.isEmpty)
                const Text(
                  'Belum ada permainan tercatat. Mainkan dulu.',
                  style: TextStyle(
                      color: GoldTheme.creamText, fontSize: 14),
                )
              else ...[
                const Text(
                  'Lawan komputer.',
                  style: TextStyle(
                    color: GoldTheme.creamText,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                for (final level in AiLevel.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${level.label}: ${store.aiWin(level)} menang, ${store.aiDraw(level)} seri, ${store.aiLoss(level)} kalah.',
                      style: const TextStyle(
                        color: GoldTheme.creamText,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Main berdua.',
                  style: TextStyle(
                    color: GoldTheme.creamText,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Putih ${store.twoWhite}, Hitam ${store.twoBlack}, Seri ${store.twoDraw}.',
                  style: const TextStyle(
                    color: GoldTheme.creamText,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
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
