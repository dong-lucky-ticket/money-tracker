import 'package:hive/hive.dart';

part 'double_color_ball_draw.g.dart';

@HiveType(typeId: 5)
class DoubleColorBallDraw extends HiveObject {
  @HiveField(0)
  final String issue;

  @HiveField(1)
  final DateTime publishDate;

  @HiveField(2)
  final List<String> redNumbers;

  @HiveField(3)
  final String blueNumber;

  @HiveField(4)
  final String announcementUrl;

  @HiveField(5)
  final List<String> drawOrderNumbers;

  @HiveField(6)
  final List<DoubleColorBallPrizeTier> prizeTiers;

  @HiveField(7)
  final String? winnerSummary;

  @HiveField(8)
  final String? salesAmount;

  @HiveField(9)
  final String? poolAmount;

  @HiveField(10)
  final DateTime syncedAt;

  DoubleColorBallDraw({
    required this.issue,
    required this.publishDate,
    required this.redNumbers,
    required this.blueNumber,
    required this.announcementUrl,
    List<String>? drawOrderNumbers,
    List<DoubleColorBallPrizeTier>? prizeTiers,
    this.winnerSummary,
    this.salesAmount,
    this.poolAmount,
    DateTime? syncedAt,
  })  : drawOrderNumbers = drawOrderNumbers ?? const [],
        prizeTiers = prizeTiers ?? const [],
        syncedAt = syncedAt ?? DateTime.now();

  bool get hasAnnouncementDetails =>
      drawOrderNumbers.isNotEmpty || prizeTiers.isNotEmpty;
}

@HiveType(typeId: 6)
class DoubleColorBallPrizeTier {
  @HiveField(0)
  final String level;

  @HiveField(1)
  final String betCount;

  @HiveField(2)
  final String singlePrize;

  const DoubleColorBallPrizeTier({
    required this.level,
    required this.betCount,
    required this.singlePrize,
  });
}
