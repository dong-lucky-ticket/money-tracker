import 'package:expensetracker/models/seven_star_draw.dart';
import 'package:expensetracker/screens/seven_star_screen.dart';
import 'package:expensetracker/theme/app_colors.dart';
import 'package:expensetracker/widgets/common/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('seven star announcement matches the existing pages',
      (tester) async {
    const announcementUrl = 'https://pdf.sporttery.cn/17100/26116/26116.pdf';
    String? copiedUrl;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedUrl = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
      AppToast.dismiss();
    });
    final draw = SevenStarDraw(
      issue: '26116',
      publishDate: DateTime(2026, 10, 11),
      numbers: const ['0', '1', '2', '3', '4', '5', '6'],
      announcementUrl: announcementUrl,
      prizeTiers: const [
        SevenStarPrizeTier(
          level: '一等奖',
          betCount: '123注',
          singlePrize: '99元',
          totalPrize: '12345元',
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp(
      home: SevenStarAnnouncementScreen(draw: draw),
    ));

    expect(find.text('第26116期开奖公告'), findsOneWidget);
    expect(find.text('第26116期开奖详情'), findsNothing);
    final prizeTable = tester.widget<Table>(find.byType(Table));
    expect(prizeTable.children.first.children.length, 4);
    expect(prizeTable.border!.top.color, AppColors.border);
    expect(prizeTable.children.first.decoration,
        const BoxDecoration(color: AppColors.surfaceMuted));
    expect(find.text('中奖注数'), findsOneWidget);
    expect(find.text('应派奖金合计'), findsOneWidget);
    expect(find.text('12345元'), findsOneWidget);
    expect(find.text('公告链接'), findsOneWidget);
    expect(find.text(announcementUrl), findsOneWidget);

    for (final number in draw.numbers) {
      final numberText = find.text(number);
      expect(numberText, findsOneWidget);
      expect(tester.widget<Text>(numberText).style!.fontSize, isNull);

      final ball = find.ancestor(
        of: numberText,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).shape == BoxShape.circle,
        ),
      );
      expect(ball, findsOneWidget);
      expect(tester.widget<Container>(ball).constraints!.maxWidth, 34);
      expect(tester.widget<Container>(ball).constraints!.maxHeight, 34);
    }

    await tester.tap(find.text(announcementUrl));
    await tester.pump();
    expect(copiedUrl, announcementUrl);
    AppToast.dismiss();
    await tester.pump();
  });
}
