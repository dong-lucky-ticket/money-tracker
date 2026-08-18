import 'package:dio/dio.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../models/double_color_ball_draw.dart';

class DoubleColorBallCrawlException implements Exception {
  final String message;
  final Object? cause;

  const DoubleColorBallCrawlException(this.message, [this.cause]);

  @override
  String toString() => message;
}

class DoubleColorBallCrawler {
  static const _origin = 'https://www.cwl.gov.cn';
  static const _drawNoticePath =
      '/cwl_admin/front/cwlkj/search/kjxx/findDrawNotice';

  final Dio _client;

  DoubleColorBallCrawler({Dio? client})
      : _client = client ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 15),
                headers: const {
                  'Accept': 'application/json,text/html',
                  'User-Agent': 'Mozilla/5.0',
                },
              ),
            );

  Future<List<DoubleColorBallDraw>> fetchLatestDraws({int limit = 30}) async {
    if (limit <= 0) {
      return const [];
    }

    try {
      final response = await _client.get<dynamic>(
        Uri.parse(_origin)
            .resolve(_drawNoticePath)
            .replace(queryParameters: {
              'name': 'ssq',
              'issueCount': limit.toString(),
              'pageNo': '1',
              'pageSize': limit.toString(),
              'systemType': 'PC',
            })
            .toString(),
      );
      final data = response.data;
      if (response.statusCode != 200 || data is! Map) {
        throw const DoubleColorBallCrawlException('中国福彩网响应异常，请稍后重试。');
      }
      if (data['message'] != '查询成功' || data['result'] is! List) {
        throw const DoubleColorBallCrawlException('中国福彩网未返回双色球开奖记录。');
      }

      final draws = (data['result'] as List)
          .whereType<Map>()
          .map(_parseListing)
          .whereType<DoubleColorBallDraw>()
          .take(limit)
          .toList();
      if (draws.isEmpty) {
        throw const DoubleColorBallCrawlException('未从中国福彩网获取到双色球开奖记录。');
      }
      return draws;
    } on DioException catch (error) {
      throw DoubleColorBallCrawlException(_networkMessage(error), error);
    } on DoubleColorBallCrawlException {
      rethrow;
    } catch (error) {
      throw DoubleColorBallCrawlException('双色球列表解析失败，请稍后重试。', error);
    }
  }

  Future<DoubleColorBallDraw> fetchAnnouncement(DoubleColorBallDraw draw) async {
    final document = await _getDocument(Uri.parse(draw.announcementUrl));
    final pageText = _text(document.body ?? document.documentElement!);
    final drawOrderNumbers = _parseDrawOrder(document);
    final prizeTiers = _parsePrizeTiers(document);

    if (drawOrderNumbers.length != 7 || prizeTiers.isEmpty) {
      throw DoubleColorBallCrawlException(
        '第${draw.issue}期公告解析不完整：'
        '出球顺序 ${drawOrderNumbers.length}/7，中奖表 ${prizeTiers.length} 个奖级。',
      );
    }

    return DoubleColorBallDraw(
      issue: draw.issue,
      publishDate: draw.publishDate,
      redNumbers: draw.redNumbers,
      blueNumber: draw.blueNumber,
      announcementUrl: draw.announcementUrl,
      drawOrderNumbers: drawOrderNumbers,
      prizeTiers: prizeTiers,
      winnerSummary: _textForLabel(document, '一等奖中奖情况'),
      salesAmount: _extractLabel(pageText, '本期销售金额'),
      poolAmount: _extractLabel(pageText, '下期一等奖奖池累计金额'),
    );
  }

  DoubleColorBallDraw? _parseListing(Map item) {
    final issue = item['code']?.toString() ?? '';
    final dateText = item['date']?.toString() ?? '';
    final dateMatch = RegExp(r'\d{4}-\d{2}-\d{2}').firstMatch(dateText);
    final publishDate = DateTime.tryParse(dateMatch?.group(0) ?? '');
    final redNumbers = _numbers(item['red']?.toString() ?? '');
    final blueNumbers = _numbers(item['blue']?.toString() ?? '');
    final detailPath = item['detailsLink']?.toString() ?? '';
    if (issue.isEmpty ||
        publishDate == null ||
        redNumbers.length != 6 ||
        blueNumbers.length != 1 ||
        detailPath.isEmpty) {
      return null;
    }

    return DoubleColorBallDraw(
      issue: issue,
      publishDate: publishDate,
      redNumbers: redNumbers,
      blueNumber: blueNumbers.single,
      announcementUrl: Uri.parse(_origin).resolve(detailPath).toString(),
      salesAmount: item['sales']?.toString(),
      poolAmount: item['poolmoney']?.toString(),
    );
  }

  Future<Document> _getDocument(Uri uri) async {
    try {
      final response = await _client.get<String>(
        uri.toString(),
        options: Options(responseType: ResponseType.plain),
      );
      if (response.statusCode != 200 || response.data == null) {
        throw const DoubleColorBallCrawlException('中国福彩网公告响应异常，请稍后重试。');
      }
      return html_parser.parse(response.data!);
    } on DioException catch (error) {
      throw DoubleColorBallCrawlException(_networkMessage(error), error);
    } on DoubleColorBallCrawlException {
      rethrow;
    } catch (error) {
      throw DoubleColorBallCrawlException('双色球公告解析失败，请稍后重试。', error);
    }
  }

  List<String> _parseDrawOrder(Document document) {
    final scripts =
        document.querySelectorAll('script').map((script) => script.innerHtml);
    final redMatch = RegExp(r'var\s+khHq\s*=\s*\[([\s\S]*?)\]')
        .firstMatch(scripts.join('\n'));
    final blueMatch = RegExp("var\\s+khLq\\s*=\\s*['\\\"](\\d{1,2})['\\\"]")
        .firstMatch(scripts.join('\n'));
    if (redMatch == null || blueMatch == null) {
      return const [];
    }
    final red = _numbers(redMatch.group(1) ?? '');
    final blue = blueMatch.group(1)?.padLeft(2, '0');
    return blue == null || red.length != 6 ? const [] : [...red, blue];
  }

  List<DoubleColorBallPrizeTier> _parsePrizeTiers(Document document) {
    final table = document.querySelector('.content-text table');
    if (table == null) {
      return const [];
    }
    final tiers = <DoubleColorBallPrizeTier>[];
    for (final row in table.querySelectorAll('tr')) {
      final cells = row.querySelectorAll('td').map(_text).toList();
      if (cells.length < 3) {
        continue;
      }
      tiers.add(
        DoubleColorBallPrizeTier(
          level: cells[0],
          betCount: cells[1],
          singlePrize: cells[2],
        ),
      );
    }
    return tiers;
  }

  String? _textForLabel(Document document, String label) {
    for (final element in document.querySelectorAll('.awardDetailed > div')) {
      if (_text(element).contains(label)) {
        final values = element.querySelectorAll('.winningProvinces').map(_text);
        final result = values.join(' ');
        return result.isEmpty ? null : result;
      }
    }
    return null;
  }

  String? _extractLabel(String text, String label) {
    final match = RegExp('$label[：:]\\s*([^\\n\\r；;。]+)').firstMatch(text);
    final value = match?.group(1)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  List<String> _numbers(String value) => RegExp(r'\d{1,2}')
      .allMatches(value)
      .map((match) => match.group(0)!.padLeft(2, '0'))
      .toList();

  String _text(Element element) =>
      element.text.replaceAll(RegExp(r'\s+'), ' ').trim();

  String _networkMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return '连接中国福彩网超时，请检查网络后重试。';
      case DioExceptionType.connectionError:
        return '无法连接中国福彩网，请检查网络后重试。';
      default:
        return '获取双色球开奖数据失败，请稍后重试。';
    }
  }
}
