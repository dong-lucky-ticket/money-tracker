import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/super_lotto_draw.dart';
import '../theme/app_colors.dart';

class SuperLottoAnnouncementScreen extends StatelessWidget {
  final SuperLottoDraw draw;

  const SuperLottoAnnouncementScreen({super.key, required this.draw});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text('第${draw.issue}期开奖公告'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(
            '超级大乐透',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '发布日期 ${DateFormat('yyyy-MM-dd').format(draw.publishDate)}',
            style: const TextStyle(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 20),
          _AnnouncementSection(
            title: '开奖号码',
            child: _NumberGroups(draw: draw),
          ),
          const SizedBox(height: 16),
          _AnnouncementSection(
            title: '开奖信息',
            child: Column(
              children: [
                _InfoRow(label: '开奖时间', value: draw.drawTime ?? '公告未提供'),
                _InfoRow(label: '开奖地点', value: draw.drawLocation ?? '公告未提供'),
                _InfoRow(
                    label: '公告链接', value: draw.announcementUrl, isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _AnnouncementSection(
            title: '本期中奖情况',
            child: draw.prizeTiers.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      '该期中奖表格暂未解析成功。',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                  )
                : _PrizeTierTable(tiers: draw.prizeTiers),
          ),
          if (draw.winnerSummary != null) ...[
            const SizedBox(height: 16),
            _AnnouncementSection(
              title: '一等奖出自',
              child: Text(
                draw.winnerSummary!,
                style: const TextStyle(
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnnouncementSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _AnnouncementSection({required this.title, required this.child});

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
          padding: const EdgeInsets.all(16),
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

class _NumberGroups extends StatelessWidget {
  final SuperLottoDraw draw;

  const _NumberGroups({required this.draw});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('本期开奖号码', style: TextStyle(color: AppColors.textTertiary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...draw.frontNumbers.map(
              (number) => _LotteryBall(number: number, color: AppColors.danger),
            ),
            ...draw.backNumbers.map(
              (number) =>
                  _LotteryBall(number: number, color: AppColors.primary),
            ),
          ],
        ),
        if (draw.drawOrderNumbers.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('本期出球顺序', style: TextStyle(color: AppColors.textTertiary)),
          const SizedBox(height: 8),
          Text(
            draw.drawOrderNumbers.join('  '),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label,
                style: const TextStyle(color: AppColors.textTertiary)),
          ),
          Expanded(
            child: Text(
              value,
              style:
                  const TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrizeTierTable extends StatelessWidget {
  final List<SuperLottoPrizeTier> tiers;

  const _PrizeTierTable({required this.tiers});

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.15),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1.25),
        3: FlexColumnWidth(1.45),
      },
      border: TableBorder.all(color: AppColors.border),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        const TableRow(
          decoration: BoxDecoration(color: AppColors.surfaceMuted),
          children: [
            _TableCell('奖级', isHeader: true),
            _TableCell('中奖注数', isHeader: true),
            _TableCell('单注奖金', isHeader: true),
            _TableCell('应派奖金合计', isHeader: true),
          ],
        ),
        ...tiers.map(
          (tier) => TableRow(
            children: [
              _TableCell(tier.level),
              _TableCell(tier.betCount),
              _TableCell(tier.singlePrize),
              _TableCell(tier.totalPrize),
            ],
          ),
        ),
      ],
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final bool isHeader;

  const _TableCell(this.text, {this.isHeader = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _LotteryBall extends StatelessWidget {
  final String number;
  final Color color;

  const _LotteryBall({required this.number, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        number,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
