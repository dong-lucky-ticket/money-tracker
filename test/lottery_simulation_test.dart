import 'dart:io';
import 'dart:math';

import 'package:expensetracker/models/lottery_simulation.dart';
import 'package:expensetracker/services/lottery_simulation_repository.dart';
import 'package:expensetracker/widgets/lottery/simulation_ticket_numbers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory =
        await Directory.systemTemp.createTemp('lottery-simulation-');
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test('calculates combination tickets and validates each game format', () {
    expect(simulationCombinations(6, 5), 6);
    expect(
        SimulationTicket(
          lottery: SimulationLottery.superLotto,
          primary: [1, 2, 3, 4, 5, 6],
          secondary: [1, 2, 3],
        ).lines,
        18);
    expect(
        SimulationTicket(
          lottery: SimulationLottery.doubleColorBall,
          primary: [1, 2, 3, 4, 5, 6],
          secondary: [1],
        ).isValid,
        isTrue);
    final sevenStar = SimulationTicket(
      lottery: SimulationLottery.sevenStar,
      primary: [1, 1, 3, 4, 5, 6, 7],
    );
    expect(sevenStar.isValid, isTrue);
    expect(sevenStar.primary, [1, 1, 3, 4, 5, 6]);
    expect(sevenStar.secondary, [7]);
    final restoredLegacySevenStar = SimulationTicket.fromMap({
      'lottery': SimulationLottery.sevenStar.name,
      'primary': [1, 1, 3, 4, 5, 6, 7],
      'secondary': <int>[],
      'happyEightCount': 10,
    });
    expect(restoredLegacySevenStar.primary, [1, 1, 3, 4, 5, 6]);
    expect(restoredLegacySevenStar.secondary, [7]);
    expect(
        SimulationTicket(
          lottery: SimulationLottery.happyEight,
          primary: List.generate(10, (index) => index + 1),
          happyEightCount: 10,
        ).lines,
        1);

    final happyEightCompound = SimulationTicket(
      lottery: SimulationLottery.happyEight,
      primary: List.generate(8, (index) => index + 1),
      happyEightCount: 6,
    );
    expect(happyEightCompound.isValid, isTrue);
    expect(happyEightCompound.lines, 28);
    expect(happyEightCompound.playLabel, '选六复式');

    final randomSevenStar =
        SimulationTicket.random(SimulationLottery.sevenStar, Random(1));
    expect(randomSevenStar.primary, hasLength(6));
    expect(randomSevenStar.secondary, hasLength(1));
  });

  testWidgets(
      'Seven Star ticket numbers display six front digits and one back digit',
      (tester) async {
    final ticket = SimulationTicket(
      lottery: SimulationLottery.sevenStar,
      primary: [1, 2, 3, 4, 5, 6],
      secondary: [7],
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SimulationTicketNumbers(ticket: ticket)),
    ));

    expect(find.text('前区'), findsOneWidget);
    expect(find.text('后区'), findsOneWidget);
    expect(find.text('七位'), findsNothing);
    expect(find.text('7'), findsOneWidget);
  });

  test('stores and restores virtual tickets from the dedicated cache',
      () async {
    final ticket = SimulationTicket(
      lottery: SimulationLottery.superLotto,
      primary: [1, 2, 3, 4, 5],
      secondary: [6, 7],
    );
    final record = SimulationRecord(
      id: 'test-record',
      createdAt: DateTime.utc(2026, 11, 12),
      lottery: SimulationLottery.superLotto,
      tickets: [ticket],
      multiple: 2,
      additional: true,
    );
    final repository = LotterySimulationRepository();

    await repository.save(record);
    final restored = await repository.load();

    expect(restored, hasLength(1));
    expect(restored.single.amount, 6);
    expect(restored.single.tickets.single.primary, [1, 2, 3, 4, 5]);
    expect(restored.single.tickets.single.secondary, [6, 7]);
  });

  test('persists draft tickets separately and updates them immediately',
      () async {
    final ticket = SimulationTicket(
      lottery: SimulationLottery.superLotto,
      primary: [1, 2, 3, 4, 5],
      secondary: [6, 7],
    );
    final repository = LotterySimulationRepository();

    await repository.saveDraftTickets(SimulationLottery.superLotto, [ticket]);
    final restored =
        await repository.loadDraftTickets(SimulationLottery.superLotto);

    expect(restored, hasLength(1));
    expect(restored.single.primary, [1, 2, 3, 4, 5]);
    expect(await repository.load(), isEmpty);

    await repository.saveDraftTickets(SimulationLottery.superLotto, []);
    expect(await repository.loadDraftTickets(SimulationLottery.superLotto),
        isEmpty);
  });

  test('Double Color Ball dan-tuo calculates lines and validates rules', () {
    SimulationTicket danTuo({
      required List<int> dan,
      required List<int> tuo,
      List<int> blue = const [1],
    }) =>
        SimulationTicket(
          lottery: SimulationLottery.doubleColorBall,
          primary: [...dan, ...tuo],
          secondary: blue,
          primaryDan: dan,
          primaryTuo: tuo,
        );

    final valid = danTuo(dan: [1, 2], tuo: [3, 4, 5, 6, 7]);
    expect(valid.isValid, isTrue);
    expect(valid.lines, 5); // C(5, 4) * C(1, 1)
    expect(valid.playLabel, '胆拖');
    expect(valid.primary, [1, 2, 3, 4, 5, 6, 7]);

    // Five dan codes with one tuo code total six red balls, below seven.
    expect(danTuo(dan: [1, 2, 3, 4, 5], tuo: [6]).isValid, isFalse);
    // Dan codes and tuo codes must not overlap.
    expect(danTuo(dan: [1, 2], tuo: [3, 4, 5, 6, 2]).isValid, isFalse);
    // At most five dan codes.
    expect(danTuo(dan: [1, 2, 3, 4, 5, 6], tuo: [7]).isValid, isFalse);

    // Multiple blue balls turn it into a compound dan-tuo bet.
    final compound =
        danTuo(dan: [1], tuo: [2, 3, 4, 5, 6, 7], blue: [8, 9]);
    expect(compound.isValid, isTrue);
    expect(compound.lines, 12); // C(6, 5) * 2
  });

  test('persists and restores dan-tuo tickets', () {
    final ticket = SimulationTicket(
      lottery: SimulationLottery.doubleColorBall,
      primary: [1, 2, 3, 4, 5, 6, 7],
      secondary: [8],
      primaryDan: [1, 2],
      primaryTuo: [3, 4, 5, 6, 7],
    );
    final restored = SimulationTicket.fromMap(ticket.toMap());
    expect(restored.isDanTuo, isTrue);
    expect(restored.primaryDan, [1, 2]);
    expect(restored.primaryTuo, [3, 4, 5, 6, 7]);
    expect(restored.lines, 5);
  });

  testWidgets('Double Color Ball dan-tuo numbers show dan and tuo rows',
      (tester) async {
    final ticket = SimulationTicket(
      lottery: SimulationLottery.doubleColorBall,
      primary: [1, 2, 3, 4, 5, 6, 7],
      secondary: [8],
      primaryDan: [1, 2],
      primaryTuo: [3, 4, 5, 6, 7],
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SimulationTicketNumbers(ticket: ticket)),
    ));

    expect(find.text('红胆'), findsOneWidget);
    expect(find.text('红拖'), findsOneWidget);
    expect(find.text('蓝球'), findsOneWidget);
  });

  test('Double Color Ball dan-tuo random pick stays within dan-tuo rules', () {
    for (var seed = 0; seed < 50; seed++) {
      final ticket = SimulationTicket.danTuoRandom(
          SimulationLottery.doubleColorBall, Random(seed));
      expect(ticket.isDanTuo, isTrue);
      expect(ticket.isValid, isTrue);
      expect(ticket.primaryDan.length, inInclusiveRange(1, 5));
      expect(ticket.primaryDan.length + ticket.primaryTuo.length, 7);
      expect(ticket.secondary, hasLength(1));
      expect(ticket.lines, greaterThan(0));
    }
  });

  test('Super Lotto dan-tuo rules for front, back and dual zones', () {
    SimulationTicket superLottoDanTuo({
      List<int> frontDan = const [],
      List<int> frontTuo = const [],
      List<int> front = const [1, 2, 3, 4, 5],
      List<int> backDan = const [],
      List<int> backTuo = const [],
      List<int> back = const [1, 2],
    }) =>
        SimulationTicket(
          lottery: SimulationLottery.superLotto,
          primary: (frontDan.isNotEmpty || frontTuo.isNotEmpty)
              ? [...frontDan, ...frontTuo]
              : front,
          secondary: (backDan.isNotEmpty || backTuo.isNotEmpty)
              ? [...backDan, ...backTuo]
              : back,
          primaryDan: frontDan,
          primaryTuo: frontTuo,
          secondaryDan: backDan,
          secondaryTuo: backTuo,
        );

    final front = superLottoDanTuo(
        frontDan: [1, 2], frontTuo: [3, 4, 5, 6]);
    expect(front.isValid, isTrue);
    expect(front.playLabel, '胆拖');
    expect(front.isPrimaryDanTuo, isTrue);
    expect(front.isSecondaryDanTuo, isFalse);
    expect(front.lines, 4); // C(4, 3) * C(2, 2)

    // Front dan codes must be 1-4 and the front total must reach six.
    expect(
        superLottoDanTuo(frontDan: [1, 2, 3, 4], frontTuo: [5]).isValid,
        isFalse);
    expect(
        superLottoDanTuo(
                frontDan: [1, 2, 3, 4, 5], frontTuo: [6])
            .isValid,
        isFalse);

    final back = superLottoDanTuo(
        backDan: [1], backTuo: [2, 3], back: const [1, 2]);
    expect(back.isValid, isTrue);
    expect(back.isPrimaryDanTuo, isFalse);
    expect(back.isSecondaryDanTuo, isTrue);
    expect(back.lines, 2); // C(5, 5) * C(2, 1)

    final dual = superLottoDanTuo(
        frontDan: [1],
        frontTuo: [2, 3, 4, 5, 6],
        backDan: [1],
        backTuo: [2, 3],
        back: const [1, 2]);
    expect(dual.isValid, isTrue);
    expect(dual.lines, 10); // C(5, 4) * C(2, 1)
  });

  test('Super Lotto dan-tuo random picks match each zone mode', () {
    for (var seed = 0; seed < 30; seed++) {
      final frontOnly = SimulationTicket.danTuoRandom(
          SimulationLottery.superLotto, Random(seed),
          front: true, back: false);
      expect(frontOnly.isValid, isTrue);
      expect(frontOnly.isPrimaryDanTuo, isTrue);
      expect(frontOnly.isSecondaryDanTuo, isFalse);
      expect(frontOnly.primaryDan.length, inInclusiveRange(1, 4));
      expect(frontOnly.primaryDan.length + frontOnly.primaryTuo.length, 6);
      expect(frontOnly.secondary, hasLength(2));

      final backOnly = SimulationTicket.danTuoRandom(
          SimulationLottery.superLotto, Random(seed),
          front: false, back: true);
      expect(backOnly.isValid, isTrue);
      expect(backOnly.isPrimaryDanTuo, isFalse);
      expect(backOnly.isSecondaryDanTuo, isTrue);
      expect(backOnly.primary, hasLength(5));
      expect(backOnly.secondaryDan, hasLength(1));
      expect(backOnly.secondaryTuo, hasLength(2));
    }
  });
}
