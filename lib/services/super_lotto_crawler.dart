import 'package:dio/dio.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../models/super_lotto_draw.dart';

class SuperLottoCrawlException implements Exception {
  final String message;
  final Object? cause;

  const SuperLottoCrawlException(this.message, [this.cause]);

  @override
  String toString() => message;
}

class SuperLottoCrawler {
  static const _origin = 'https://www.js-lottery.com';
  static const _listPath = '/Lottery/_ListData';
  static const _pageSize = 10;

  final Dio _client;

  SuperLottoCrawler({Dio? client})
      : _client = client ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 15),
                headers: const {
                  'Accept': 'text/html,application/xhtml+xml',
                  'User-Agent': 'Mozilla/5.0',
                },
              ),
            );

  Future<List<SuperLottoDraw>> fetchLatestDraws({int limit = 30}) async {
    if (limit <= 0) {
      return const [];
    }

    final pageCount = (limit / _pageSize).ceil();
    final draws = <SuperLottoDraw>[];
    final seenIssues = <String>{};

    for (var page = 1; page <= pageCount; page++) {
      final document = await _getDocument(
        _listPath,
        queryParameters: {'itemType': 'lo', 'pageindex': page.toString()},
      );
      for (final draw in _parseListPage(document)) {
        if (seenIssues.add(draw.issue)) {
          draws.add(draw);
        }
      }
    }

    if (draws.isEmpty) {
      throw const SuperLottoCrawlException('未从江苏体彩网获取到大乐透开奖记录。');
    }
    return draws.take(limit).toList();
  }

  Future<SuperLottoDraw> fetchAnnouncement(SuperLottoDraw draw) async {
    final uri = Uri.parse(draw.announcementUrl);
    final response = await _getDocumentUri(uri);
    final pageText = _normalize(response.body?.text ?? '');
    final numberTable = _findTable(response, '本期开奖号码');
    if (numberTable == null) {
      throw SuperLottoCrawlException('第${draw.issue}期公告缺少开奖号码表格。');
    }

    final drawNumbers = _numbersForLabel(numberTable, '本期开奖号码');
    if (drawNumbers.length != 7) {
      throw SuperLottoCrawlException('第${draw.issue}期公告的开奖号码格式异常。');
    }

    final drawOrderNumbers = _numbersForLabel(numberTable, '本期出球顺序');
    final prizeTable = _findTable(response, '中奖注数');

    return SuperLottoDraw(
      issue: draw.issue,
      publishDate: draw.publishDate,
      frontNumbers: drawNumbers.take(5).toList(),
      backNumbers: drawNumbers.skip(5).toList(),
      announcementUrl: draw.announcementUrl,
      drawTime:
          _extractLabel(pageText, '开奖时间') ?? _extractLabel(pageText, '开奖日期'),
      drawLocation: _extractLabel(pageText, '开奖地点'),
      drawOrderNumbers: drawOrderNumbers,
      prizeTiers: prizeTable == null ? const [] : _parsePrizeTiers(prizeTable),
      winnerSummary: _extractLabel(pageText, '本期一等奖出自'),
    );
  }

  Future<Document> _getDocument(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _getDocumentUri(
      Uri.parse(_origin)
          .resolve(path)
          .replace(queryParameters: queryParameters),
    );
  }

  Future<Document> _getDocumentUri(Uri uri) async {
    try {
      final response = await _client.get<String>(
        uri.toString(),
        options: Options(responseType: ResponseType.plain),
      );
      if (response.statusCode != 200 || response.data == null) {
        throw const SuperLottoCrawlException('江苏体彩网响应异常，请稍后重试。');
      }
      return html_parser.parse(response.data!);
    } on DioException catch (error) {
      throw SuperLottoCrawlException(_networkMessage(error), error);
    } on SuperLottoCrawlException {
      rethrow;
    } catch (error) {
      throw SuperLottoCrawlException('开奖数据解析失败，请稍后重试。', error);
    }
  }

  List<SuperLottoDraw> _parseListPage(Document document) {
    final table = document.querySelector('table.table-border');
    if (table == null) {
      throw const SuperLottoCrawlException('开奖列表结构已变化，无法解析。');
    }

    final draws = <SuperLottoDraw>[];
    for (final row in table.querySelectorAll('tr')) {
      final cells = row.querySelectorAll('td');
      if (cells.length < 4) {
        continue;
      }

      final publishDate = DateTime.tryParse(_text(cells[0]));
      final issue = _text(cells[1]);
      final numbers = _numbers(_text(cells[2]));
      final href = cells[3].querySelector('a')?.attributes['href'];
      if (publishDate == null ||
          issue.isEmpty ||
          numbers.length != 7 ||
          href == null) {
        continue;
      }

      draws.add(
        SuperLottoDraw(
          issue: issue,
          publishDate: publishDate,
          frontNumbers: numbers.take(5).toList(),
          backNumbers: numbers.skip(5).toList(),
          announcementUrl: Uri.parse(_origin).resolve(href).toString(),
        ),
      );
    }
    return draws;
  }

  Element? _findTable(Document document, String requiredText) {
    for (final table in document.querySelectorAll('table')) {
      if (_text(table).contains(requiredText)) {
        return table;
      }
    }
    return null;
  }

  List<String> _numbersForLabel(Element table, String label) {
    for (final row in table.querySelectorAll('tr')) {
      final cells = row.querySelectorAll('th, td');
      if (cells.isNotEmpty && _text(cells.first).contains(label)) {
        return _numbers(cells.skip(1).map(_text).join(' '));
      }
    }
    return const [];
  }

  List<SuperLottoPrizeTier> _parsePrizeTiers(Element table) {
    final tiers = <SuperLottoPrizeTier>[];
    for (final row in table.querySelectorAll('tr')) {
      final cells = row.querySelectorAll('th, td').map(_text).toList();
      if (cells.length < 4 || cells.first == '奖级') {
        continue;
      }

      final hasAdditionalPrize =
          cells.length >= 5 && (cells[1] == '基本' || cells[1] == '追加');
      final level = hasAdditionalPrize ? '${cells[0]}${cells[1]}' : cells[0];
      tiers.add(
        SuperLottoPrizeTier(
          level: level,
          betCount: cells[cells.length - 3],
          singlePrize: cells[cells.length - 2],
          totalPrize: cells.last,
        ),
      );
    }
    return tiers;
  }

  String? _extractLabel(String text, String label) {
    final match = RegExp('$label[：:]\\s*([^\\n\\r；;。]+)').firstMatch(text);
    final value = match?.group(1)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  List<String> _numbers(String value) => RegExp(r'\d{2}')
      .allMatches(value)
      .map((match) => match.group(0)!)
      .toList();

  String _text(Element element) => _normalize(element.text);

  String _normalize(String value) =>
      value.replaceAll(RegExp(r'\s+'), ' ').trim();

  String _networkMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return '连接江苏体彩网超时，请检查网络后重试。';
      case DioExceptionType.connectionError:
        return '无法连接江苏体彩网，请检查网络后重试。';
      default:
        return '获取开奖数据失败，请稍后重试。';
    }
  }
}
