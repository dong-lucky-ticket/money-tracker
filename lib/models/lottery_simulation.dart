import 'dart:math';

enum SimulationLottery { superLotto, sevenStar, doubleColorBall, happyEight, qilecai }

extension SimulationLotteryInfo on SimulationLottery {
  String get label => const ['体彩大乐透', '体彩七星彩', '福彩双色球', '福彩快乐8', '福彩七乐彩'][index];
  String get shortLabel => const ['大乐透', '七星彩', '双色球', '快乐8', '七乐彩'][index];
  int get primaryMax => const [35, 10, 33, 80, 30][index];
  int get primaryCount => const [5, 6, 6, 10, 7][index];
  int get secondaryMax => const [12, 9, 16, 0, 0][index];
  int get secondaryCount => const [2, 1, 1, 0, 0][index];
  String get primaryLabel {
    if (this == SimulationLottery.doubleColorBall) return '红球';
    if (this == SimulationLottery.happyEight) return '号码';
    if (this == SimulationLottery.qilecai) return '基本号码';
    return '前区';
  }

  String get secondaryLabel {
    if (this == SimulationLottery.doubleColorBall) return '蓝球';
    if (this == SimulationLottery.qilecai) return '特别号码';
    return '后区';
  }
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
  final List<int> primaryDan;
  final List<int> primaryTuo;
  final int happyEightCount;

  SimulationTicket({
    required this.lottery,
    required List<int> primary,
    List<int> secondary = const [],
    this.happyEightCount = 10,
    List<int> primaryDan = const [],
    List<int> primaryTuo = const [],
  })  : primaryDan = List.unmodifiable(_sortedNumbers(primaryDan)),
        primaryTuo = List.unmodifiable(_sortedNumbers(primaryTuo)),
        primary = List.unmodifiable(
            lottery == SimulationLottery.doubleColorBall &&
                    (primaryDan.isNotEmpty || primaryTuo.isNotEmpty)
                ? _unionNumbers(primaryDan, primaryTuo)
                : _normalizePrimary(lottery, primary, secondary)),
        secondary =
            List.unmodifiable(_normalizeSecondary(lottery, primary, secondary));

  bool get isDanTuo =>
      lottery == SimulationLottery.doubleColorBall &&
      (primaryDan.isNotEmpty || primaryTuo.isNotEmpty);

  bool get isValid {
    if (lottery == SimulationLottery.sevenStar) {
      return primary.length == 6 &&
          primary.every((n) => n >= 0 && n <= 9) &&
          secondary.length == 1 &&
          secondary.single >= 0 &&
          secondary.single <= 9;
    }
    if (isDanTuo) {
      if (primaryDan.isEmpty ||
          primaryTuo.isEmpty ||
          primaryDan.length > 5 ||
          primaryDan.toSet().length != primaryDan.length ||
          primaryTuo.toSet().length != primaryTuo.length ||
          primaryDan.toSet().intersection(primaryTuo.toSet()).isNotEmpty ||
          primaryDan.length + primaryTuo.length < 7) {
        return false;
      }
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
    if (isDanTuo) {
      return simulationCombinations(
              primaryTuo.length, lottery.primaryCount - primaryDan.length) *
          simulationCombinations(secondary.length, lottery.secondaryCount);
    }
    if (lottery == SimulationLottery.happyEight) {
      return simulationCombinations(primary.length, happyEightCount);
    }
    return simulationCombinations(primary.length, lottery.primaryCount) *
        simulationCombinations(secondary.length, lottery.secondaryCount);
  }

  String get playLabel {
    if (lottery == SimulationLottery.happyEight) {
      return '${happyEightPlayLabel(happyEightCount)}'
          '${primary.length > happyEightCount ? '复式' : ''}';
    }
    if (isDanTuo) return '胆拖';
    return lines > 1 ? '复式' : '单式';
  }

  factory SimulationTicket.random(SimulationLottery lottery, Random random,
      {int happyEightCount = 10}) {
    List<int> sample(int max, int count) =>
        (List.generate(max, (index) => index + 1)..shuffle(random))
            .take(count)
            .toList();
    return SimulationTicket(
      lottery: lottery,
      primary: lottery == SimulationLottery.sevenStar
          ? List.generate(6, (_) => random.nextInt(10))
          : sample(
              lottery.primaryMax,
              lottery == SimulationLottery.happyEight
                  ? happyEightCount
                  : lottery.primaryCount),
      secondary: lottery == SimulationLottery.sevenStar
          ? [random.nextInt(10)]
          : sample(lottery.secondaryMax, lottery.secondaryCount),
      happyEightCount: happyEightCount,
    );
  }

  /// Builds a random Double Color Ball dan-tuo ticket that stays within the
  /// official rules: 1-5 dan codes plus enough tuo codes to reach seven red
  /// numbers, giving a small fixed-size compound bet.
  factory SimulationTicket.danTuoRandom(
      SimulationLottery lottery, Random random) {
    final danCount = 1 + random.nextInt(5);
    final tuoCount = 7 - danCount;
    final redPool =
        (List<int>.generate(lottery.primaryMax, (index) => index + 1)
          ..shuffle(random));
    final dan = redPool.take(danCount).toList();
    final tuo = redPool.skip(danCount).take(tuoCount).toList();
    final secondary =
        (List<int>.generate(lottery.secondaryMax, (index) => index + 1)
          ..shuffle(random))
            .take(lottery.secondaryCount)
            .toList();
    return SimulationTicket(
      lottery: lottery,
      primary: [...dan, ...tuo],
      secondary: secondary,
      primaryDan: dan,
      primaryTuo: tuo,
    );
  }

  Map<String, dynamic> toMap() => {
        'lottery': lottery.name,
        'primary': primary,
        'secondary': secondary,
        'happyEightCount': happyEightCount,
        'primaryDan': primaryDan,
        'primaryTuo': primaryTuo,
      };

  factory SimulationTicket.fromMap(Map map) => SimulationTicket(
        lottery: SimulationLottery.values.byName(map['lottery'] as String),
        primary: List<int>.from(map['primary'] as List),
        secondary: List<int>.from(map['secondary'] as List),
        happyEightCount: map['happyEightCount'] as int,
        primaryDan: map['primaryDan'] == null
            ? const []
            : List<int>.from(map['primaryDan'] as List),
        primaryTuo: map['primaryTuo'] == null
            ? const []
            : List<int>.from(map['primaryTuo'] as List),
      );
}

List<int> _sortedNumbers(List<int> numbers) => List<int>.of(numbers)..sort();

List<int> _unionNumbers(List<int> first, List<int> second) =>
    ({...first, ...second}.toList()..sort());

List<int> _normalizePrimary(
    SimulationLottery lottery, List<int> primary, List<int> secondary) {
  if (lottery == SimulationLottery.sevenStar &&
      primary.length == 7 &&
      secondary.isEmpty) {
    return primary.take(6).toList();
  }
  return lottery == SimulationLottery.sevenStar
      ? List<int>.of(primary)
      : (List<int>.of(primary)..sort());
}

List<int> _normalizeSecondary(
    SimulationLottery lottery, List<int> primary, List<int> secondary) {
  if (lottery == SimulationLottery.sevenStar &&
      primary.length == 7 &&
      secondary.isEmpty) {
    return [primary.last];
  }
  return lottery == SimulationLottery.sevenStar
      ? List<int>.of(secondary)
      : (List<int>.of(secondary)..sort());
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
