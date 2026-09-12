import 'package:catur/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Splash ke peluncur lalu mulai dari sheet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyCaturApp());
    expect(find.bySemanticsLabel('Logo MyCatur'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Lawan Komputer'), findsOneWidget);
    expect(find.text('Main Berdua'), findsOneWidget);
    await tester.ensureVisible(find.text('Lawan Komputer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lawan Komputer'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Mulai lawan komputer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mulai lawan komputer'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Giliran Putih'), findsOneWidget);
  });
}
