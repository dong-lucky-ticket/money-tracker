import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;

import '../models/happy_eight_draw.dart';

class HappyEightCrawlException implements Exception {
  final String message;
  final Object? cause;

  const HappyEightCrawlException(this.message, [this.cause]);

  @override
  String toString() => message;
}

class HappyEightCrawler {
  static const sourcePageUrl = 'https://www.cwl.gov.cn/ygkj/wqkjgg/kl8/';
  static const apiUrl =
      'https://www.cwl.gov.cn/cwl_admin/front/cwlkj/search/kjxx/findDrawNotice';

  final Dio _client;

  HappyEightCrawler({Dio? client})
      : _client = client ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              headers: const {
                'Accept': 'application/json,text/plain,*/*',
                'User-Agent': 'Mozilla/5.0',
                'Referer': sourcePageUrl,
              },
            ));

  Future<List<HappyEightDraw>> fetchDraws({int limit = 30}) async {
    if (limit <= 0) return const [];
    try {
      final response = await _client.get<dynamic>(apiUrl, queryParameters: {
        'name': 'kl8',
        'issueCount': limit,
        'pageNo': 1,
        'pageSize': limit,
        'systemType': 'PC',
      });
      final data = response.data;
      if (response.statusCode != 200 || data is! Map) {
        throw const HappyEightCrawlException('中国福彩网响应异常，请稍后重试。');
      }
      if (data['message'] != '查询成功' || data['result'] is! List) {
        throw const HappyEightCrawlException('中国福彩网未返回快乐8开奖记录。');
      }
      final draws = (data['result'] as List)
          .whereType<Map>()
          .map(_parseDraw)
          .whereType<HappyEightDraw>()
          .take(limit)
          .toList();
      if (draws.isEmpty) {
        throw const HappyEightCrawlException('未从中国福彩网获取到快乐8开奖记录。');
      }
      return draws;
    } on DioException catch (error) {
      throw HappyEightCrawlException(_networkMessage(error), error);
    } on HappyEightCrawlException {
      rethrow;
    } catch (error) {
      throw HappyEightCrawlException('快乐8开奖数据解析失败，请稍后重试。', error);
    }
  }

  HappyEightDraw? _parseDraw(Map item) {
    final issue = item['code']?.toString() ?? '';
    final dateMatch =
        RegExp(r'\d{4}-\d{2}-\d{2}').firstMatch(item['date']?.toString() ?? '');
    final publishDate = DateTime.tryParse(dateMatch?.group(0) ?? '');
    final numbers = _numbers(item['red']?.toString() ?? '');
    final detailPath = item['detailsLink']?.toString() ?? '';
    if (issue.isEmpty || publishDate == null || numbers.length != 20) {
      return null;
    }
    final prizeGrades = item['prizegrades'];
    final prizeTiers = prizeGrades is List
        ? prizeGrades.whereType<Map>().map(_parsePrizeTier).toList()
        : <HappyEightPrizeTier>[];
    return HappyEightDraw(
      issue: issue,
      publishDate: publishDate,
      numbers: numbers
        ..sort((left, right) => int.parse(left).compareTo(int.parse(right))),
      announcementUrl: Uri.parse(sourcePageUrl).resolve(detailPath).toString(),
      prizeTiers: prizeTiers,
      salesAmount: item['sales']?.toString(),
      poolAmount: item['poolmoney']?.toString(),
      winnerContent: _optionalText(item['content']),
    );
  }

  String? _optionalText(dynamic value) {
    final rawText = value?.toString();
    if (rawText == null) return null;
    final text = html_parser.parseFragment(rawText).text?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  HappyEightPrizeTier _parsePrizeTier(Map item) => HappyEightPrizeTier(
        play: item['type']?.toString() ?? '',
        betCount: item['typenum']?.toString() ?? '0',
        singlePrize: item['typemoney']?.toString() ?? '0',
      );

  List<String> _numbers(String value) => RegExp(r'\d{1,2}')
      .allMatches(value)
      .map((match) => match.group(0)!.padLeft(2, '0'))
      .toList();

  String _networkMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return '连接中国福彩网超时，请检查网络后重试。';
      case DioExceptionType.connectionError:
        return '无法连接中国福彩网，请检查网络后重试。';
      default:
        return '获取快乐8开奖数据失败，请稍后重试。';
    }
  }
}
