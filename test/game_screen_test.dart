import 'package:catur/screens/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Tombol riwayat membuka lembar riwayat', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: GameScreen(vsAi: false)),
    );
    expect(find.textContaining('Giliran Putih'), findsOneWidget);
    await tester.tap(find.byTooltip('Riwayat'));
    await tester.pumpAndSettle();
    expect(find.text('Riwayat langkah'), findsOneWidget);
  });

  testWidgets('Kartu pemain, undo, dan menu menyerah ada', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: GameScreen(vsAi: false)),
    );
    expect(find.text('Putih'), findsWidgets);
    expect(find.text('Hitam'), findsWidgets);
    expect(find.byTooltip('Urungkan'), findsOneWidget);
    await tester.tap(find.byTooltip('Opsi lain'));
    await tester.pumpAndSettle();
    expect(find.text('Main baru'), findsOneWidget);
    expect(find.text('Putar papan'), findsOneWidget);
    expect(find.text('Menyerah'), findsOneWidget);
  });
}
