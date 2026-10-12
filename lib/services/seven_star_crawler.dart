import 'package:dio/dio.dart';

import '../models/seven_star_draw.dart';

class SevenStarCrawlException implements Exception {
  final String message;
  final Object? cause;

  const SevenStarCrawlException(this.message, [this.cause]);

  @override
  String toString() => message;
}

class SevenStarCrawler {
  static const sourcePageUrl = 'https://www.lottery.gov.cn/kj/kjlb.html?qxc';
  static const _historyPath = '/gateway/lottery/getHistoryPageListV1.qry';
  static const _pageSize = 100;

  final Dio _client;

  SevenStarCrawler({Dio? client})
      : _client = client ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 15),
                headers: const {
                  'Accept': 'application/json',
                  'User-Agent': 'Mozilla/5.0',
                  'Referer': sourcePageUrl,
                },
              ),
            );

  Future<List<SevenStarDraw>> fetchDraws({int limit = 30}) async {
    if (limit <= 0) return const [];

    final pageCount = (limit / _pageSize).ceil();
    final draws = <SevenStarDraw>[];
    try {
      final endpoint = await _endpointFromSourcePage();
      for (var page = 1; page <= pageCount; page++) {
        final response = await _client.get<dynamic>(
          endpoint,
          queryParameters: {
            'gameNo': '04',
            'provinceId': '0',
            'pageSize': _pageSize,
            'isVerify': '1',
            'pageNo': page,
          },
        );
        final data = response.data;
        if (response.statusCode != 200 || data is! Map) {
          throw const SevenStarCrawlException('体彩官方接口响应异常，请稍后重试。');
        }
        final value = data['value'];
        final list = value is Map ? value['list'] : null;
        if (data['errorCode']?.toString() != '0' || list is! List) {
          throw const SevenStarCrawlException('体彩官方接口未返回体彩七星彩开奖记录。');
        }
        for (final item in list.whereType<Map>()) {
          final draw = _parseDraw(item);
          if (draw != null) draws.add(draw);
        }
        if (list.length < _pageSize) break;
      }
    } on DioException catch (error) {
      throw SevenStarCrawlException(_networkMessage(error), error);
    } on SevenStarCrawlException {
      rethrow;
    } catch (error) {
      throw SevenStarCrawlException('体彩七星彩开奖数据解析失败，请稍后重试。', error);
    }

    if (draws.isEmpty) {
      throw const SevenStarCrawlException('未从体彩官方接口获取到体彩七星彩开奖记录。');
    }
    return draws.take(limit).toList();
  }

  Future<String> _endpointFromSourcePage() async {
    final response = await _client.get<String>(
      sourcePageUrl,
      options: Options(responseType: ResponseType.plain),
    );
    final html = response.data;
    if (response.statusCode != 200 ||
        html == null ||
        !RegExp(r'''qxc\s*:\s*['"]7xc\.html''').hasMatch(html)) {
      throw const SevenStarCrawlException('体彩七星彩开奖页面无法读取，请稍后重试。');
    }

    final apiBase =
        RegExp(r'''webApi\s*:\s*['"]([^'"]+)['"]''').firstMatch(html)?.group(1);
    final uri = apiBase == null
        ? null
        : Uri.tryParse(apiBase.startsWith('//') ? 'https:$apiBase' : apiBase);
    if (uri == null ||
        uri.scheme != 'https' ||
        !(uri.host == 'sporttery.cn' ||
            uri.host.endsWith('.sporttery.cn') ||
            uri.host == 'lottery.gov.cn' ||
            uri.host.endsWith('.lottery.gov.cn'))) {
      throw const SevenStarCrawlException('体彩七星彩开奖页面未提供有效数据地址。');
    }
    return uri.resolve(_historyPath).toString();
  }

  SevenStarDraw? _parseDraw(Map item) {
    final issue = item['lotteryDrawNum']?.toString() ?? '';
    final publishDate = DateTime.tryParse(
      item['lotteryDrawTime']?.toString() ?? '',
    );
    final numbers = (item['lotteryDrawResult']?.toString() ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((number) => number.isNotEmpty)
        .toList();
    final prizeList = item['prizeLevelList'];
    if (issue.isEmpty || publishDate == null || numbers.length != 7) {
      return null;
    }

    final prizeTiers = prizeList is List
        ? prizeList.whereType<Map>().map(_parsePrizeTier).toList()
        : <SevenStarPrizeTier>[];
    return SevenStarDraw(
      issue: issue,
      publishDate: publishDate,
      numbers: numbers,
      announcementUrl: item['drawPdfUrl']?.toString() ?? '',
      prizeTiers: prizeTiers,
      salesAmount: item['totalSaleAmount']?.toString(),
      poolAmount: item['poolBalanceAfterdraw']?.toString(),
    );
  }

  SevenStarPrizeTier _parsePrizeTier(Map item) => SevenStarPrizeTier(
        level: item['prizeLevel']?.toString() ?? '',
        betCount: item['stakeCount']?.toString() ?? '0',
        singlePrize: item['stakeAmount']?.toString() ?? '0',
        totalPrize: item['totalPrizeamount']?.toString() ?? '0',
      );

  String _networkMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return '连接体彩官方接口超时，请检查网络后重试。';
      case DioExceptionType.connectionError:
        return '无法连接体彩官方接口，请检查网络后重试。';
      default:
        return '获取体彩七星彩开奖数据失败，请稍后重试。';
    }
  }
}
