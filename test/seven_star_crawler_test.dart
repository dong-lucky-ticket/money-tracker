import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expensetracker/services/seven_star_crawler.dart';

void main() {
  test('parses official seven star draw and prize data', () async {
    final adapter = _SevenStarApiAdapter();
    final client = Dio()..httpClientAdapter = adapter;
    addTearDown(() => client.close(force: true));

    final draws = await SevenStarCrawler(client: client).fetchDraws(limit: 30);

    expect(adapter.requests, hasLength(2));
    expect(
        adapter.requests.first.uri.toString(), SevenStarCrawler.sourcePageUrl);
    expect(adapter.requests.last.uri.host, 'webapi.sporttery.cn');
    expect(adapter.requests.last.queryParameters['gameNo'], '04');
    expect(adapter.requests.last.queryParameters['pageSize'], 100);
    expect(draws, hasLength(1));
    expect(draws.single.issue, '26116');
    expect(draws.single.numbers, ['8', '7', '1', '5', '7', '0', '6']);
    expect(draws.single.publishDate, DateTime(2026, 10, 11));
    expect(draws.single.announcementUrl,
        'https://pdf.sporttery.cn/17100/26116/26116.pdf');
    expect(draws.single.prizeTiers, hasLength(2));
    expect(draws.single.prizeTiers.first.level, '一等奖');
    expect(draws.single.prizeTiers.first.singlePrize, '5,000,000');
    expect(draws.single.salesAmount, '15,998,496');
  });

  test('uses the data host configured by the seven star page', () async {
    final adapter = _SevenStarApiAdapter(apiBase: '//history.lottery.gov.cn');
    final client = Dio()..httpClientAdapter = adapter;
    addTearDown(() => client.close(force: true));

    await SevenStarCrawler(client: client).fetchDraws(limit: 1);

    expect(
        adapter.requests.first.uri.toString(), SevenStarCrawler.sourcePageUrl);
    expect(adapter.requests.last.uri.host, 'history.lottery.gov.cn');
  });
}

class _SevenStarApiAdapter implements HttpClientAdapter {
  final String apiBase;
  final requests = <RequestOptions>[];

  _SevenStarApiAdapter({this.apiBase = '//webapi.sporttery.cn'});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (options.uri.toString() == SevenStarCrawler.sourcePageUrl) {
      return ResponseBody.fromString(
        '''<script>var jsCommonDataV1 = {webApi: "$apiBase"};
        var kjDataName = {qxc: '7xc.html?url=' + myDomain};</script>''',
        200,
        headers: {
          Headers.contentTypeHeader: ['text/html'],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode({
        'errorCode': '0',
        'success': true,
        'value': {
          'list': [
            {
              'lotteryDrawNum': '26116',
              'lotteryDrawTime': '2026-10-11',
              'lotteryDrawResult': '8 7 1 5 7 0 6',
              'drawPdfUrl': 'https://pdf.sporttery.cn/17100/26116/26116.pdf',
              'totalSaleAmount': '15,998,496',
              'poolBalanceAfterdraw': '46,977,993.06',
              'prizeLevelList': [
                {
                  'prizeLevel': '一等奖',
                  'stakeCount': '2',
                  'stakeAmount': '5,000,000',
                  'totalPrizeamount': '10,000,000',
                },
                {
                  'prizeLevel': '二等奖',
                  'stakeCount': '4',
                  'stakeAmount': '59,062',
                  'totalPrizeamount': '236,248',
                },
              ],
            },
          ],
        },
      }),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
