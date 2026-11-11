import 'package:am_lich/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app({DateTime? date}) => CalendarApp(
    lunarPrimary: true,
    saveMode: (_) async {},
    clock: () => date ?? DateTime.utc(2024, 2, 10, 5),
  );

  testWidgets('home shows lunar day and month toggles keep selected date', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    expect(find.text('01'), findsOneWidget);
    expect(find.text('THÁNG 1 · 2024'), findsOneWidget);
    expect(find.text('10/02/2024'), findsOneWidget);

    await tester.tap(find.text('Lịch tháng'));
    await tester.pumpAndSettle();
    expect(find.text('Tháng 1 · 2024'), findsOneWidget);

    await tester.tap(find.text('Dương lịch'));
    await tester.pumpAndSettle();
    expect(find.text('Tháng 2 · 2024'), findsOneWidget);

    await tester.tap(find.byTooltip('Sau'));
    await tester.pumpAndSettle();
    expect(find.text('Tháng 3 · 2024'), findsOneWidget);

    await tester.tap(find.text('Hôm nay'));
    await tester.pumpAndSettle();
    expect(find.text('Tháng 2 · 2024'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('calendar supports small, large text and tablet viewports', (
    tester,
  ) async {
    for (final size in [const Size(320, 568), const Size(834, 1194)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: app(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Lịch tháng'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
  });
}
