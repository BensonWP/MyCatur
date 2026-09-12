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
}
