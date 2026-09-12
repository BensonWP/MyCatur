import 'package:flutter/material.dart';
import '../chess/game_settings.dart';
import '../theme/gold_theme.dart';

// Opsi kecil satu ukuran. Terpilih = emas tua solid + teks putih (AA);
// tidak terpilih = border walnut tenang, teks ink penuh. Emas hanya
// muncul pada keadaan "aktif", sama semantik dengan target langkah
// di papan, jadi aksen tidak bersaing dengan tombol mulai.
//
// Warna dipasang sebagai WidgetStatePropertyAll, bukan styleFrom:
// styleFrom membuat map {disabled: null} sehingga chip terpilih
// (onPressed null) jatuh ke default onSurface 38% dan teks tampak
// hitam pudar di atas emas.
Widget choiceChip(
  String label, {
  required bool selected,
  VoidCallback? onTap,
}) {
  return OutlinedButton(
    onPressed: onTap,
    style: ButtonStyle(
      backgroundColor: selected
          ? const WidgetStatePropertyAll(GoldTheme.selectedFill)
          : null,
      foregroundColor: WidgetStatePropertyAll(
        selected ? GoldTheme.onSelected : GoldTheme.ink,
      ),
      side: WidgetStatePropertyAll(
        BorderSide(
          color: selected ? GoldTheme.selectedFill : GoldTheme.quietBorder,
        ),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GoldTheme.radiusButton),
        ),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(48, 44)),
    ),
    child: Text(label),
  );
}

Widget chipRow<T>({
  required List<T> values,
  required T current,
  required String Function(T) label,
  required void Function(T) onPick,
}) {
  return Row(
    children: values.map((v) {
      final last = v == values.last;
      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: last ? 0 : GoldTheme.gap8),
          child: choiceChip(
            label(v),
            selected: current == v,
            onTap: current == v ? null : () => onPick(v),
          ),
        ),
      );
    }).toList(),
  );
}

/// Lembar Pengaturan: tempo + animasi langkah. Berlaku langsung lewat
/// onApply; tombol tutup tidak membuang perubahan yang sudah dipilih.
Future<void> openSettingsSheet(
  BuildContext context, {
  required GameSettings current,
  required void Function(GameSettings) onApply,
}) {
  var settings = current;
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      final text = Theme.of(sheetContext).textTheme;
      void withSettings(GameSettings next) {
        settings = next;
        onApply(next);
      }

      return StatefulBuilder(
        builder: (context, setSheetState) {
          void pick(GameSettings next) {
            setSheetState(() => withSettings(next));
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(GoldTheme.gap16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Pengaturan', style: text.titleLarge),
                  const SizedBox(height: GoldTheme.gap16),
                  Text('Tempo', style: text.titleSmall),
                  const SizedBox(height: GoldTheme.gap8),
                  chipRow<Tempo>(
                    values: Tempo.values,
                    current: settings.tempo,
                    label: (t) => t == Tempo.santai ? 'Santai' : 'Cepat',
                    onPick: (t) => pick(GameSettings(
                      tempo: t,
                      clock: settings.clock,
                      animation: settings.animation,
                    )),
                  ),
                  const SizedBox(height: GoldTheme.gap12),
                  Text('Animasi langkah', style: text.titleSmall),
                  const SizedBox(height: GoldTheme.gap8),
                  chipRow<int>(
                    values: const [1, 0],
                    current: settings.animation ? 1 : 0,
                    label: (v) => v == 1 ? 'Aktif' : 'Mati',
                    onPick: (v) => pick(GameSettings(
                      tempo: settings.tempo,
                      clock: settings.clock,
                      animation: v == 1,
                    )),
                  ),
                  const SizedBox(height: GoldTheme.gap16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
