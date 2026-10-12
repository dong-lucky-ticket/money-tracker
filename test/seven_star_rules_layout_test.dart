import 'package:expensetracker/screens/lottery_rules_screen.dart';
import 'package:expensetracker/theme/app_colors.dart';
import 'package:expensetracker/widgets/lottery/prize_rules_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'all prize rules retain the original table layout without overflow',
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
      for (final lotteryType in ['体彩大乐透', '福彩双色球', '体彩七星彩']) {
        await tester.pumpWidget(
          MaterialApp(home: LotteryRulesScreen(lotteryType: lotteryType)),
        );
        await tester.pumpAndSettle();

        expect(find.byType(PrizeRulesTable), findsOneWidget);
        expect(find.text('中奖条件'), findsOneWidget);
        final ruleTable = find.byType(PrizeRulesTable);
        final tables = tester
            .widgetList<Table>(
              find.descendant(of: ruleTable, matching: find.byType(Table)),
            )
            .toList();
        final mainTable = tables.first;
        expect(mainTable.defaultColumnWidth, isA<IntrinsicColumnWidth>());
        expect(mainTable.border!.top.color, AppColors.border);
        expect(mainTable.children.first.decoration,
            const BoxDecoration(color: AppColors.surfaceMuted));
        expect(mainTable.children.first.children.length,
            lotteryType == '体彩大乐透' ? 4 : 3);
        expect(find.descendant(of: ruleTable, matching: find.text('前区')),
            findsNothing);
        expect(find.descendant(of: ruleTable, matching: find.text('后区')),
            findsNothing);
        expect(find.descendant(of: ruleTable, matching: find.text('红球')),
            findsNothing);
        expect(find.descendant(of: ruleTable, matching: find.text('蓝球')),
            findsNothing);

        final firstCondition = find.byWidget(mainTable.children[1].children[1]);
        Finder ballsWithColor(Color color) => find.descendant(
              of: firstCondition,
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Container &&
                    widget.decoration is BoxDecoration &&
                    (widget.decoration as BoxDecoration).shape ==
                        BoxShape.circle &&
                    (widget.decoration as BoxDecoration).color == color,
              ),
            );
        expect(ballsWithColor(AppColors.danger),
            findsNWidgets(lotteryType == '体彩大乐透' ? 5 : 6));
        expect(ballsWithColor(AppColors.primary),
            findsNWidgets(lotteryType == '体彩大乐透' ? 2 : 1));

        if (lotteryType == '体彩大乐透') {
          expect(mainTable.children.length, 8);
          expect(find.text('体彩大乐透中奖规则'), findsOneWidget);
          expect(find.text('体彩大乐透'), findsOneWidget);
          expect(find.text('奖池8亿以下'), findsOneWidget);
          expect(find.text('奖池8亿及以上'), findsOneWidget);
          expect(find.text('6666元'), findsOneWidget);
        } else if (lotteryType == '体彩七星彩') {
          expect(mainTable.children.length, 7);
          expect(find.text('体彩七星彩中奖规则'), findsOneWidget);
          expect(find.text('体彩七星彩'), findsOneWidget);
          expect(find.text('最高可中\n500万元'), findsOneWidget);
          final fourthTierCondition = mainTable.children[4].children[1];
          final alternatives = tester.widget<Table>(find.descendant(
            of: find.byWidget(fourthTierCondition),
            matching: find.byType(Table),
          ));
          expect(alternatives.children.length, 2);
        } else {
          expect(mainTable.children.length, 8);
          expect(find.text('福彩双色球中奖规则'), findsOneWidget);
          expect(find.text('福彩双色球'), findsOneWidget);
        }
      }
    }
    expect(layoutErrors, isEmpty,
        reason: layoutErrors.map((error) => error.toString()).join('\n'));
    expect(tester.takeException(), isNull);
  });
}
