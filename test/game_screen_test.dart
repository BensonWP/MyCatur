import 'package:catur/screens/game_screen.dart';
import 'package:catur/widgets/animated_board_widget.dart';
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

  testWidgets('Menu memuat pengaturan, baru, putar, menyerah', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: GameScreen(vsAi: false)),
    );
    await tester.tap(find.byTooltip('Opsi lain'));
    await tester.pumpAndSettle();
    expect(find.text('Pengaturan'), findsOneWidget);
    expect(find.text('Main baru'), findsOneWidget);
    expect(find.text('Putar papan'), findsOneWidget);
    expect(find.text('Menyerah'), findsOneWidget);
  });

  testWidgets('Pengaturan dibuka lewat menu', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: GameScreen(vsAi: false)),
    );
    await tester.tap(find.byTooltip('Opsi lain'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pengaturan'));
    await tester.pumpAndSettle();
    expect(find.text('Tempo'), findsOneWidget);
    expect(find.text('Animasi langkah'), findsOneWidget);
    expect(find.text('Tutup'), findsOneWidget);
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();
    expect(find.text('Riwayat langkah'), findsNothing);
  });
  testWidgets('Papan selebar layar di HP portrait 360', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      const MaterialApp(home: GameScreen(vsAi: false)),
    );
    await tester.pumpAndSettle();
    final size = tester.getSize(find.byType(AnimatedBoardWidget));
    expect(size.width, greaterThanOrEqualTo(350));
    expect(size.width, size.height);
  });

  testWidgets('Tangkapan e4 d5 exd5 tampil +1 di strip Putih', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      const MaterialApp(home: GameScreen(vsAi: false)),
    );
    await tester.pumpAndSettle();
    final board = tester.getRect(find.byType(AnimatedBoardWidget));
    final inner = board.deflate(12);
    final sq = inner.width / 8;
    Future<void> tapSquare(int r, int c) async {
      await tester.tapAt(Offset(
        inner.left + (c + 0.5) * sq,
        inner.top + (r + 0.5) * sq,
      ));
      await tester.pump();
    }

    await tapSquare(6, 4); // e2
    await tapSquare(4, 4); // e4
    await tapSquare(1, 3); // d7
    await tapSquare(3, 3); // d5
    await tapSquare(4, 4); // e4
    await tapSquare(3, 3); // exd5, makan pion
    await tester.pumpAndSettle();
    expect(find.textContaining('Giliran Hitam'), findsOneWidget);
    expect(find.textContaining('+1'), findsOneWidget);
  });
}
