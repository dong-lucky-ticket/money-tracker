import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:expensetracker/services/happy_eight_crawler.dart';
import 'package:expensetracker/models/happy_eight_draw.dart';
import 'package:expensetracker/screens/happy_eight_announcement_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses official Happy 8 numbers and prize grades', () async {
    final adapter = _HappyEightApiAdapter();
    final client = Dio()..httpClientAdapter = adapter;
    addTearDown(() => client.close(force: true));

    final draws = await HappyEightCrawler(client: client).fetchDraws(limit: 1);
    final draw = draws.single;

    expect(adapter.request.uri.queryParameters['name'], 'kl8');
    expect(draw.issue, '2026295');
    expect(draw.publishDate, DateTime(2026, 11, 5));
    expect(draw.numbers, [
      '05',
      '06',
      '07',
      '11',
      '12',
      '16',
      '18',
      '21',
      '24',
      '32',
      '33',
      '36',
      '38',
      '44',
      '47',
      '56',
      '57',
      '61',
      '75',
      '77'
    ]);
    expect(draw.announcementUrl,
        'https://www.cwl.gov.cn/c/2026/11/05/672297.shtml');
    expect(draw.salesAmount, '110152370');
    expect(draw.prizeTiers.first.play, 'x10z10');
    expect(draw.prizeTiers.first.singlePrize, '5000000');
    expect(draw.winnerContent, '湖北1注。');
  });

  testWidgets('announcement shows its source link without draw order',
      (tester) async {
    const announcementUrl = 'https://www.cwl.gov.cn/c/2026/11/05/672297.shtml';
    final draw = HappyEightDraw(
      issue: '2026295',
      publishDate: DateTime(2026, 11, 5),
      numbers: List.generate(20, (index) => '${index + 1}'.padLeft(2, '0')),
      announcementUrl: announcementUrl,
      prizeTiers: const [
        HappyEightPrizeTier(
          play: 'x10z10',
          betCount: '1',
          singlePrize: '5000000',
        ),
      ],
      winnerContent: '湖北1注。',
    );
    await tester.pumpWidget(MaterialApp(
      home: HappyEightAnnouncementScreen(draw: draw),
    ));

    expect(find.text('“选十中十”中奖情况：'), findsOneWidget);
    expect(find.text('湖北1注。'), findsOneWidget);
    final ball = find.ancestor(
      of: find.text('01'),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).shape == BoxShape.circle,
      ),
    );
    expect(tester.widget<Container>(ball).constraints!.maxWidth, 34);
    await tester.scrollUntilVisible(
      find.text(announcementUrl),
      300,
      scrollable: find.byType(Scrollable).last,
    );

    expect(find.text(announcementUrl), findsOneWidget);
    expect(find.text('出球顺序'), findsNothing);
  });
}

class _HappyEightApiAdapter implements HttpClientAdapter {
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
              'code': '2026295',
              'date': '2026-11-05(四)',
              'detailsLink': '/c/2026/11/05/672297.shtml',
              'red':
                  '05,06,07,11,12,16,18,21,24,32,33,36,38,44,47,56,57,61,75,77',
              'sales': '110152370',
              'poolmoney': '68324570.68',
              'content': '&#x6E56;北1注。',
              'prizegrades': [
                {'type': 'x10z10', 'typenum': '1', 'typemoney': '5000000'}
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
