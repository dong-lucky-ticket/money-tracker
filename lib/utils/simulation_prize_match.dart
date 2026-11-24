import '../models/lottery_simulation.dart';

/// Returns the best prize tier reached by a ticket for one draw.
String? simulationPrizeLabel({
  required SimulationTicket ticket,
  required List<int> primaryDraw,
  List<int> secondaryDraw = const [],
}) {
  if (ticket.lottery == SimulationLottery.happyEight) {
    final hits =
        ticket.primary.toSet().intersection(primaryDraw.toSet()).length;
    final minHits = (ticket.happyEightCount - (ticket.primary.length - hits))
        .clamp(0, ticket.happyEightCount)
        .toInt();
    final maxHits = hits.clamp(0, ticket.happyEightCount).toInt();
    for (var lineHits = maxHits; lineHits >= minHits; lineHits--) {
      final prize = _happyEightPrize(ticket.happyEightCount, lineHits);
      if (prize != null) return prize;
    }
    return null;
  }

  if (ticket.lottery == SimulationLottery.qilecai) {
    if (!ticket.isValid || primaryDraw.length < 7 || secondaryDraw.isEmpty) {
      return null;
    }
    final baseHits = ticket.primary
        .toSet()
        .intersection(primaryDraw.take(7).toSet())
        .length;
    final specialHit = ticket.primary.contains(secondaryDraw.single) ? 1 : 0;
    final frontCounts = _possibleHits(
        ticket.primary.length, baseHits, ticket.lottery.primaryCount);
    const tiers = [
      [
        [7, 0]
      ],
      [
        [6, 1]
      ],
      [
        [6, 0]
      ],
      [
        [5, 1]
      ],
      [
        [5, 0]
      ],
      [
        [4, 1]
      ],
      [
        [4, 0]
      ],
    ];
    final tier = _tierIndex(
        tiers,
        (condition) =>
            frontCounts.contains(condition[0]) &&
            (condition[1] == 1 ? specialHit == 1 : specialHit == 0));
    return _tierLabel(tier);
  }
  if (ticket.lottery == SimulationLottery.sevenStar) {
    final drawnBackDigit = secondaryDraw.isNotEmpty
        ? secondaryDraw.first
        : primaryDraw.length > 6
            ? primaryDraw[6]
            : null;
    if (!ticket.isValid || primaryDraw.length < 6 || drawnBackDigit == null) {
      return null;
    }
    final frontHits = List.generate(6, (index) => index)
        .where((index) => ticket.primary[index] == primaryDraw[index])
        .length;
    final backHits = ticket.secondary.single == drawnBackDigit ? 1 : 0;
    const tiers = [
      [
        [6, 1]
      ],
      [
        [6, 0]
      ],
      [
        [5, 1]
      ],
      [
        [5, 0],
        [4, 1]
      ],
      [
        [4, 0],
        [3, 1]
      ],
      [
        [3, 0],
        [2, 1],
        [1, 1],
        [0, 1]
      ],
    ];
    final tier = _tierIndex(tiers,
        (condition) => frontHits == condition[0] && backHits == condition[1]);
    return _tierLabel(tier);
  }

  final frontHits =
      ticket.primary.toSet().intersection(primaryDraw.toSet()).length;
  final backHits =
      ticket.secondary.toSet().intersection(secondaryDraw.toSet()).length;
  final frontCounts = _possibleHits(
      ticket.primary.length, frontHits, ticket.lottery.primaryCount);
  final backCounts = _possibleHits(
      ticket.secondary.length, backHits, ticket.lottery.secondaryCount);

  if (ticket.lottery == SimulationLottery.superLotto) {
    const tiers = [
      [
        [5, 2]
      ],
      [
        [5, 1]
      ],
      [
        [5, 0],
        [4, 2]
      ],
      [
        [4, 1]
      ],
      [
        [4, 0],
        [3, 2]
      ],
      [
        [3, 1],
        [2, 2]
      ],
      [
        [3, 0],
        [2, 1],
        [1, 2],
        [0, 2]
      ],
    ];
    final tier = _tierIndex(
        tiers,
        (condition) =>
            frontCounts.contains(condition[0]) &&
            backCounts.contains(condition[1]));
    return _tierLabel(tier);
  }

  const tiers = [
    [
      [6, 1]
    ],
    [
      [6, 0]
    ],
    [
      [5, 1]
    ],
    [
      [5, 0],
      [4, 1]
    ],
    [
      [4, 0],
      [3, 1]
    ],
    [
      [2, 1],
      [1, 1],
      [0, 1]
    ],
  ];
  final tier = _tierIndex(
      tiers,
      (condition) =>
          frontCounts.contains(condition[0]) &&
          backCounts.contains(condition[1]));
  return _tierLabel(tier);
}

String? _tierLabel(int? tier) => tier == null
    ? null
    : '${const ['', '一', '二', '三', '四', '五', '六', '七'][tier]}等奖';

Set<int> _possibleHits(int selectedCount, int selectedHits, int lineSize) {
  final selectedMisses = selectedCount - selectedHits;
  return {
    for (var hits = 0; hits <= lineSize; hits++)
      if (hits <= selectedHits && lineSize - hits <= selectedMisses) hits,
  };
}

int? _tierIndex(List<List<List<int>>> tiers, bool Function(List<int>) matches) {
  for (var index = 0; index < tiers.length; index++) {
    if (tiers[index].any(matches)) return index + 1;
  }
  return null;
}

String? _happyEightPrize(int count, int hits) {
  const winningHits = <int, Map<int, int>>{
    10: {10: 1, 9: 2, 8: 3, 7: 4, 6: 5, 5: 6, 0: 7},
    9: {9: 1, 8: 2, 7: 3, 6: 4, 5: 5, 4: 6, 0: 7},
    8: {8: 1, 7: 2, 6: 3, 5: 4, 4: 5, 0: 6},
    7: {7: 1, 6: 2, 5: 3, 4: 4, 0: 5},
    6: {6: 1, 5: 2, 4: 3, 3: 4},
    5: {5: 1, 4: 2, 3: 3},
    4: {4: 1, 3: 2, 2: 3},
    3: {3: 1, 2: 2},
    2: {2: 1},
    1: {1: 1},
  };
  final tiers = winningHits[count];
  final tier = tiers?[hits];
  return tier == null ? null : '中$hits个';
}
