import 'package:expensetracker/screens/lottery_rules_screen.dart';
import 'package:expensetracker/widgets/lottery/prize_rules_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Qilecai rules show the official prize schedule and source',
      (tester) async {
    final layoutErrors = <FlutterErrorDetails>[];
    final previousErrorHandler = FlutterError.onError;
    FlutterError.onError = layoutErrors.add;
    addTearDown(() => FlutterError.onError = previousErrorHandler);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    for (final width in [320.0, 390.0]) {
      tester.view.physicalSize = Size(width, 800);
      await tester.pumpWidget(const MaterialApp(
        home: LotteryRulesScreen(lotteryType: '福彩七乐彩'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('福彩七乐彩中奖规则'), findsOneWidget);
      expect(find.text('奖级与中奖条件'), findsOneWidget);
      expect(find.byType(PrizeRulesTable), findsOneWidget);
      expect(find.text('单注奖金'), findsOneWidget);
      expect(find.text('5元'), findsOneWidget);
      expect(
          find.text('https://www.cwl.gov.cn/fcpz/yxjs/qlc/'), findsOneWidget);
    }

    expect(layoutErrors, isEmpty,
        reason: layoutErrors.map((error) => error.toString()).join('\n'));
    expect(tester.takeException(), isNull);
  });
}