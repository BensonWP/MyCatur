import 'package:catur/chess/ai.dart';
import 'package:catur/chess/piece.dart';
import 'package:catur/chess/stats_store.dart';
import 'package:catur/screens/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Statistik tercatat dan dibaca', () async {
    SharedPreferences.setMockInitialValues({});
    final store = StatsStore();
    await store.load();
    expect(store.isEmpty, true);
    await store.recordAi(level: AiLevel.easy, humanScore: 1);
    await store.recordAi(level: AiLevel.easy, humanScore: 0);
    await store.recordTwoPlayer(winner: PieceColor.white);
    expect(store.aiWin(AiLevel.easy), 1);
    expect(store.aiDraw(AiLevel.easy), 1);
    expect(store.twoWhite, 1);
    expect(store.isEmpty, false);
  });

  testWidgets('Navigasi 4 halaman hidup', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(home: MainShell()),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Cara Main'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Gerak bidak.'), findsOneWidget);
    await tester.tap(find.text('Statistik'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Catatan di HP ini.'), findsOneWidget);
    await tester.tap(find.text('Tentang'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Dibuat dengan Flutter.'), findsOneWidget);
  });
}
