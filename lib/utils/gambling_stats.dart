
import '../models/category.dart';
import '../models/record.dart';

enum GamblingIssuer { all, sports, welfare, uncategorized }

extension GamblingIssuerLabel on GamblingIssuer {
  String get label {
    switch (this) {
      case GamblingIssuer.all:
        return '全部';
      case GamblingIssuer.sports:
        return '体彩';
      case GamblingIssuer.welfare:
        return '福彩';
      case GamblingIssuer.uncategorized:
        return '未分类';
    }
  }
}

enum GamblingForm { all, scratch, paper }

extension GamblingFormLabel on GamblingForm {
  String get label {
    switch (this) {
      case GamblingForm.all:
        return '全部';
      case GamblingForm.scratch:
        return '刮刮乐';
      case GamblingForm.paper:
        return '纸质彩票';
    }
  }
}

bool isLotteryCategory(Category category) {
  if (category.name.trim() == '彩票') {
    return true;
  }

  if (category.isExpense) {
    return category.iconName == 'lottery';
  }

  return category.iconName == 'lottery-income';
}

List<Record> collectLotteryRecords(Iterable<Record> records) {
  return records.where((record) {
    if (record.isVoided) {
      return false;
    }
    return isLotteryCategory(record.category);
  }).toList(growable: false);
}

const List<String> _sportsKeywords = [
  '超级大乐透',
  '大乐透',
  '排列三',
  '排列五',
  '排列3',
  '排列5',
  '排三',
  '排五',
  '排3',
  '排5',
  '七星彩',
  '7星彩',
  '竞彩',
  '竞足',
  '竞篮',
  '足彩',
  '胜负彩',
  '任选九',
  '顶呱刮',
];

const List<String> _welfareKeywords = [
  '双色球',
  '快乐8',
  '快乐八',
  '七乐彩',
  '福彩3d',
  '3d',
  '刮刮乐',
];

const List<String> _scratchKeywords = [
  '刮刮乐',
  '刮刮卡',
  '刮刮彩',
  '刮刮',
  '即开票',
  '即开',
  '顶呱刮',
];

GamblingIssuer classifyGamblingIssuer(String remark) {
  final text = _normalize(remark);
  if (text.isEmpty) {
    return GamblingIssuer.uncategorized;
  }

  // 发行方优先：备注里明确写了体彩/福彩时，以它为准。
  if (text.contains('体彩')) {
    return GamblingIssuer.sports;
  }
  if (text.contains('福彩')) {
    return GamblingIssuer.welfare;
  }

  for (final keyword in _sportsKeywords) {
    if (text.contains(keyword)) {
      return GamblingIssuer.sports;
    }
  }

  for (final keyword in _welfareKeywords) {
    if (text.contains(keyword)) {
      return GamblingIssuer.welfare;
    }
  }

  return GamblingIssuer.uncategorized;
}

GamblingForm classifyGamblingForm(String remark) {
  final text = _normalize(remark);
  for (final keyword in _scratchKeywords) {
    if (text.contains(keyword)) {
      return GamblingForm.scratch;
    }
  }
  return GamblingForm.paper;
}

List<Record> filterRecordsByIssuer(
  Iterable<Record> records,
  GamblingIssuer issuer,
) {
  if (issuer == GamblingIssuer.all) {
    return records.toList(growable: false);
  }
  return records.where((record) {
    return classifyGamblingIssuer(record.remark) == issuer;
  }).toList(growable: false);
}

List<Record> filterRecordsByForm(
  Iterable<Record> records,
  GamblingForm form,
) {
  if (form == GamblingForm.all) {
    return records.toList(growable: false);
  }
  return records.where((record) {
    return classifyGamblingForm(record.remark) == form;
  }).toList(growable: false);
}

class GamblingSummary {
  final double spent;
  final double won;
  final int betCount;
  final int winCount;

  const GamblingSummary({
    this.spent = 0,
    this.won = 0,
    this.betCount = 0,
    this.winCount = 0,
  });

  double get net => won - spent;

  double? get returnRate => spent > 0 ? won / spent : null;

  bool get isEmpty => betCount == 0 && winCount == 0;

  static GamblingSummary fromRecords(Iterable<Record> records) {
    var spent = 0.0;
    var won = 0.0;
    var betCount = 0;
    var winCount = 0;

    for (final record in records) {
      if (record.isExpense) {
        spent += record.amount;
        betCount++;
      } else {
        won += record.amount;
        winCount++;
      }
    }

    return GamblingSummary(
      spent: spent,
      won: won,
      betCount: betCount,
      winCount: winCount,
    );
  }
}

class GamblingMonthStat {
  final DateTime month;
  final double spent;
  final double won;

  const GamblingMonthStat({
    required this.month,
    required this.spent,
    required this.won,
  });
}

List<GamblingMonthStat> buildGamblingMonthlyStats(
  List<Record> records, {
  required DateTime fromMonth,
  required DateTime toMonth,
}) {
  final start = DateTime(fromMonth.year, fromMonth.month);
  final end = DateTime(toMonth.year, toMonth.month);

  final months = <DateTime>[];
  var cursor = start;
  while (!cursor.isAfter(end) && months.length < 24) {
    months.add(cursor);
    cursor = DateTime(cursor.year, cursor.month + 1);
  }

  if (months.length > 12) {
    months.removeRange(0, months.length - 12);
  }

  final result = <GamblingMonthStat>[];
  for (final month in months) {
    var spent = 0.0;
    var won = 0.0;

    for (final record in records) {
      if (record.date.year == month.year && record.date.month == month.month) {
        if (record.isExpense) {
          spent += record.amount;
        } else {
          won += record.amount;
        }
      }
    }

    result.add(GamblingMonthStat(month: month, spent: spent, won: won));
  }

  return result;
}

String _normalize(String value) {
  return value.replaceAll(RegExp(r'\s+'), '').toLowerCase();
}
