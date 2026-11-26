

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../models/record.dart';
import '../providers/data_provider.dart';
import '../theme/app_colors.dart';
import '../utils/gambling_stats.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/segmented_selector.dart';
import '../widgets/edit_record_sheet.dart';

enum _TimePreset { all, recent1, recent3, recent6, thisYear, custom }

class GamblingStatsScreen extends StatefulWidget {
  const GamblingStatsScreen({super.key});

  @override
  State<GamblingStatsScreen> createState() => _GamblingStatsScreenState();
}

class _GamblingStatsScreenState extends State<GamblingStatsScreen> {
  GamblingIssuer _issuer = GamblingIssuer.all;
  _TimePreset _timePreset = _TimePreset.all;
  DateTimeRange? _customRange;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('赌狗统计'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: '识别规则',
            onPressed: _showRuleDialog,
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      body: Consumer<DataProvider>(
        builder: (context, provider, child) {
          final lotteryRecords = collectLotteryRecords(provider.records);
          if (lotteryRecords.isEmpty) {
            return _buildEmptyState();
          }

          final hasUncategorized = lotteryRecords.any((record) {
            return classifyGamblingIssuer(record.remark) ==
                GamblingIssuer.uncategorized;
          });

          final timeFiltered = _applyTimeFilter(lotteryRecords);
          final issuerFiltered = filterRecordsByIssuer(timeFiltered, _issuer);
          final scopeRecords = issuerFiltered;
          final scopeSummary = GamblingSummary.fromRecords(scopeRecords);
          final listRecords = List<Record>.from(scopeRecords)
            ..sort((a, b) => b.date.compareTo(a.date));

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            physics: const BouncingScrollPhysics(),
            children: [
              _buildRuleBanner(),
              const SizedBox(height: 16),
              _buildTimeFilter(),
              const SizedBox(height: 16),
              _buildIssuerSelector(hasUncategorized),
              const SizedBox(height: 16),
              _buildOverviewCard(scopeSummary),
              if (_issuer == GamblingIssuer.all) ...[
                const SizedBox(height: 16),
                _buildIssuerCards(timeFiltered, hasUncategorized),
              ],

              const SizedBox(height: 16),
              _buildFormCards(timeFiltered),
              const SizedBox(height: 16),
              _buildTrendCard(scopeRecords),
              const SizedBox(height: 16),
              _buildRecordsSection(listRecords, provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
      icon: Icon(
        MdiIcons.ticketOutline,
        size: 64,
        color: AppColors.border,
      ),
      title: '还没有彩票相关的账单',
      subtitle: '在“彩票 / 彩票”分类下记账，备注“体彩/福彩”，即可在这里统计投入与中回。',
    );
  }

  Widget _buildRuleBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.rule_outlined,
            size: 18,
            color: AppColors.primary,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '统计“彩票”分类下的账单，按备注自动区分体彩/福彩，识别时体彩/福彩优先。',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final preset in _TimePreset.values) ...[
            _buildTimeChip(preset),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeChip(_TimePreset preset) {
    final selected = _timePreset == preset;
    return GestureDetector(
      onTap: () {
        if (preset == _TimePreset.custom) {
          _pickCustomRange();
          return;
        }
        setState(() {
          _timePreset = preset;
          _customRange = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          _timeChipLabel(preset),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildIssuerSelector(bool hasUncategorized) {
    return SegmentedSelector<GamblingIssuer>(
      value: _issuer,
      onChanged: (issuer) {
        setState(() {
          _issuer = issuer;
        });
      },
      options: [
        const SegmentedOption(value: GamblingIssuer.all, label: '全部'),
        const SegmentedOption(value: GamblingIssuer.sports, label: '体彩'),
        const SegmentedOption(value: GamblingIssuer.welfare, label: '福彩'),
        if (hasUncategorized)
          const SegmentedOption(
            value: GamblingIssuer.uncategorized,
            label: '未分类',
          ),
      ],
    );
  }

  Widget _buildOverviewCard(GamblingSummary summary) {
    return AppCard(
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '净收益',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _signedMoney(summary.net),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: _netColor(summary.net),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMiniMetric('总投入', _money(summary.spent), AppColors.danger),
              _buildMiniMetric('中回', _money(summary.won), AppColors.success),
              _buildMiniMetric('回报率', _rateText(summary.returnRate), AppColors.textPrimary),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '投注 ${summary.betCount} 笔 · 中奖 ${summary.winCount} 笔'
            '${summary.isEmpty ? '（当前筛选无流水）' : ''}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssuerCards(List<Record> timeFiltered, bool hasUncategorized) {
    final candidates = [
      GamblingIssuer.sports,
      GamblingIssuer.welfare,
      if (hasUncategorized) GamblingIssuer.uncategorized,
    ];

    return Row(
      children: [
        for (final issuer in candidates) ...[
          Expanded(
            child: _buildIssuerCard(
              issuer,
              GamblingSummary.fromRecords(
                filterRecordsByIssuer(
                  timeFiltered,
                  issuer,
                ),
              ),
            ),
          ),
          if (issuer != candidates.last) const SizedBox(width: 10),
        ],
      ],
    );
  }

  Widget _buildIssuerCard(GamblingIssuer issuer, GamblingSummary summary) {
    final accent = switch (issuer) {
      GamblingIssuer.sports => AppColors.primary,
      GamblingIssuer.welfare => AppColors.danger,
      _ => AppColors.textMuted,
    };
    final icon = switch (issuer) {
      GamblingIssuer.sports => Icons.sports_football_outlined,
      GamblingIssuer.welfare => Icons.favorite_border,
      _ => Icons.help_outline,
    };

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        setState(() {
          _issuer = issuer;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: accent),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    issuer.label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _signedMoney(summary.net),
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: _netColor(summary.net),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '投 ${_money(summary.spent)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '中 ${_money(summary.won)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCards(List<Record> records) {
    return Row(
      children: [
        Expanded(
          child: _buildFormCard(
            GamblingForm.scratch,
            GamblingSummary.fromRecords(
              filterRecordsByForm(
                filterRecordsByIssuer(records, _issuer),
                GamblingForm.scratch,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildFormCard(
            GamblingForm.paper,
            GamblingSummary.fromRecords(
              filterRecordsByForm(
                filterRecordsByIssuer(records, _issuer),
                GamblingForm.paper,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(GamblingForm form, GamblingSummary summary) {
    final isScratch = form == GamblingForm.scratch;
    final accent = isScratch ? AppColors.warning : AppColors.primary;
    final icon = isScratch
        ? Icons.auto_awesome_outlined
        : Icons.receipt_long_outlined;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: accent),
              const SizedBox(width: 6),
              Text(
                form.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _signedMoney(summary.net),
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: _netColor(summary.net),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '投 ${_money(summary.spent)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '中 ${_money(summary.won)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildTrendCard(List<Record> records) {
    final range = _effectiveRange();
    final now = DateTime.now();

    late DateTime fromMonth;
    late DateTime toMonth;
    String subtitle;

    if (range == null) {
      final latest = _latestMonthOf(records) ?? DateTime(now.year, now.month);
      toMonth = latest;
      fromMonth = DateTime(latest.year, latest.month - 5);
      subtitle = '全部时间 · 近6个月';
    } else {
      fromMonth = DateTime(range.start.year, range.start.month);
      toMonth = DateTime(range.end.year, range.end.month);
      subtitle = range == _customRange
          ? '${_shortDate(range.start)} ~ ${_shortDate(range.end)}'
          : _timeChipLabel(_timePreset);
    }

    final trend = buildGamblingMonthlyStats(
      records,
      fromMonth: fromMonth,
      toMonth: toMonth,
    );

    var maxValue = 0.0;
    for (final month in trend) {
      if (month.spent > maxValue) maxValue = month.spent;
      if (month.won > maxValue) maxValue = month.won;
    }
    if (maxValue <= 0) {
      maxValue = 100;
    }

    return AppCard(
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '投入 / 中回走势',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildLegendDot('投入', AppColors.danger),
              const SizedBox(width: 16),
              _buildLegendDot('中回', AppColors.success),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue * 1.15,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.black87,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final month = trend[group.x];
                      final label = rodIndex == 0
                          ? '投入 ${_money(month.spent)}'
                          : '中回 ${_money(month.won)}';
                      return BarTooltipItem(
                        '${_monthLabel(month.month)}\n$label',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxValue / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.black.withOpacity(0.05),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) {
                          return const SizedBox();
                        }
                        return Text(
                          value >= 1000
                              ? '${(value / 1000).toStringAsFixed(1)}k'
                              : value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) {
                        if (value < 0 || value >= trend.length) {
                          return const SizedBox();
                        }
                        final index = value.toInt();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _monthLabel(trend[index].month),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  for (var index = 0; index < trend.length; index++)
                    BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: trend[index].spent,
                          color: AppColors.danger,
                          width: 9,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(3),
                            topRight: Radius.circular(3),
                          ),
                        ),
                        BarChartRodData(
                          toY: trend[index].won,
                          color: AppColors.success,
                          width: 9,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(3),
                            topRight: Radius.circular(3),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordsSection(List<Record> records, DataProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '流水明细',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${records.length} 笔',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (records.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                '该筛选条件下暂无流水',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ),
          )
        else
          ...records.map((record) => _buildRecordRow(record, provider)),
      ],
    );
  }

  Widget _buildRecordRow(Record record, DataProvider provider) {
    final issuer = classifyGamblingIssuer(record.remark);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => EditRecordSheet(record: record, provider: provider),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    '${record.date.month.toString().padLeft(2, '0')}/${record.date.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildBadge(issuer.label, _issuerBadgeColor(issuer)),
                      Text(
                        record.isExpense ? '支出' : '收入',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  if (record.remark.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      record.remark,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${record.isExpense ? '-' : '+'}${record.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: record.isExpense ? AppColors.danger : AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Color _issuerBadgeColor(GamblingIssuer issuer) {
    switch (issuer) {
      case GamblingIssuer.sports:
        return AppColors.primary;
      case GamblingIssuer.welfare:
        return AppColors.danger;
      case GamblingIssuer.uncategorized:
      case GamblingIssuer.all:
        return AppColors.textMuted;
    }
  }

  List<Record> _applyTimeFilter(List<Record> records) {
    final range = _effectiveRange();
    if (range == null) {
      return records;
    }
    return records.where((record) {
      return !record.date.isBefore(range.start) &&
          !record.date.isAfter(range.end);
    }).toList(growable: false);
  }

  DateTimeRange? _effectiveRange() {
    final now = DateTime.now();
    switch (_timePreset) {
      case _TimePreset.all:
        return null;
      case _TimePreset.recent1:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );
      case _TimePreset.recent3:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 90)),
          end: now,
        );
      case _TimePreset.recent6:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 180)),
          end: now,
        );
      case _TimePreset.thisYear:
        return DateTimeRange(
          start: DateTime(now.year, 1),
          end: now,
        );
      case _TimePreset.custom:
        return _customRange;
    }
  }

  String _timeChipLabel(_TimePreset preset) {
    switch (preset) {
      case _TimePreset.all:
        return '全部时间';
      case _TimePreset.recent1:
        return '近1月';
      case _TimePreset.recent3:
        return '近3月';
      case _TimePreset.recent6:
        return '近6月';
      case _TimePreset.thisYear:
        return '今年';
      case _TimePreset.custom:
        return _customRange == null
            ? '自定义'
            : '${_shortDate(_customRange!.start)} ~ ${_shortDate(_customRange!.end)}';
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final initial = _customRange ??
        DateTimeRange(
          start: DateTime(now.year, 1),
          end: now,
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: initial,
      saveText: '应用',
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _timePreset = _TimePreset.custom;
      _customRange = picked;
    });
  }

  DateTime? _latestMonthOf(List<Record> records) {
    if (records.isEmpty) {
      return null;
    }
    var latest = records.first.date;
    for (final record in records) {
      if (record.date.isAfter(latest)) {
        latest = record.date;
      }
    }
    return DateTime(latest.year, latest.month);
  }

  Color _netColor(double net) {
    if (net > 0) {
      return AppColors.success;
    }
    if (net < 0) {
      return AppColors.danger;
    }
    return AppColors.textSecondary;
  }

  String _money(double value) {
    return '¥${value.abs().toStringAsFixed(2)}';
  }

  String _signedMoney(double value) {
    if (value > 0) {
      return '+${_money(value)}';
    }
    if (value < 0) {
      return '-${_money(value)}';
    }
    return _money(0);
  }

  String _rateText(double? rate) {
    if (rate == null) {
      return '--';
    }
    return '${(rate * 100).toStringAsFixed(1)}%';
  }

  String _monthLabel(DateTime month) {
    return '${month.month}月';
  }

  String _shortDate(DateTime date) {
    return '${date.month}.${date.day}';
  }

  void _showRuleDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('识别规则'),
          content: const Text(
            '本模块统计“彩票”（支出）与“彩票”（收入）分类下的有效账单，并按备注区分体彩/福彩：\n\n'
            '体彩：备注含“体彩、大乐透、排列三/五、七星彩、竞彩、足彩、顶呱刮”等归体彩。\n\n'
            '福彩：备注含“福彩、双色球、快乐8、七乐彩、3D、刮刮乐”等归福彩；否则为未分类。',
            style: TextStyle(fontSize: 14, height: 1.6),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('知道了'),
            ),
          ],
        );
      },
    );
  }
}








