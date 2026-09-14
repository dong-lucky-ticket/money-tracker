import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../widgets/common/app_toast.dart';

/// The published prize rules for the two lottery products supported by the app.
///
/// Keeping the rules here makes them available when the user is offline and
/// avoids coupling the announcement detail page to a particular draw.
class LotteryRulesScreen extends StatelessWidget {
  final String lotteryType;

  const LotteryRulesScreen({super.key, required this.lotteryType});

  bool get _isSporttery => lotteryType == '体彩';

  @override
  Widget build(BuildContext context) {
    final title = _isSporttery ? '超级大乐透中奖规则' : '双色球中奖规则';
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          Text(
            _isSporttery ? '超级大乐透（体彩）' : '双色球（福彩）',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '规则依据官方公开发行规则整理，适用于当前标准玩法。',
            style: TextStyle(color: AppColors.textTertiary, height: 1.5),
          ),
          const SizedBox(height: 20),
          _RuleSection(
            title: '奖级与中奖条件',
            child: _isSporttery
                ? const _SuperLottoTable()
                : const _DoubleColorBallTable(),
          ),
          const SizedBox(height: 16),
          _RuleSection(
            title: '玩法说明',
            child: _isSporttery
                ? const _SportteryNotes()
                : const _DoubleColorBallNotes(),
          ),
          const SizedBox(height: 16),
          _RuleSection(
            title: '规则来源',
            child: _SourceInfo(isSporttery: _isSporttery),
          ),
        ],
      ),
    );
  }
}

class _RuleSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _RuleSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _RulesTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;
  final List<TableColumnWidth>? widths;

  const _RulesTable({required this.headers, required this.rows, this.widths});

  @override
  Widget build(BuildContext context) {
    final columnWidths = <int, TableColumnWidth>{};
    if (widths != null) {
      for (var i = 0; i < widths!.length; i++) {
        columnWidths[i] = widths![i];
      }
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        columnWidths: columnWidths,
        border: TableBorder.all(color: AppColors.border),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: const BoxDecoration(color: AppColors.surfaceMuted),
            children:
                headers.map((text) => _RuleCell(text, isHeader: true)).toList(),
          ),
          ...rows.map(
            (row) => TableRow(
              children: row
                  .asMap()
                  .entries
                  .map(
                    (entry) => _RuleCell(
                      entry.value,
                      isCondition: entry.key == 1,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleCell extends StatelessWidget {
  final String text;
  final bool isHeader;
  final bool isCondition;

  const _RuleCell(
    this.text, {
    this.isHeader = false,
    this.isCondition = false,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 76),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: isCondition
            ? _ConditionDisplay(text)
            : Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
                  color: AppColors.textSecondary,
                ),
              ),
      ),
    );
  }
}

class _ConditionDisplay extends StatelessWidget {
  final String condition;

  const _ConditionDisplay(this.condition);

  @override
  Widget build(BuildContext context) {
    final combinations = condition
        .split(RegExp(r'\s*或\s*|\n'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    return Semantics(
      label: condition,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var index = 0; index < combinations.length; index++) ...[
            if (index > 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '或',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            _ConditionCombination(combinations[index]),
          ],
        ],
      ),
    );
  }
}

class _ConditionCombination extends StatelessWidget {
  final String condition;

  const _ConditionCombination(this.condition);

  @override
  Widget build(BuildContext context) {
    final match = RegExp(
      r'(\d+)(?:个前区|个红球)\s*\+\s*(\d+)(?:个后区|个蓝球)',
    ).firstMatch(condition);
    if (match == null) {
      return Text(
        condition,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      );
    }
    final frontCount = int.parse(match.group(1)!);
    final backCount = int.parse(match.group(2)!);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < frontCount; i++)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: _RuleBall(color: AppColors.danger),
          ),
        for (var i = 0; i < backCount; i++)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: _RuleBall(color: AppColors.primary),
          ),
      ],
    );
  }
}

class _RuleBall extends StatelessWidget {
  final Color color;

  const _RuleBall({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _SuperLottoTable extends StatelessWidget {
  const _SuperLottoTable();

  @override
  Widget build(BuildContext context) {
    return const _RulesTable(
      headers: ['奖级', '中奖条件', '奖池8亿以下', '奖池8亿及以上'],
      widths: [
        IntrinsicColumnWidth(),
        IntrinsicColumnWidth(),
        IntrinsicColumnWidth(),
        IntrinsicColumnWidth(),
      ],
      rows: [
        ['一等奖', '5个前区 + 2个后区', '浮动奖', '浮动奖'],
        ['二等奖', '5个前区 + 1个后区', '浮动奖', '浮动奖'],
        ['三等奖', '5个前区 + 0个后区\n或 4个前区 + 2个后区', '5,000元', '6,666元'],
        ['四等奖', '4个前区 + 1个后区\n或 3个前区 + 2个后区', '300元', '380元'],
        ['五等奖', '4个前区 + 0个后区\n或 3个前区 + 1个后区\n或 2个前区 + 2个后区', '150元', '200元'],
        ['六等奖', '3个前区 + 1个后区\n或 2个前区 + 2个后区', '15元', '18元'],
        [
          '七等奖',
          '3个前区 + 0个后区\n或 2个前区 + 1个后区\n或 1个前区 + 2个后区\n或 0个前区 + 2个后区',
          '5元',
          '7元'
        ],
      ],
    );
  }
}

class _DoubleColorBallTable extends StatelessWidget {
  const _DoubleColorBallTable();

  @override
  Widget build(BuildContext context) {
    return const _RulesTable(
      headers: ['奖级', '中奖条件', '单注奖金'],
      widths: [
        IntrinsicColumnWidth(),
        IntrinsicColumnWidth(),
        IntrinsicColumnWidth(),
      ],
      rows: [
        ['一等奖', '6个红球 + 1个蓝球', '浮动奖'],
        ['二等奖', '6个红球 + 0个蓝球', '浮动奖'],
        ['三等奖', '5个红球 + 1个蓝球', '3000元'],
        ['四等奖', '5个红球 + 0个蓝球\n或 4个红球 + 1个蓝球', '200元'],
        ['五等奖', '4个红球 + 0个蓝球\n或 3个红球 + 1个蓝球', '10元'],
        ['六等奖', '2个红球 + 1个蓝球\n或 1个红球 + 1个蓝球\n或 0个红球 + 1个蓝球', '5元'],
      ],
    );
  }
}

class _SportteryNotes extends StatelessWidget {
  const _SportteryNotes();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '每注从前区01-35中选5个号码、后区01-12中选2个号码。基本投注每注2元，追加投注每注另加1元；追加投注中奖时，追加奖金按官方规则另行计算。\n\n一等奖奖金由当期奖级奖金的75%与奖池资金组成（奖池超过1亿元时按官方比例分配），单注最高限额500万元。三至七等奖按奖池金额分档派发。',
      style: TextStyle(color: AppColors.textSecondary, height: 1.65),
    );
  }
}

class _DoubleColorBallNotes extends StatelessWidget {
  const _DoubleColorBallNotes();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '每注从红球01-33中选6个号码，从蓝球01-16中选1个号码。一等奖和二等奖为浮动奖，奖金取决于当期奖池和中奖注数；三至六等奖为固定奖。单注投注金额2元。',
      style: TextStyle(color: AppColors.textSecondary, height: 1.65),
    );
  }
}

class _SourceInfo extends StatelessWidget {
  final bool isSporttery;

  const _SourceInfo({required this.isSporttery});

  @override
  Widget build(BuildContext context) {
    final source = isSporttery ? '国家体育总局体育彩票管理中心、江苏体彩网' : '中国福利彩票发行管理中心、中国福彩网';
    final url = isSporttery
        ? 'https://www.lottery.gov.cn/dlt/rule.html'
        : 'https://www.cwl.gov.cn/fcpz/ywxx/ssq/gz/';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('来源：$source',
            style:
                const TextStyle(color: AppColors.textSecondary, height: 1.5)),
        const SizedBox(height: 4),
        const Text('规则抓取日期：2026-09-14',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
        const SizedBox(height: 4),
        Tooltip(
          message: '点击复制规则地址',
          child: InkWell(
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (context.mounted) {
                AppToast.showSuccess(context, '规则地址已复制');
              }
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.copy_outlined,
                      size: 15,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      url,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        height: 1.4,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
