import 'package:hive/hive.dart';

import '../models/happy_eight_draw.dart';
import 'happy_eight_crawler.dart';

class HappyEightRepository {
  static const _boxName = 'happyEightDrawsBox';
  Box<HappyEightDraw>? _box;

  Future<List<HappyEightDraw>> loadRecent({int? limit = 30}) async {
    final box = await _getBox();
    final draws = box.values.toList()
      ..sort((a, b) {
        final dateOrder = b.publishDate.compareTo(a.publishDate);
        return dateOrder != 0 ? dateOrder : b.issue.compareTo(a.issue);
      });
    return limit == null ? draws : draws.take(limit).toList();
  }

  Future<void> saveAll(Iterable<HappyEightDraw> draws) async {
    final box = await _getBox();
    await box.putAll({for (final draw in draws) draw.issue: draw});
  }

  Future<void> deleteIssue(String issue) async =>
      (await _getBox()).delete(issue);

  Future<HappyEightDraw?> loadByIssue(String issue) async =>
      (await _getBox()).get(issue);

  Future<Box<HappyEightDraw>> _getBox() async =>
      _box ??= await Hive.openBox<HappyEightDraw>(_boxName);
}

class HappyEightSyncService {
  final HappyEightCrawler _crawler;
  final HappyEightRepository _repository;

  HappyEightSyncService({
    HappyEightCrawler? crawler,
    HappyEightRepository? repository,
  })  : _crawler = crawler ?? HappyEightCrawler(),
        _repository = repository ?? HappyEightRepository();

  Future<List<HappyEightDraw>> loadCachedDraws({int? limit = 30}) =>
      _repository.loadRecent(limit: limit);

  Future<void> deleteIssue(String issue) => _repository.deleteIssue(issue);

  Future<HappyEightDraw> refreshIssue(String issue) async {
    if (await _repository.loadByIssue(issue) == null) {
      throw const HappyEightCrawlException('本地没有找到该期记录，请先同步开奖数据。');
    }
    final draws = await _crawler.fetchDraws(limit: 100);
    final draw = draws.where((item) => item.issue == issue).firstOrNull;
    if (draw == null) {
      throw HappyEightCrawlException('官方接口暂未返回第$issue期数据，请稍后重试。');
    }
    await _repository.saveAll([draw]);
    return draw;
  }

  Future<({List<HappyEightDraw> draws, int addedDrawCount})> refreshLatest({
    int limit = 30,
    void Function(List<HappyEightDraw> draws)? onListingLoaded,
  }) async {
    final listing = await _crawler.fetchDraws(limit: limit);
    final cached = await _repository.loadRecent(limit: null);
    final cachedIssues = cached.map((draw) => draw.issue).toSet();
    final added =
        listing.where((draw) => !cachedIssues.contains(draw.issue)).length;
    await _repository.saveAll(listing);
    final loaded = await _repository.loadRecent(limit: limit);
    onListingLoaded?.call(loaded);
    return (draws: loaded, addedDrawCount: added);
  }
}
