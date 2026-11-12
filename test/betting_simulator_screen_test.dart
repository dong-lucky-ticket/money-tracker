import 'package:expensetracker/screens/betting_simulator_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('switches lottery pickers, adds a random ticket and opens rules',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final width in [320.0, 390.0]) {
      tester.view.physicalSize = Size(width, 844);
      await tester.pumpWidget(MaterialApp(
        key: ValueKey(width),
        home: const BettingSimulatorScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('体彩大乐透'), findsNothing);
      expect(find.text('前区'), findsOneWidget);
      await tester.tap(find.text('双色球'));
      await tester.pumpAndSettle();
      expect(find.text('红球'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('蓝球'), 180,
          scrollable: find.byType(Scrollable).last);
      expect(find.text('蓝球'), findsOneWidget);
      await tester.drag(find.byType(ListView).last, const Offset(0, 900));
      await tester.pumpAndSettle();

      await tester.tap(find.text('机选'));
      await tester.pump();
      expect(find.text('已选 1注，共2元', findRichText: true), findsOneWidget);
      await tester.tap(find.text('选好了'));
      await tester.pumpAndSettle();
      expect(find.text('双色球明细'), findsOneWidget);

      await tester.tap(find.byTooltip('关闭明细'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('游戏规则'));
      await tester.pumpAndSettle();
      expect(find.text('福彩双色球中奖规则'), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}
