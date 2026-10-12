import 'package:expensetracker/screens/double_color_ball_screen.dart';
import 'package:expensetracker/screens/lottery_screen.dart';
import 'package:expensetracker/screens/seven_star_screen.dart';
import 'package:expensetracker/widgets/settings/lottery_management_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('lottery entries open their pages directly', (tester) async {
    final openedPages = <Widget>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LotteryManagementSection(
            onOpenPage: (page) async => openedPages.add(page),
          ),
        ),
      ),
    );

    for (final (label, pageType) in [
      ('体彩大乐透', LotteryScreen),
      ('体彩七星彩', SevenStarScreen),
      ('福彩双色球', DoubleColorBallScreen),
    ]) {
      await tester.tap(find.text(label));
      await tester.pump();
      expect(openedPages.last.runtimeType, pageType);
    }
  });
}
