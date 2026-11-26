
import 'package:expensetracker/models/category.dart';
import 'package:expensetracker/models/record.dart';
import 'package:expensetracker/utils/gambling_stats.dart';
import 'package:flutter_test/flutter_test.dart';

Category _category({
  required String name,
  required String iconName,
  required bool isExpense,
}) {
  return Category(
    id: '$name-$iconName-$isExpense',
    name: name,
    iconName: iconName,
    colorHex: '#EF4444',
    isExpense: isExpense,
  );
}

Record _record({
  required String id,
  required bool isExpense,
  required double amount,
  required String remark,
  DateTime? date,
}) {
  return Record(
    id: id,
    amount: amount,
    category: _category(
      name: '彩票',
      iconName: isExpense ? 'lottery' : 'lottery-income',
      isExpense: isExpense,
    ),
    remark: remark,
    date: date ?? DateTime(2026, 11, 1),
    isExpense: isExpense,
  );
}

void main() {
  test('classifies sports and welfare lottery by issuer keywords', () {
    expect(classifyGamblingIssuer('体彩'), GamblingIssuer.sports);
    expect(classifyGamblingIssuer('大乐透'), GamblingIssuer.sports);
    expect(classifyGamblingIssuer('顶呱刮'), GamblingIssuer.sports);
    expect(classifyGamblingIssuer('福彩'), GamblingIssuer.welfare);
    expect(classifyGamblingIssuer('双色球'), GamblingIssuer.welfare);
    expect(classifyGamblingIssuer('刮刮乐'), GamblingIssuer.welfare);
    expect(classifyGamblingIssuer('刮刮卡'), GamblingIssuer.uncategorized);
    expect(classifyGamblingIssuer(''), GamblingIssuer.uncategorized);
  });

  test('issuer has higher priority than scratch keyword', () {
    expect(classifyGamblingIssuer('体彩刮刮乐'), GamblingIssuer.sports);
    expect(classifyGamblingForm('体彩刮刮乐'), GamblingForm.scratch);
  });

  test('classifies scratch and paper lottery by form keywords', () {
    expect(classifyGamblingForm('刮刮卡'), GamblingForm.scratch);
    expect(classifyGamblingForm('刮刮乐'), GamblingForm.scratch);
    expect(classifyGamblingForm('即开票'), GamblingForm.scratch);
    expect(classifyGamblingForm('顶呱刮'), GamblingForm.scratch);
    expect(classifyGamblingForm('大乐透'), GamblingForm.paper);
    expect(classifyGamblingForm('双色球'), GamblingForm.paper);
    expect(classifyGamblingForm(''), GamblingForm.paper);
  });

  test('builds spent and won summaries from lottery records', () {
    final records = [
      _record(id: '1', isExpense: true, amount: 100, remark: '体彩大乐透'),
      _record(id: '2', isExpense: true, amount: 60, remark: '福彩双色球'),
      _record(id: '3', isExpense: false, amount: 30, remark: '体彩大乐透 中奖'),
      _record(id: '4', isExpense: false, amount: 5, remark: '福彩 中奖'),
    ];

    final summary = GamblingSummary.fromRecords(records);

    expect(summary.spent, 160);
    expect(summary.won, 35);
    expect(summary.net, -125);
    expect(summary.returnRate, closeTo(35 / 160, 0.000001));
  });

  test('filters records by issuer and form independently', () {
    final records = [
      _record(id: '1', isExpense: true, amount: 10, remark: '体彩刮刮乐'),
      _record(id: '2', isExpense: true, amount: 20, remark: '福彩双色球'),
      _record(id: '3', isExpense: true, amount: 30, remark: '刮刮卡'),
    ];

    final sports = filterRecordsByIssuer(records, GamblingIssuer.sports);
    final scratch = filterRecordsByForm(records, GamblingForm.scratch);

    expect(sports, hasLength(1));
    expect(sports.single.id, '1');
    expect(scratch, hasLength(2));
    expect(scratch.map((record) => record.id), containsAll(['1', '3']));
  });

  test('builds monthly stats within the given month window', () {
    final stats = buildGamblingMonthlyStats(
      [
        _record(id: '1', isExpense: true, amount: 100, remark: '刮刮卡', date: DateTime(2026, 11, 5)),
        _record(id: '2', isExpense: false, amount: 20, remark: '刮刮卡', date: DateTime(2026, 11, 8)),
        _record(id: '3', isExpense: true, amount: 50, remark: '刮刮卡', date: DateTime(2025, 12, 1)),
      ],
      fromMonth: DateTime(2026, 10),
      toMonth: DateTime(2026, 11),
    );

    expect(stats, hasLength(2));
    expect(stats.first.month, DateTime(2026, 10));
    expect(stats.first.spent, 0);
    expect(stats.last.month, DateTime(2026, 11));
    expect(stats.last.spent, 100);
    expect(stats.last.won, 20);
  });
}
