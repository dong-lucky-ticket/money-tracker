import 'package:hive/hive.dart';

part 'super_lotto_draw.g.dart';

@HiveType(typeId: 3)
class SuperLottoDraw extends HiveObject {
  @HiveField(0)
  final String issue;

  @HiveField(1)
  final DateTime publishDate;

  @HiveField(2)
  final List<String> frontNumbers;

  @HiveField(3)
  final List<String> backNumbers;

  @HiveField(4)
  final String announcementUrl;

  @HiveField(5)
  final String? drawTime;

  @HiveField(6)
  final String? drawLocation;

  @HiveField(7)
  final List<String> drawOrderNumbers;

  @HiveField(8)
  final List<SuperLottoPrizeTier> prizeTiers;

  @HiveField(9)
  final String? winnerSummary;

  @HiveField(10)
  final DateTime syncedAt;

  SuperLottoDraw({
    required this.issue,
    required this.publishDate,
    required this.frontNumbers,
    required this.backNumbers,
    required this.announcementUrl,
    this.drawTime,
    this.drawLocation,
    List<String>? drawOrderNumbers,
    List<SuperLottoPrizeTier>? prizeTiers,
    this.winnerSummary,
    DateTime? syncedAt,
  })  : drawOrderNumbers = drawOrderNumbers ?? const [],
        prizeTiers = prizeTiers ?? const [],
        syncedAt = syncedAt ?? DateTime.now();

  bool get hasAnnouncementDetails =>
      drawOrderNumbers.isNotEmpty || prizeTiers.isNotEmpty;
}

@HiveType(typeId: 4)
class SuperLottoPrizeTier {
  @HiveField(0)
  final String level;

  @HiveField(1)
  final String betCount;

  @HiveField(2)
  final String singlePrize;

  @HiveField(3)
  final String totalPrize;

  const SuperLottoPrizeTier({
    required this.level,
    required this.betCount,
    required this.singlePrize,
    required this.totalPrize,
  });
}
