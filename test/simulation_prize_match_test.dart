import 'package:expensetracker/models/lottery_simulation.dart';
import 'package:expensetracker/utils/simulation_prize_match.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Super Lotto matches the official seventh-prize combinations', () {
    final ticket = SimulationTicket(
      lottery: SimulationLottery.superLotto,
      primary: [1, 2, 3, 4, 5],
      secondary: [1, 2],
    );

    expect(
      simulationPrizeLabel(
        ticket: ticket,
        primaryDraw: [1, 2, 6, 7, 8],
        secondaryDraw: [1, 9],
      ),
      '七等奖',
    );
    expect(
      simulationPrizeLabel(
        ticket: ticket,
        primaryDraw: [6, 7, 8, 9, 10],
        secondaryDraw: [3, 4],
      ),
      isNull,
    );
  });

  test('复式 tickets match when at least one generated line wins', () {
    final ticket = SimulationTicket(
      lottery: SimulationLottery.doubleColorBall,
      primary: [1, 2, 3, 4, 5, 6, 7],
      secondary: [8],
    );

    expect(
      simulationPrizeLabel(
        ticket: ticket,
        primaryDraw: [1, 2, 3, 4, 9, 10],
        secondaryDraw: [11],
      ),
      '五等奖',
    );
  });

  test('Seven Star requires positional matches and Happy 8 uses its play rule',
      () {
    final sevenStar = SimulationTicket(
      lottery: SimulationLottery.sevenStar,
      primary: [1, 2, 3, 4, 5, 6],
      secondary: [7],
    );
    expect(
      simulationPrizeLabel(
        ticket: sevenStar,
        primaryDraw: [1, 2, 3, 4, 5, 6],
        secondaryDraw: [0],
      ),
      '二等奖',
    );
    expect(
      simulationPrizeLabel(
        ticket: sevenStar,
        primaryDraw: [1, 2, 3, 4, 5, 6],
        secondaryDraw: [7],
      ),
      '一等奖',
    );

    final happyEight = SimulationTicket(
      lottery: SimulationLottery.happyEight,
      primary: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
      happyEightCount: 10,
    );
    expect(
      simulationPrizeLabel(
        ticket: happyEight,
        primaryDraw: [
          1,
          2,
          3,
          4,
          5,
          11,
          12,
          13,
          14,
          15,
          16,
          17,
          18,
          19,
          20,
          21,
          22,
          23,
          24,
          25
        ],
      ),
      '中5个',
    );
    expect(
      simulationPrizeLabel(
        ticket: happyEight,
        primaryDraw: [
          1,
          2,
          3,
          4,
          11,
          12,
          13,
          14,
          15,
          16,
          17,
          18,
          19,
          20,
          21,
          22,
          23,
          24,
          25,
          26
        ],
      ),
      isNull,
    );
  });

  test('Happy 8 compound play matches prizes across generated lines', () {
    final ticket = SimulationTicket(
      lottery: SimulationLottery.happyEight,
      primary: [1, 2, 3, 4, 5, 6, 7, 8],
      happyEightCount: 5,
    );

    expect(
      simulationPrizeLabel(
        ticket: ticket,
        primaryDraw: [
          1,
          2,
          3,
          20,
          21,
          22,
          23,
          24,
          25,
          26,
          27,
          28,
          29,
          30,
          31,
          32,
          33,
          34,
          35,
          36,
        ],
      ),
      '中3个',
    );
  });
}
