import 'dart:math';

import 'package:hive/hive.dart';

import '../models/double_color_ball_draw.dart';
import 'double_color_ball_crawler.dart';

class DoubleColorBallSyncResult {
  final List<DoubleColorBallDraw> draws;
  final List<String> failedAnnouncementIssues;
  final int addedDrawCount;
  final int skippedAnnouncementCount;

  const DoubleColorBallSyncResult({
    required this.draws,
    required this.failedAnnouncementIssues,
    required this.addedDrawCount,
    required this.skippedAnnouncementCount,
  });
}

class DoubleColorBallRepository {
  static const _boxName = 'doubleColorBallDrawsBox';

  Box<DoubleColorBallDraw>? _box;

  Future<List<DoubleColorBallDraw>> loadRecent({int limit = 30}) async {
    final box = await _getBox();
    final draws = box.values.toList()
      ..sort((left, right) {
        final byDate = right.publishDate.compareTo(left.publishDate);
        return byDate != 0 ? byDate : right.issue.compareTo(left.issue);
      });
    return draws.take(limit).toList();
  }

  Future<void> saveAll(Iterable<DoubleColorBallDraw> draws) async {
    final box = await _getBox();
    await box.putAll({for (final draw in draws) draw.issue: draw});
  }

  Future<Map<String, DoubleColorBallDraw>> loadByIssues(
    Iterable<String> issues,
  ) async {
    final box = await _getBox();
    return {
      for (final issue in issues)
        if (box.get(issue) case final draw?) issue: draw,
    };
  }

  Future<Box<DoubleColorBallDraw>> _getBox() async {
    return _box ??= await Hive.openBox<DoubleColorBallDraw>(_boxName);
  }
}

class DoubleColorBallSyncService {
  final DoubleColorBallCrawler _crawler;
  final DoubleColorBallRepository _repository;

  DoubleColorBallSyncService({
    DoubleColorBallCrawler? crawler,
    DoubleColorBallRepository? repository,
  })  : _crawler = crawler ?? DoubleColorBallCrawler(),
        _repository = repository ?? DoubleColorBallRepository();

  Future<List<DoubleColorBallDraw>> loadCachedDraws() =>
      _repository.loadRecent();

  Future<DoubleColorBallSyncResult> refreshLatest({
    void Function(List<DoubleColorBallDraw> draws)? onListingLoaded,
    void Function(int completed, int total)? onAnnouncementProgress,
  }) async {
    final listing = await _crawler.fetchLatestDraws();
    final existingByIssue = await _repository.loadByIssues(
      listing.map((draw) => draw.issue),
    );
    final mergedDraws = <DoubleColorBallDraw>[];
    var addedDrawCount = 0;
    var skippedAnnouncementCount = 0;

    for (final listedDraw in listing) {
      final existingDraw = existingByIssue[listedDraw.issue];
      if (existingDraw == null) {
        addedDrawCount++;
        mergedDraws.add(listedDraw);
      } else if (existingDraw.hasAnnouncementDetails) {
        skippedAnnouncementCount++;
        mergedDraws.add(existingDraw);
      } else {
        mergedDraws.add(listedDraw);
      }
    }

    await _repository.saveAll(mergedDraws);
    onListingLoaded?.call(await _repository.loadRecent());

    final pendingIndexes = <int>[
      for (var index = 0; index < mergedDraws.length; index++)
        if (!mergedDraws[index].hasAnnouncementDetails) index,
    ];
    final resolved = List<DoubleColorBallDraw>.from(mergedDraws);
    final failedIssues = <String>[];
    var nextIndex = 0;
    var completed = 0;
    onAnnouncementProgress?.call(0, pendingIndexes.length);

    Future<void> worker() async {
      while (nextIndex < pendingIndexes.length) {
        final index = pendingIndexes[nextIndex++];
        final draw = mergedDraws[index];
        try {
          resolved[index] = await _crawler.fetchAnnouncement(draw);
        } catch (_) {
          failedIssues.add(draw.issue);
        } finally {
          completed++;
          onAnnouncementProgress?.call(completed, pendingIndexes.length);
        }
      }
    }

    await Future.wait(
      List.generate(min(4, pendingIndexes.length), (_) => worker()),
    );

    await _repository.saveAll(resolved);
    return DoubleColorBallSyncResult(
      draws: await _repository.loadRecent(),
      failedAnnouncementIssues: failedIssues,
      addedDrawCount: addedDrawCount,
      skippedAnnouncementCount: skippedAnnouncementCount,
    );
  }
}
