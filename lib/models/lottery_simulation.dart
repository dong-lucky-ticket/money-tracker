import 'dart:math';

enum SimulationLottery { superLotto, doubleColorBall, sevenStar, happyEight }

extension SimulationLotteryInfo on SimulationLottery {
  String get label => const ['体彩大乐透', '福彩双色球', '体彩七星彩', '福彩快乐8'][index];
  String get shortLabel => const ['大乐透', '双色球', '七星彩', '快乐8'][index];
  int get primaryMax => const [35, 33, 10, 80][index];
  int get primaryCount => const [5, 6, 7, 10][index];
  int get secondaryMax => const [12, 16, 0, 0][index];
  int get secondaryCount => const [2, 1, 0, 0][index];
  String get primaryLabel => this == SimulationLottery.doubleColorBall
      ? '红球'
      : this == SimulationLottery.happyEight
          ? '号码'
          : this == SimulationLottery.sevenStar
              ? '前区6位'
              : '前区';
  String get secondaryLabel =>
      this == SimulationLottery.doubleColorBall ? '蓝球' : '后区';
}

int simulationCombinations(int n, int k) {
  if (n < k || k < 0) return 0;
  var result = 1;
  for (var i = 1; i <= k; i++) {
    result = result * (n - i + 1) ~/ i;
  }
  return result;
}

String happyEightPlayLabel(int count) =>
    '选${const ['一', '二', '三', '四', '五', '六', '七', '八', '九', '十'][count - 1]}';

class SimulationTicket {
  final SimulationLottery lottery;
  final List<int> primary;
  final List<int> secondary;
  final int happyEightCount;

  SimulationTicket({
    required this.lottery,
    required List<int> primary,
    List<int> secondary = const [],
    this.happyEightCount = 10,
  })  : primary = List.unmodifiable(lottery == SimulationLottery.sevenStar
            ? primary
            : (List<int>.of(primary)..sort())),
        secondary = List.unmodifiable(List<int>.of(secondary)..sort());

  bool get isValid {
    if (lottery == SimulationLottery.sevenStar) {
      return primary.length == 7 &&
          primary.every((n) => n >= 0 && n <= 9) &&
          secondary.isEmpty;
    }
    if (primary.toSet().length != primary.length ||
        primary.any((n) => n < 1 || n > lottery.primaryMax)) return false;
    if (lottery == SimulationLottery.happyEight) {
      return happyEightCount >= 1 &&
          happyEightCount <= 10 &&
          primary.length >= happyEightCount &&
          secondary.isEmpty;
    }
    return primary.length >= lottery.primaryCount &&
        secondary.length >= lottery.secondaryCount &&
        secondary.toSet().length == secondary.length &&
        secondary.every((n) => n >= 1 && n <= lottery.secondaryMax);
  }

  int get lines {
    if (!isValid) return 0;
    if (lottery == SimulationLottery.sevenStar) return 1;
    if (lottery == SimulationLottery.happyEight) {
      return simulationCombinations(primary.length, happyEightCount);
    }
    return simulationCombinations(primary.length, lottery.primaryCount) *
        simulationCombinations(secondary.length, lottery.secondaryCount);
  }

  String get playLabel => lottery == SimulationLottery.happyEight
      ? '${happyEightPlayLabel(happyEightCount)}${primary.length > happyEightCount ? '复式' : ''}'
      : (lines > 1 ? '复式' : '单式');

  factory SimulationTicket.random(SimulationLottery lottery, Random random,
      {int happyEightCount = 10}) {
    List<int> sample(int max, int count) =>
        (List.generate(max, (index) => index + 1)..shuffle(random))
            .take(count)
            .toList();
    return SimulationTicket(
      lottery: lottery,
      primary: lottery == SimulationLottery.sevenStar
          ? List.generate(7, (_) => random.nextInt(10))
          : sample(
              lottery.primaryMax,
              lottery == SimulationLottery.happyEight
                  ? happyEightCount
                  : lottery.primaryCount),
      secondary: sample(lottery.secondaryMax, lottery.secondaryCount),
      happyEightCount: happyEightCount,
    );
  }

  Map<String, dynamic> toMap() => {
        'lottery': lottery.name,
        'primary': primary,
        'secondary': secondary,
        'happyEightCount': happyEightCount,
      };

  factory SimulationTicket.fromMap(Map map) => SimulationTicket(
        lottery: SimulationLottery.values.byName(map['lottery'] as String),
        primary: List<int>.from(map['primary'] as List),
        secondary: List<int>.from(map['secondary'] as List),
        happyEightCount: map['happyEightCount'] as int,
      );
}

class SimulationRecord {
  final String id;
  final DateTime createdAt;
  final SimulationLottery lottery;
  final List<SimulationTicket> tickets;
  final int multiple;
  final bool additional;

  SimulationRecord({
    required this.id,
    required this.createdAt,
    required this.lottery,
    required List<SimulationTicket> tickets,
    required this.multiple,
    required this.additional,
  }) : tickets = List.unmodifiable(tickets);

  int get lines => tickets.fold(0, (sum, ticket) => sum + ticket.lines);
  int get amount =>
      lines *
      multiple *
      (additional && lottery == SimulationLottery.superLotto ? 3 : 2);

  Map<String, dynamic> toMap() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'lottery': lottery.name,
        'tickets': tickets.map((ticket) => ticket.toMap()).toList(),
        'multiple': multiple,
        'additional': additional,
      };

  factory SimulationRecord.fromMap(Map map) => SimulationRecord(
        id: map['id'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        lottery: SimulationLottery.values.byName(map['lottery'] as String),
        tickets: (map['tickets'] as List)
            .map((ticket) => SimulationTicket.fromMap(ticket as Map))
            .toList(),
        multiple: map['multiple'] as int,
        additional: map['additional'] as bool,
      );
}
