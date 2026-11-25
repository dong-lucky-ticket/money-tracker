import 'dart:io';

import 'package:expensetracker/screens/betting_simulator_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('simulator-screen-');
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

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
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
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
      await tester.tap(find.text('已选 (0)'));
      await tester.pumpAndSettle();
      final actionsWithNewSelection = find
          .byWidgetPredicate(
            (widget) =>
                widget is ListView && widget.scrollDirection == Axis.horizontal,
          )
          .last;
      await tester.drag(actionsWithNewSelection, const Offset(-400, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+继续选号'));
      await tester.pumpAndSettle();
      expect(find.text('已选 1注，共2元', findRichText: true), findsOneWidget);
      await tester.tap(find.text('选好了'));
      await tester.pumpAndSettle();
      expect(find.text('双色球明细'), findsOneWidget);
      final confirmButton = find.ancestor(
        of: find.text('保存记录'),
        matching: find.byType(FilledButton),
      );
      expect(tester.getSize(confirmButton).height, 48);
      for (final label in ['+机选1注', '+机选5注', '+机选10注']) {
        final button = find.ancestor(
          of: find.text(label),
          matching: find.byType(OutlinedButton),
        );
        expect(tester.getSize(button).height, 32);
      }
      final actionButtons = find
          .byWidgetPredicate(
            (widget) =>
                widget is ListView && widget.scrollDirection == Axis.horizontal,
          )
          .last;
      await tester.drag(actionButtons, const Offset(-400, 0));
      await tester.pumpAndSettle();
      final continueButton = find.ancestor(
        of: find.text('+继续选号'),
        matching: find.byType(TextButton),
      );
      expect(tester.getSize(continueButton).height, 32);
      await tester.drag(actionButtons, const Offset(400, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('+机选1注'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('编辑号码'), findsNWidgets(2));
      expect(find.byTooltip('删除此项'), findsNWidgets(2));

      await tester.tap(find.byKey(const ValueKey('ticket-content-1')));
      await tester.pumpAndSettle();
      expect(find.text('已选 (2)'), findsOneWidget);
      expect(find.text('保存修改'), findsOneWidget);

      await tester.tap(find.text('已选 (2)'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('编辑号码'), findsNWidgets(2));
      await tester.tap(find.byTooltip('编辑号码').at(1));
      await tester.pumpAndSettle();
      expect(find.text('保存修改'), findsOneWidget);

      await tester.tap(find.text('保存修改'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('编辑号码'), findsNWidgets(2));

      await tester.tap(find.byTooltip('编辑号码').at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('已选 (2)'));
      await tester.pumpAndSettle();
      final actionsAfterEdit = find
          .byWidgetPredicate(
            (widget) =>
                widget is ListView && widget.scrollDirection == Axis.horizontal,
          )
          .last;
      await tester.drag(actionsAfterEdit, const Offset(-400, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+继续选号'));
      await tester.pumpAndSettle();
      expect(find.text('已选 0注，共0元', findRichText: true), findsOneWidget);

      await tester.tap(find.text('游戏规则'));
      await tester.pumpAndSettle();
      expect(find.text('福彩双色球中奖规则'), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Happy 8 selection above the chosen play counts as a compound bet',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(
      home: BettingSimulatorScreen(),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('快乐8'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('选五玩法').last);
    await tester.pumpAndSettle();

    for (var number = 1; number <= 6; number++) {
      final picker = find.byKey(ValueKey('pick-happyEight-$number'));
      await tester.ensureVisible(picker);
      await tester.tap(picker);
      await tester.pump();
    }

    expect(find.text('已选 6注，共12元', findRichText: true), findsOneWidget);
    await tester.tap(find.text('选好了'));
    await tester.pumpAndSettle();
    expect(find.text('选五复式'), findsOneWidget);
    expect(find.text('选五'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Double Color Ball dan-tuo builds a valid dan-tuo ticket',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(
      home: BettingSimulatorScreen(),
    ));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('双色球'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<bool>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('胆拖投注').last);
    await tester.pumpAndSettle();

    for (final number in [1, 2]) {
      final danBall = find.byKey(ValueKey('pick-doubleColorBall-dan-$number'));
      await tester.ensureVisible(danBall);
      await tester.tap(danBall);
      await tester.pump();
    }

    for (final number in [3, 4, 5, 6, 7, 8]) {
      final tuoBall = find.byKey(ValueKey('pick-doubleColorBall-tuo-$number'));
      await tester.ensureVisible(tuoBall);
      await tester.tap(tuoBall);
      await tester.pump();
    }

    final blueBall = find.byKey(const ValueKey('pick-doubleColorBall-blue-8'));
    await tester.ensureVisible(blueBall);
    await tester.tap(blueBall);
    await tester.pumpAndSettle();

    // dan 1-2, tuo 3-8 (six tuo codes) => C(6, 4) = 15 lines, 30 yuan.
    expect(find.text('已选 15注，共30元', findRichText: true), findsOneWidget);

    await tester.tap(find.text('选好了'));
    await tester.pumpAndSettle();

    expect(find.text('胆拖'), findsOneWidget);
    expect(find.text('红胆'), findsOneWidget);
    expect(find.text('红拖'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Double Color Ball machine pick keeps dan-tuo mode',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(
      home: BettingSimulatorScreen(),
    ));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('双色球'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<bool>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('胆拖投注').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('机选'));
    await tester.pumpAndSettle();

    expect(find.text('胆拖投注'), findsOneWidget);
    expect(find.text('基本投注'), findsNothing);
    expect(find.text('红球胆码'), findsOneWidget);
    expect(find.text('红球拖码'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Seven Star selection preserves the front six and back one',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(
      home: BettingSimulatorScreen(),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('七星彩'));
    await tester.pumpAndSettle();

    for (var position = 0; position < 7; position++) {
      final picker =
          find.byKey(ValueKey('digit-picker-$position-${position + 1}'));
      await tester.ensureVisible(picker);
      await tester.tap(picker);
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('选好了'));
    await tester.pumpAndSettle();
    expect(find.text('前区'), findsOneWidget);
    expect(find.text('后区'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
