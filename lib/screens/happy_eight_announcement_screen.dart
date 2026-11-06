import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/happy_eight_draw.dart';
import '../theme/app_colors.dart';
import '../widgets/common/app_toast.dart';

class HappyEightAnnouncementScreen extends StatefulWidget {
  final HappyEightDraw draw;
  final List<HappyEightDraw> draws;

  const HappyEightAnnouncementScreen({
    super.key,
    required this.draw,
    this.draws = const [],
  });

  @override
  State<HappyEightAnnouncementScreen> createState() =>
      _HappyEightAnnouncementScreenState();
}

class _HappyEightAnnouncementScreenState
    extends State<HappyEightAnnouncementScreen> {
  static const _switchThreshold = 72.0;
  late final List<HappyEightDraw> _draws;
  late final PageController _pageController;
  late int _currentIndex;
  double _overscrollDistance = 0;
  int? _overscrollDirection;
  bool _isSwitching = false;

  @override
  void initState() {
    super.initState();
    _draws = widget.draws.isEmpty ? [widget.draw] : widget.draws;
    _currentIndex =
        _draws.indexWhere((item) => item.issue == widget.draw.issue);
    if (_currentIndex < 0) _currentIndex = 0;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification) {
      _overscrollDistance = 0;
      _overscrollDirection = null;
    }
    if (notification is! OverscrollNotification || _isSwitching) return false;

    final isAtTop =
        notification.metrics.pixels <= notification.metrics.minScrollExtent;
    final isAtBottom =
        notification.metrics.pixels >= notification.metrics.maxScrollExtent;
    final direction = notification.overscroll < 0 && isAtTop
        ? -1
        : notification.overscroll > 0 && isAtBottom
            ? 1
            : 0;
    if (direction == 0 ||
        _currentIndex + direction < 0 ||
        _currentIndex + direction >= _draws.length) {
      return false;
    }

    if (_overscrollDirection != direction) {
      _overscrollDirection = direction;
      _overscrollDistance = 0;
    }
    _overscrollDistance += notification.overscroll.abs();
    if (_overscrollDistance >= _switchThreshold) {
      _isSwitching = true;
      _overscrollDistance = 0;
      _pageController
          .animateToPage(
            _currentIndex + direction,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          )
          .whenComplete(() => _isSwitching = false);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final draw = _draws[_currentIndex];
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text('第${draw.issue}期开奖公告'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _draws.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
            _overscrollDistance = 0;
            _overscrollDirection = null;
          });
        },
        itemBuilder: (context, index) =>
            NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: _AnnouncementBody(draw: _draws[index]),
        ),
      ),
    );
  }
}

class _AnnouncementBody extends StatelessWidget {
  final HappyEightDraw draw;

  const _AnnouncementBody({required this.draw});

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: PageStorageKey('happy-eight-${draw.issue}'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text(
          '福彩快乐8',
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
          title: '本期中奖情况',
          child: draw.prizeTiers.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    '该期中奖数据暂未返回。',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textTertiary),
                  ),
                )
              : _PrizeTierTable(tiers: draw.prizeTiers),
        ),
        const SizedBox(height: 16),
        _AnnouncementSection(
          title: '“选十中十”中奖情况：',
          child: _TopPrizeSummary(draw: draw),
        ),
        if (draw.salesAmount != null || draw.poolAmount != null) ...[
          const SizedBox(height: 16),
          _AnnouncementSection(
            title: '开奖信息',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (draw.salesAmount != null)
                  Text('本期销售额：${_money(draw.salesAmount!)} 元'),
                if (draw.poolAmount != null)
                  Text('奖池金额：${_money(draw.poolAmount!)} 元'),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        _AnnouncementSection(
          title: '公告链接',
          child: Tooltip(
            message: '点击复制',
            child: GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: draw.announcementUrl));
                AppToast.showSuccess(context, '公告链接已复制');
              },
              child: Text(
                draw.announcementUrl,
                style: const TextStyle(
                  color: AppColors.primary,
                  height: 1.5,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),
      ],
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
  final HappyEightDraw draw;

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
          children: draw.numbers
              .map((number) => _LotteryBall(number: number))
              .toList(),
        ),
      ],
    );
  }
}

class _TopPrizeSummary extends StatelessWidget {
  final HappyEightDraw draw;

  const _TopPrizeSummary({required this.draw});

  @override
  Widget build(BuildContext context) {
    final announcement = draw.winnerContent;
    if (announcement != null) {
      return Text(
        announcement,
        style: const TextStyle(
          height: 1.6,
          color: AppColors.textSecondary,
        ),
      );
    }

    HappyEightPrizeTier? topPrize;
    for (final tier in draw.prizeTiers) {
      if (tier.play == 'x10z10') {
        topPrize = tier;
        break;
      }
    }
    if (topPrize == null) {
      return const Text('该期选十中十中奖数据暂未返回。',
          style: TextStyle(color: AppColors.textTertiary));
    }

    final winnerCount = int.tryParse(topPrize.betCount.replaceAll(',', ''));
    if (winnerCount == 0) {
      return const Text('本期暂无选十中十中奖记录。',
          style: TextStyle(color: AppColors.textTertiary));
    }
    return const Text('该期中奖说明暂未返回。',
        style: TextStyle(color: AppColors.textTertiary));
  }
}

class _PrizeTierTable extends StatelessWidget {
  final List<HappyEightPrizeTier> tiers;

  const _PrizeTierTable({required this.tiers});

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(1.2),
        2: FlexColumnWidth(1.6),
      },
      border: TableBorder.all(color: AppColors.border),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        const TableRow(
          decoration: BoxDecoration(color: AppColors.surfaceMuted),
          children: [
            _TableCell('玩法', isHeader: true),
            _TableCell('中奖注数', isHeader: true),
            _TableCell('单注奖金', isHeader: true),
          ],
        ),
        ...tiers.map(
          (tier) => TableRow(
            children: [
              _TableCell(_playName(tier.play)),
              _TableCell(_money(tier.betCount)),
              _TableCell('${_money(tier.singlePrize)} 元'),
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

  const _LotteryBall({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.danger,
        shape: BoxShape.circle,
      ),
      child: Text(
        number,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}

String _money(String value) =>
    value.replaceAllMapped(RegExp(r'(?<!^)(?=(\d{3})+(?!\d))'), (_) => ',');

String _playName(String play) {
  final match = RegExp(r'x(\d+)z(\d+)').firstMatch(play);
  if (match == null) return play;
  return '${match.group(1)}选${match.group(2)}中';
}
