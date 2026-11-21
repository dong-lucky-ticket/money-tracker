import 'dart:io';

import 'package:expensetracker/models/lottery_simulation.dart';
import 'package:expensetracker/models/seven_star_draw.dart';
import 'package:expensetracker/screens/historical_match_sheet.dart';
import 'package:expensetracker/services/seven_star_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('seven-star-match-');
    Hive.init(hiveDirectory.path);
    Hive.registerAdapter(SevenStarDrawAdapter());
    Hive.registerAdapter(SevenStarPrizeTierAdapter());
    await SevenStarRepository().saveAll([
      SevenStarDraw(
        issue: '26116',
        publishDate: DateTime(2026, 10, 11),
        numbers: const ['1', '2', '3', '4', '5', '6', '7'],
        announcementUrl: 'https://example.com/draw',
      ),
    ]);
  });

  tearDown(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  testWidgets('Seven Star historical match shows all seven balls on one row',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final ticket = SimulationTicket(
      lottery: SimulationLottery.sevenStar,
      primary: [1, 2, 3, 4, 5, 6],
      secondary: [7],
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: HistoricalMatchSheet(ticket: ticket)),
    ));
    await tester.pumpAndSettle();

    expect(find.text('前区'), findsNothing);
    expect(find.text('后区'), findsNothing);
    final balls = find.byWidgetPredicate((widget) =>
        widget is Container &&
        widget.decoration is BoxDecoration &&
        (widget.decoration as BoxDecoration).shape == BoxShape.circle);
    expect(balls, findsNWidgets(14));
    expect(find.text('一等奖'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
