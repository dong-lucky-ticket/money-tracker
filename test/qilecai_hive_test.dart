import 'dart:io';

import 'package:expensetracker/models/qilecai_draw.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('qilecai-hive-');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(QilecaiDrawAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(QilecaiPrizeTierAdapter());
    }
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('QilecaiDraw round-trips through Hive', () async {
    final box = await Hive.openBox<QilecaiDraw>('qilecaiDrawsBox');
    final draw = QilecaiDraw(
      issue: '2026135',
      publishDate: DateTime(2026, 11, 23),
      redNumbers: const ['01', '02', '07', '10', '12', '21', '26'],
      blueNumber: '03',
      announcementUrl: 'https://www.cwl.gov.cn/c/2026/11/23/674415.shtml',
      drawOrderNumbers: const ['02', '07', '26', '10', '12', '01', '21', '03'],
      prizeTiers: const [
        QilecaiPrizeTier(level: '四等奖', betCount: '447', singlePrize: '200'),
      ],
      winnerSummary: '共0注。',
      salesAmount: '4719322',
      poolAmount: '2836950',
    );
    await box.put(draw.issue, draw);

    final restored = box.get('2026135')!;
    expect(restored.issue, '2026135');
    expect(restored.redNumbers, hasLength(7));
    expect(restored.blueNumber, '03');
    expect(restored.drawOrderNumbers, hasLength(8));
    expect(restored.prizeTiers.single.level, '四等奖');
    expect(restored.prizeTiers.single.singlePrize, '200');
    expect(restored.winnerSummary, '共0注。');
    expect(restored.salesAmount, '4719322');
    expect(restored.poolAmount, '2836950');
  });
}