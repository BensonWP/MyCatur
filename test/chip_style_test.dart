import 'package:catur/theme/gold_theme.dart';
import 'package:catur/widgets/sheets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Chip terpilih selalu disabled (onTap null) supaya tidak bisa di-tap
  // ulang. Bug lama: styleFrom membuat map {disabled: null} sehingga
  // foreground fallback ke onSurface 38% dan teks terlihat hitam pudar
  // di atas emas. Regression test ini menuntut warna putih tetap
  // ter-resolve pada state disabled.
  testWidgets('Chip terpilih (disabled): teks putih di atas emas tua',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: GoldTheme.theme(),
        home: Scaffold(
          body: Center(
            child: choiceChip('Sedang', selected: true, onTap: null),
          ),
        ),
      ),
    );
    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    final style = button.style!;
    expect(
      style.foregroundColor?.resolve({WidgetState.disabled}),
      GoldTheme.onSelected,
    );
    expect(
      style.backgroundColor?.resolve({WidgetState.disabled}),
      GoldTheme.selectedFill,
    );
  });

  testWidgets('Chip terpilih (enabled): warna sama', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: GoldTheme.theme(),
        home: Scaffold(
          body: Center(
            child: choiceChip('Sedang', selected: true, onTap: () {}),
          ),
        ),
      ),
    );
    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    final style = button.style!;
    expect(style.foregroundColor?.resolve({}), GoldTheme.onSelected);
    expect(style.backgroundColor?.resolve({}), GoldTheme.selectedFill);
  });

  testWidgets('Chip tidak terpilih: teks ink, latar transparan', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: GoldTheme.theme(),
        home: Scaffold(
          body: Center(
            child: choiceChip('Sedang', selected: false, onTap: () {}),
          ),
        ),
      ),
    );
    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    final style = button.style!;
    expect(style.foregroundColor?.resolve({}), GoldTheme.ink);
    expect(style.backgroundColor?.resolve({}), isNull);
  });
}
