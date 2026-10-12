import 'package:hive/hive.dart';

import '../models/seven_star_draw.dart';
import 'seven_star_crawler.dart';

class SevenStarRepository {
  static const _boxName = 'sevenStarDrawsBox';

  Box<SevenStarDraw>? _box;

  Future<List<SevenStarDraw>> loadRecent({int? limit = 30}) async {
    final box = await _getBox();
    final draws = box.values.toList()
      ..sort((left, right) {
        final byDate = right.publishDate.compareTo(left.publishDate);
        return byDate != 0 ? byDate : right.issue.compareTo(left.issue);
      });
    return limit == null ? draws : draws.take(limit).toList();
  }

  Future<void> saveAll(Iterable<SevenStarDraw> draws) async {
    final box = await _getBox();
    await box.putAll({for (final draw in draws) draw.issue: draw});
  }

  Future<void> deleteIssue(String issue) async {
    final box = await _getBox();
    await box.delete(issue);
  }

  Future<SevenStarDraw?> loadByIssue(String issue) async {
    final box = await _getBox();
    return box.get(issue);
  }

  Future<Box<SevenStarDraw>> _getBox() async =>
      _box ??= await Hive.openBox<SevenStarDraw>(_boxName);
}

class SevenStarSyncResult {
  final List<SevenStarDraw> draws;
  final int addedDrawCount;

  const SevenStarSyncResult({
    required this.draws,
    required this.addedDrawCount,
  });
}

class SevenStarSyncService {
  final SevenStarCrawler _crawler;
  final SevenStarRepository _repository;

  SevenStarSyncService({
    SevenStarCrawler? crawler,
    SevenStarRepository? repository,
  })  : _crawler = crawler ?? SevenStarCrawler(),
        _repository = repository ?? SevenStarRepository();

  Future<List<SevenStarDraw>> loadCachedDraws({int? limit = 30}) =>
      _repository.loadRecent(limit: limit);

  Future<void> deleteIssue(String issue) => _repository.deleteIssue(issue);

  Future<SevenStarDraw> refreshIssue(String issue) async {
    final existing = await _repository.loadByIssue(issue);
    if (existing == null) {
      throw const SevenStarCrawlException('本地没有找到该期记录，请先同步开奖数据。');
    }
    final latestDraws = await _crawler.fetchDraws(limit: 100);
    final refreshed = latestDraws.where((draw) => draw.issue == issue);
    if (refreshed.isEmpty) {
      throw SevenStarCrawlException('官方接口暂未返回第$issue期数据，请稍后重试。');
    }
    final draw = refreshed.first;
    await _repository.saveAll([draw]);
    return draw;
  }

  Future<SevenStarSyncResult> refreshLatest({
    int limit = 30,
    void Function(List<SevenStarDraw> draws)? onListingLoaded,
  }) async {
    final listing = await _crawler.fetchDraws(limit: limit);
    final cached = await _repository.loadRecent(limit: null);
    final cachedIssues = cached.map((draw) => draw.issue).toSet();
    final addedDrawCount =
        listing.where((draw) => !cachedIssues.contains(draw.issue)).length;
    await _repository.saveAll(listing);
    final loaded = await _repository.loadRecent(limit: limit);
    onListingLoaded?.call(loaded);
    return SevenStarSyncResult(
      draws: loaded,
      addedDrawCount: addedDrawCount,
    );
  }
}
