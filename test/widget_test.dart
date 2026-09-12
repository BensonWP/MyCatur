import 'package:catur/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Splash pindah ke beranda MyCatur', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyCaturApp());
    expect(find.bySemanticsLabel('Logo MyCatur'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Mulai lawan komputer'), findsOneWidget);
    expect(find.text('Main berdua'), findsOneWidget);
  });
}
