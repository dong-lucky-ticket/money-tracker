import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:expensetracker/services/qilecai_crawler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses official Qilecai numbers from the listing API', () async {
    final adapter = _QilecaiApiAdapter();
    final client = Dio()..httpClientAdapter = adapter;
    addTearDown(() => client.close(force: true));

    final draws = await QilecaiCrawler(client: client).fetchLatestDraws(limit: 1);
    final draw = draws.single;

    expect(adapter.request.uri.queryParameters['name'], 'qlc');
    expect(draw.issue, '2026135');
    expect(draw.publishDate, DateTime(2026, 11, 23));
    expect(draw.redNumbers, [
      '01',
      '02',
      '07',
      '10',
      '12',
      '21',
      '26'
    ]);
    expect(draw.blueNumber, '03');
    expect(draw.announcementUrl,
        'https://www.cwl.gov.cn/c/2026/11/23/674415.shtml');
    expect(draw.salesAmount, '4719322');
    expect(draw.poolAmount, '2836950');
  });
}

class _QilecaiApiAdapter implements HttpClientAdapter {
  RequestOptions? _request;
  RequestOptions get request => _request!;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    _request = options;
    return ResponseBody.fromString(
        jsonEncode({
          'message': '查询成功',
          'result': [
            {
              'name': '七乐彩',
              'code': '2026135',
              'detailsLink': '/c/2026/11/23/674415.shtml',
              'date': '2026-11-23(一)',
              'red': '01,02,07,10,12,21,26',
              'blue': '03',
              'sales': '4719322',
              'poolmoney': '2836950',
              'content': '共0注。',
              'prizegrades': [
                {'type': 1, 'typenum': '0', 'typemoney': '0'},
                {'type': 2, 'typenum': '3', 'typemoney': '54730'},
              ],
            }
          ],
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        });
  }

  @override
  void close({bool force = false}) {}
}