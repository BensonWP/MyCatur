import 'package:catur/chess/ai.dart';
import 'package:catur/chess/piece.dart';
import 'package:catur/chess/stats_store.dart';
import 'package:catur/screens/home_screen.dart';
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

  testWidgets('Hanya halaman peluncur tanpa navbar', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(home: HomeScreen()),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Lawan Komputer'), findsOneWidget);
    expect(find.text('Main Berdua'), findsOneWidget);
    expect(find.byTooltip('Pengaturan'), findsOneWidget);
    expect(find.text('Cara Main'), findsNothing);
    expect(find.text('Statistik'), findsNothing);
    expect(find.text('Tentang'), findsNothing);
  });
}
