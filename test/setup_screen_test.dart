import 'package:catur/chess/app_prefs.dart';
import 'package:catur/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Tombol lawan komputer membuka sheet lalu mulai', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(home: HomeScreen()),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.text('Lawan Komputer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lawan Komputer'));
    await tester.pumpAndSettle();
    expect(find.text('Warna kamu'), findsOneWidget);
    expect(find.text('Tingkat komputer'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
    await tester.ensureVisible(find.text('Mulai lawan komputer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mulai lawan komputer'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Giliran Putih'), findsOneWidget);
    expect(await AppPrefs.loadPlayMode(), PlayMode.ai);
  });

  testWidgets('Sheet berdua tanpa opsi AI lalu mulai', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(home: HomeScreen()),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.text('Main Berdua'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Main Berdua'));
    await tester.pumpAndSettle();
    expect(find.text('Warna kamu'), findsNothing);
    expect(find.text('Tingkat komputer'), findsNothing);
    await tester.ensureVisible(find.text('Mulai main berdua'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mulai main berdua'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Giliran Putih'), findsOneWidget);
    expect(await AppPrefs.loadPlayMode(), PlayMode.duo);
  });

  testWidgets('Batal menutup sheet tanpa mulai', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(home: HomeScreen()),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.text('Main Berdua'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Main Berdua'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Batal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.text('Mulai main berdua'), findsNothing);
    expect(find.text('Main Berdua'), findsOneWidget);
  });

  testWidgets('Mode terakhir round-trip lewat prefs', (
    WidgetTester tester,
  ) async {
    await AppPrefs.savePlayMode(PlayMode.duo);
    expect(await AppPrefs.loadPlayMode(), PlayMode.duo);
    await AppPrefs.savePlayMode(PlayMode.ai);
    expect(await AppPrefs.loadPlayMode(), PlayMode.ai);
  });
}
