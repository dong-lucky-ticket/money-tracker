import 'dart:io';

import 'package:expensetracker/models/lottery_simulation.dart';
import 'package:expensetracker/services/lottery_simulation_repository.dart';
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
    expect(
        SimulationTicket(
          lottery: SimulationLottery.sevenStar,
          primary: [1, 1, 3, 4, 5, 6, 7],
        ).isValid,
        isTrue);
    expect(
        SimulationTicket(
          lottery: SimulationLottery.happyEight,
          primary: List.generate(10, (index) => index + 1),
          happyEightCount: 10,
        ).lines,
        1);
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
}
