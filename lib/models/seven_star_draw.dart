import 'package:hive/hive.dart';

part 'seven_star_draw.g.dart';

@HiveType(typeId: 7)
class SevenStarDraw extends HiveObject {
  @HiveField(0)
  final String issue;

  @HiveField(1)
  final DateTime publishDate;

  @HiveField(2)
  final List<String> numbers;

  @HiveField(3)
  final String announcementUrl;

  @HiveField(4)
  final List<SevenStarPrizeTier> prizeTiers;

  @HiveField(5)
  final String? salesAmount;

  @HiveField(6)
  final String? poolAmount;

  @HiveField(7)
  final DateTime syncedAt;

  SevenStarDraw({
    required this.issue,
    required this.publishDate,
    required this.numbers,
    required this.announcementUrl,
    List<SevenStarPrizeTier>? prizeTiers,
    this.salesAmount,
    this.poolAmount,
    DateTime? syncedAt,
  })  : prizeTiers = prizeTiers ?? const [],
        syncedAt = syncedAt ?? DateTime.now();
}

@HiveType(typeId: 8)
class SevenStarPrizeTier {
  @HiveField(0)
  final String level;

  @HiveField(1)
  final String betCount;

  @HiveField(2)
  final String singlePrize;

  @HiveField(3)
  final String totalPrize;

  const SevenStarPrizeTier({
    required this.level,
    required this.betCount,
    required this.singlePrize,
    required this.totalPrize,
  });
}
