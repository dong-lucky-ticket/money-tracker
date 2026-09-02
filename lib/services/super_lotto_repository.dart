import 'dart:math';

import 'package:hive/hive.dart';

import '../models/super_lotto_draw.dart';
import 'super_lotto_crawler.dart';

class SuperLottoSyncResult {
  final List<SuperLottoDraw> draws;
  final List<String> failedAnnouncementIssues;
  final int addedDrawCount;
  final int skippedAnnouncementCount;

  const SuperLottoSyncResult({
    required this.draws,
    required this.failedAnnouncementIssues,
    required this.addedDrawCount,
    required this.skippedAnnouncementCount,
  });
}

class SuperLottoRepository {
  static const _boxName = 'superLottoDrawsBox';

  Box<SuperLottoDraw>? _box;

  Future<List<SuperLottoDraw>> loadRecent({int limit = 30}) async {
    final box = await _getBox();
    final draws = box.values.toList()
      ..sort((left, right) {
        final byDate = right.publishDate.compareTo(left.publishDate);
        return byDate != 0 ? byDate : right.issue.compareTo(left.issue);
      });
    return draws.take(limit).toList();
  }

  Future<void> saveAll(Iterable<SuperLottoDraw> draws) async {
    final box = await _getBox();
    await box.putAll({for (final draw in draws) draw.issue: draw});
  }

  Future<void> deleteIssue(String issue) async {
    final box = await _getBox();
    await box.delete(issue);
  }

  Future<Map<String, SuperLottoDraw>> loadByIssues(
    Iterable<String> issues,
  ) async {
    final box = await _getBox();
    return {
      for (final issue in issues)
        if (box.get(issue) case final draw?) issue: draw,
    };
  }

  Future<Box<SuperLottoDraw>> _getBox() async {
    return _box ??= await Hive.openBox<SuperLottoDraw>(_boxName);
  }
}

class SuperLottoSyncService {
  final SuperLottoCrawler _crawler;
  final SuperLottoRepository _repository;

  SuperLottoSyncService({
    SuperLottoCrawler? crawler,
    SuperLottoRepository? repository,
  })  : _crawler = crawler ?? SuperLottoCrawler(),
        _repository = repository ?? SuperLottoRepository();

  Future<List<SuperLottoDraw>> loadCachedDraws() => _repository.loadRecent();

  Future<void> deleteIssue(String issue) => _repository.deleteIssue(issue);

  Future<SuperLottoDraw> refreshIssue(String issue) async {
    final existing = (await _repository.loadByIssues([issue]))[issue];
    if (existing == null) {
      throw const SuperLottoCrawlException('本地没有找到该期记录，请先同步最近开奖数据。');
    }
    final refreshed = await _crawler.fetchAnnouncement(existing);
    await _repository.saveAll([refreshed]);
    return refreshed;
  }

  Future<SuperLottoSyncResult> refreshLatest({
    void Function(List<SuperLottoDraw> draws)? onListingLoaded,
    void Function(int completed, int total)? onAnnouncementProgress,
  }) async {
    final listing = await _crawler.fetchLatestDraws();
    final existingByIssue = await _repository.loadByIssues(
      listing.map((draw) => draw.issue),
    );
    final mergedDraws = <SuperLottoDraw>[];
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
    final resolved = List<SuperLottoDraw>.from(mergedDraws);
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
    return SuperLottoSyncResult(
      draws: await _repository.loadRecent(),
      failedAnnouncementIssues: failedIssues,
      addedDrawCount: addedDrawCount,
      skippedAnnouncementCount: skippedAnnouncementCount,
    );
  }
}
