import 'package:hive/hive.dart';

part 'happy_eight_draw.g.dart';

@HiveType(typeId: 9)
class HappyEightDraw extends HiveObject {
  @HiveField(0)
  final String issue;
  @HiveField(1)
  final DateTime publishDate;
  @HiveField(2)
  final List<String> numbers;
  @HiveField(4)
  final String announcementUrl;
  @HiveField(5)
  final List<HappyEightPrizeTier> prizeTiers;
  @HiveField(6)
  final String? salesAmount;
  @HiveField(7)
  final String? poolAmount;
  @HiveField(8)
  final DateTime syncedAt;
  @HiveField(9)
  final String? winnerContent;

  HappyEightDraw({
    required this.issue,
    required this.publishDate,
    required this.numbers,
    required this.announcementUrl,
    List<HappyEightPrizeTier>? prizeTiers,
    this.salesAmount,
    this.poolAmount,
    this.winnerContent,
    DateTime? syncedAt,
  })  : prizeTiers = prizeTiers ?? const [],
        syncedAt = syncedAt ?? DateTime.now();
}

@HiveType(typeId: 10)
class HappyEightPrizeTier {
  @HiveField(0)
  final String play;
  @HiveField(1)
  final String betCount;
  @HiveField(2)
  final String singlePrize;

  const HappyEightPrizeTier({
    required this.play,
    required this.betCount,
    required this.singlePrize,
  });
}
