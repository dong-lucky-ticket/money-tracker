import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/double_color_ball_draw.dart';
import '../models/happy_eight_draw.dart';
import '../models/lottery_simulation.dart';
import '../models/qilecai_draw.dart';
import '../models/seven_star_draw.dart';
import '../models/super_lotto_draw.dart';
import '../services/double_color_ball_repository.dart';
import '../services/happy_eight_repository.dart';
import '../services/qilecai_repository.dart';
import '../services/seven_star_repository.dart';
import '../services/super_lotto_repository.dart';
import '../theme/app_colors.dart';
import '../utils/simulation_prize_match.dart';
import '../widgets/lottery/simulation_ticket_numbers.dart';
import 'lottery_rules_screen.dart';

class _HistoricalDraw {
  final String issue;
  final DateTime date;
  final List<int> primary;
  final List<int> secondary;

  const _HistoricalDraw(this.issue, this.date, this.primary,
      [this.secondary = const []]);
}

class HistoricalRecordMatchScreen extends StatefulWidget {
  final SimulationRecord record;

  const HistoricalRecordMatchScreen({super.key, required this.record});

  @override
  State<HistoricalRecordMatchScreen> createState() =>
      _HistoricalRecordMatchScreenState();
}

class _HistoricalRecordMatchScreenState extends State<HistoricalRecordMatchScreen> {
  static const _blue = Color(0xFF1D67D4);
  static const _summaryHighlight = Color(0xFFE5737A);
  List<_HistoricalDraw> _draws = const [];
  bool _loading = true;
  bool _winnersOnly = false;
  bool _numbersExpanded = true;
  int? _limit = 30;

  @override
  void initState() {
    super.initState();
    _loadDraws();
  }

  Future<void> _loadDraws() async {
    setState(() => _loading = true);
    try {
      final lottery = widget.record.lottery;
      late final List<_HistoricalDraw> draws;
      switch (lottery) {
        case SimulationLottery.superLotto:
          final items = await SuperLottoRepository().loadRecent(limit: _limit);
          draws = items.map(_superLotto).toList();
        case SimulationLottery.doubleColorBall:
          final items =
              await DoubleColorBallRepository().loadRecent(limit: _limit);
          draws = items.map(_doubleColorBall).toList();
        case SimulationLottery.sevenStar:
          final items = await SevenStarRepository().loadRecent(limit: _limit);
          draws = items.map(_sevenStar).toList();
        case SimulationLottery.happyEight:
          final items = await HappyEightRepository().loadRecent(limit: _limit);
          draws = items.map(_happyEight).toList();
        case SimulationLottery.qilecai:
          final items = await QilecaiRepository().loadRecent(limit: _limit);
          draws = items.map(_qilecai).toList();
      }
      if (mounted) {
        setState(() {
          _draws = draws;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _draws = const [];
          _loading = false;
        });
      }
    }
  }

  _HistoricalDraw _superLotto(SuperLottoDraw draw) => _HistoricalDraw(
      draw.issue, draw.publishDate, _numbers(draw.frontNumbers),
      _numbers(draw.backNumbers));
  _HistoricalDraw _doubleColorBall(DoubleColorBallDraw draw) => _HistoricalDraw(
      draw.issue, draw.publishDate, _numbers(draw.redNumbers),
      _numbers([draw.blueNumber]));
  _HistoricalDraw _sevenStar(SevenStarDraw draw) => _HistoricalDraw(
      draw.issue, draw.publishDate, _numbers(draw.numbers.take(6).toList()),
      _numbers(draw.numbers.skip(6).take(1).toList()));
  _HistoricalDraw _happyEight(HappyEightDraw draw) =>
      _HistoricalDraw(draw.issue, draw.publishDate, _numbers(draw.numbers));
  _HistoricalDraw _qilecai(QilecaiDraw draw) => _HistoricalDraw(
      draw.issue, draw.publishDate, _numbers(draw.redNumbers),
      _numbers([draw.blueNumber]));
  List<int> _numbers(List<String> values) =>
      values.map((value) => int.tryParse(value) ?? -1).toList();

  String? _prizeLabel(_HistoricalDraw draw) {
    String? best;
    for (final ticket in widget.record.tickets) {
      final label = simulationPrizeLabel(
          ticket: ticket,
          primaryDraw: draw.primary,
          secondaryDraw: draw.secondary);
      if (label == null) continue;
      if (best == null || _prizeRank(label) < _prizeRank(best)) best = label;
    }
    return best;
  }

  SimulationTicket? _winningTicket(_HistoricalDraw draw) {
    SimulationTicket? bestTicket;
    String? best;
    for (final ticket in widget.record.tickets) {
      final label = simulationPrizeLabel(
          ticket: ticket,
          primaryDraw: draw.primary,
          secondaryDraw: draw.secondary);
      if (label == null) continue;
      if (best == null || _prizeRank(label) < _prizeRank(best)) {
        best = label;
        bestTicket = ticket;
      }
    }
    return bestTicket;
  }

  int _prizeRank(String label) {
    if (label.startsWith('中')) {
      return -int.parse(label.substring(1, label.length - 1));
    }
    const ranks = {'一': 1, '二': 2, '三': 3, '四': 4, '五': 5, '六': 6, '七': 7};
    return ranks[label.substring(0, 1)] ?? 99;
  }

  List<_HistoricalDraw> get _visibleDraws => _draws
      .where((draw) => !_winnersOnly || _prizeLabel(draw) != null)
      .toList();

  void _openRules() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LotteryRulesScreen(lotteryType: widget.record.lottery.label),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleDraws;
    final winningDraws =
        _draws.map((draw) => _prizeLabel(draw)).whereType<String>().toList();
    final bestPrize = winningDraws.isEmpty
        ? null
        : winningDraws.reduce((best, current) =>
            _prizeRank(current) < _prizeRank(best) ? current : best);
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('历史中奖匹配'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          TextButton.icon(
            onPressed: _openRules,
            style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimary),
            icon: const Icon(Icons.menu_book, size: 18),
            label: const Text('中奖规则'),
          ),
        ],
      ),
      body: Column(children: [
        _buildCurrentSelection(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Row(children: [
            PopupMenuButton<int?>(
              tooltip: '选择历史期数',
              onSelected: (value) {
                setState(() => _limit = value);
                _loadDraws();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 30, child: Text('最近30期')),
                PopupMenuItem(value: 50, child: Text('最近50期')),
                PopupMenuItem(value: 100, child: Text('最近100期')),
                PopupMenuItem(value: null, child: Text('全部已缓存')),
              ],
              child: Row(children: [
                Text(_limit == null ? '全部已缓存' : '最近$_limit期',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const Icon(Icons.arrow_drop_down),
              ]),
            ),
            const Spacer(),
            const Text('只显示中奖期次',
                style: TextStyle(color: AppColors.textSecondary)),
            Switch.adaptive(
                value: _winnersOnly,
                activeColor: _blue,
                onChanged: (value) =>
                    setState(() => _winnersOnly = value)),
          ]),
        ),
        Container(
          width: double.infinity,
          color: const Color(0xFFF3F5F7),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          child: _loading
              ? const Text('正在读取本地开奖记录…',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 14))
              : _draws.isEmpty
                  ? const Text('暂无本地开奖记录',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 14))
                  : Text.rich(
                      TextSpan(
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 14),
                        children: [
                          TextSpan(text: '已匹配${_draws.length}期 · '),
                          TextSpan(
                            text: bestPrize == null
                                ? '最高未中奖'
                                : bestPrize.startsWith('中')
                                    ? '最高$bestPrize'
                                    : '最高中$bestPrize',
                            style: const TextStyle(
                                color: _summaryHighlight,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
        ),
        Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _draws.isEmpty
                    ? _empty('暂无本地开奖记录', '先在开奖页面同步该彩种的历史数据')
                    : visible.isEmpty
                        ? _empty('没有中奖期次', '关闭“只显示中奖期次”查看全部结果')
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                            itemCount: visible.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, index) =>
                                _drawRow(visible[index]),
                          )),
      ]),
    );
  }

  Widget _buildCurrentSelection() {
    final record = widget.record;
    return Container(
      color: _blue,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _numbersExpanded = !_numbersExpanded),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  const Expanded(
                      child: Text('已选号码',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13))),
                  Text(record.lottery.label,
                      style: const TextStyle(
                          color: AppColors.textTertiary, fontSize: 12)),
                  const SizedBox(width: 6),
                  Icon(
                    _numbersExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                ]),
              ),
            ),
            if (_numbersExpanded) ...[
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.34),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (var i = 0; i < record.tickets.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        _ticketTile(record, i),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _ticketTile(SimulationRecord record, int displayIndex) {
    final ticketIndex = record.tickets.length - 1 - displayIndex;
    final ticket = record.tickets[ticketIndex];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 22,
              child: Text('${displayIndex + 1}',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700))),
          const SizedBox(width: 10),
          Expanded(child: SimulationTicketNumbers(ticket: ticket)),
        ],
      ),
    );
  }

  Widget _empty(String title, String subtitle) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.history, size: 36, color: AppColors.textMuted),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          Text(subtitle,
              style:
                  const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
        ]),
      );

  Widget _drawRow(_HistoricalDraw draw) {
    final prize = _prizeLabel(draw);
    final winning = prize != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('第${draw.issue}期',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 10),
          Text(DateFormat('yyyy-MM-dd').format(draw.date),
              style:
                  const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
          const Spacer(),
          Text(prize ?? '未中奖',
              style: TextStyle(
                  fontSize: winning ? 13 : 12,
                  color:
                      winning ? _summaryHighlight : AppColors.textTertiary,
                  fontWeight: winning ? FontWeight.w700 : FontWeight.normal)),
        ]),
        const SizedBox(height: 11),
        if (widget.record.lottery == SimulationLottery.sevenStar)
          _sevenStarBalls(draw)
        else
          _drawBalls(draw),
      ]),
    );
  }

  Widget _drawBalls(_HistoricalDraw draw) {
    final winning = _winningTicket(draw);
    final lottery = widget.record.lottery;
    final primaryColor = lottery == SimulationLottery.doubleColorBall ||
            lottery == SimulationLottery.qilecai
        ? AppColors.danger
        : const Color(0xFF4A9BD6);
    const spacing = 5.0;
    const groupSpacing = 12.0;
    const minSize = 24.0;
    const defaultSize = 34.0;
    final balls = <(int, Color, bool)>[
      for (final number in draw.primary)
        (number, primaryColor, winning?.primary.contains(number) ?? false),
      for (final number in draw.secondary)
        (
          number,
          const Color(0xFFE7A51B),
          lottery == SimulationLottery.qilecai
              ? (winning?.primary.contains(number) ?? false)
              : (winning?.secondary.contains(number) ?? false)
        ),
    ];
    final gaps = (balls.length > 1 ? (balls.length - 1) * spacing : 0) +
        (draw.primary.isNotEmpty && draw.secondary.isNotEmpty
            ? groupSpacing - spacing
            : 0);

    return LayoutBuilder(builder: (context, constraints) {
      if (balls.isEmpty) return const SizedBox.shrink();
      final availableSize = (constraints.maxWidth - gaps) / balls.length;
      final useSingleLine = availableSize >= minSize;
      final size = useSingleLine
          ? availableSize.clamp(minSize, defaultSize).toDouble()
          : defaultSize;
      final children = <Widget>[
        for (var index = 0; index < balls.length; index++) ...[
          if (index > 0)
            SizedBox(
                width: index == draw.primary.length ? groupSpacing : spacing),
          _ball(balls[index].$1, balls[index].$2,
              hit: balls[index].$3, size: size),
        ],
      ];
      return useSingleLine
          ? Row(mainAxisSize: MainAxisSize.min, children: children)
          : Wrap(spacing: spacing, runSpacing: 7, children: children);
    });
  }

  Widget _sevenStarBalls(_HistoricalDraw draw) {
    final winning = _winningTicket(draw);
    final selected = winning == null
        ? const <int>[]
        : [...winning.primary, ...winning.secondary];
    final numbers = [...draw.primary, ...draw.secondary];
    const spacing = 5.0;
    const minSize = 24.0;
    const defaultSize = 34.0;
    return LayoutBuilder(builder: (context, constraints) {
      if (numbers.isEmpty) return const SizedBox.shrink();
      final available =
          (constraints.maxWidth - (numbers.length - 1) * spacing) /
              numbers.length;
      final size = available.clamp(minSize, defaultSize).toDouble();
      final balls = [
        for (var index = 0; index < numbers.length; index++)
          _ball(
            numbers[index],
            index < 6 ? const Color(0xFF4A9BD6) : const Color(0xFFE7A51B),
            pad: false,
            hit: index < selected.length && selected[index] == numbers[index],
            size: size,
          ),
      ];
      if (available >= minSize) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < balls.length; index++) ...[
              if (index > 0) const SizedBox(width: spacing),
              balls[index],
            ],
          ],
        );
      }
      return Wrap(spacing: spacing, runSpacing: 7, children: balls);
    });
  }

  Widget _ball(int number, Color color,
          {bool hit = false, bool pad = true, double size = 34}) =>
      Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hit ? color : Colors.white,
            border: Border.all(
                color: color.withOpacity(hit ? 1 : .65),
                width: hit ? 1 : .8)),
        child: Text(pad ? number.toString().padLeft(2, '0') : '$number',
            style: TextStyle(
                color: hit ? Colors.white : color,
                fontSize: size < 30
                    ? size * .42
                    : size < 35
                        ? 13
                        : 14,
                fontWeight: hit ? FontWeight.w700 : FontWeight.w500)),
      );
}