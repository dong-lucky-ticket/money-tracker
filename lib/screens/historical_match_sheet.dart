import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/double_color_ball_draw.dart';
import '../models/happy_eight_draw.dart';
import '../models/lottery_simulation.dart';
import '../models/seven_star_draw.dart';
import '../models/super_lotto_draw.dart';
import '../services/double_color_ball_repository.dart';
import '../services/happy_eight_repository.dart';
import '../services/seven_star_repository.dart';
import '../services/super_lotto_repository.dart';
import '../theme/app_colors.dart';

class _HistoricalDraw {
  final String issue;
  final DateTime date;
  final List<int> primary;
  final List<int> secondary;

  const _HistoricalDraw(this.issue, this.date, this.primary,
      [this.secondary = const []]);
}

class HistoricalMatchSheet extends StatefulWidget {
  final SimulationTicket ticket;

  const HistoricalMatchSheet({super.key, required this.ticket});

  @override
  State<HistoricalMatchSheet> createState() => _HistoricalMatchSheetState();
}

class _HistoricalMatchSheetState extends State<HistoricalMatchSheet> {
  static const _blue = Color(0xFF1D67D4);
  List<_HistoricalDraw> _draws = const [];
  bool _loading = true;
  bool _winnersOnly = false;
  int? _limit = 30;

  @override
  void initState() {
    super.initState();
    _loadDraws();
  }

  Future<void> _loadDraws() async {
    setState(() => _loading = true);
    try {
      final lottery = widget.ticket.lottery;
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
      draw.issue,
      draw.publishDate,
      _numbers(draw.frontNumbers),
      _numbers(draw.backNumbers));
  _HistoricalDraw _doubleColorBall(DoubleColorBallDraw draw) => _HistoricalDraw(
      draw.issue,
      draw.publishDate,
      _numbers(draw.redNumbers),
      _numbers([draw.blueNumber]));
  _HistoricalDraw _sevenStar(SevenStarDraw draw) =>
      _HistoricalDraw(draw.issue, draw.publishDate, _numbers(draw.numbers));
  _HistoricalDraw _happyEight(HappyEightDraw draw) =>
      _HistoricalDraw(draw.issue, draw.publishDate, _numbers(draw.numbers));
  List<int> _numbers(List<String> values) =>
      values.map((value) => int.tryParse(value) ?? -1).toList();

  int _primaryHits(_HistoricalDraw draw) {
    if (widget.ticket.lottery == SimulationLottery.sevenStar) {
      return List.generate(7, (index) => index)
          .where((index) => widget.ticket.primary[index] == draw.primary[index])
          .length;
    }
    return widget.ticket.primary
        .toSet()
        .intersection(draw.primary.toSet())
        .length;
  }

  int _secondaryHits(_HistoricalDraw draw) => widget.ticket.secondary
      .toSet()
      .intersection(draw.secondary.toSet())
      .length;

  bool _hasHits(_HistoricalDraw draw) =>
      _primaryHits(draw) + _secondaryHits(draw) > 0;

  List<_HistoricalDraw> get _visibleDraws =>
      _draws.where((draw) => !_winnersOnly || _hasHits(draw)).toList();

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    final visible = _visibleDraws;
    final wins = _draws.where(_hasHits).length;
    return FractionallySizedBox(
      heightFactor: .94,
      child: Material(
        color: AppColors.pageBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          Container(
            color: _blue,
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 18),
            child: Column(children: [
              Row(children: [
                const Expanded(
                    child: Text('历史中奖匹配',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w700))),
                IconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.pop(context),
                    color: Colors.white,
                    icon: const Icon(Icons.close)),
              ]),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Expanded(
                            child: Text('当前选号',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13))),
                        Text(ticket.playLabel,
                            style: const TextStyle(
                                color: AppColors.textTertiary, fontSize: 12)),
                      ]),
                      const SizedBox(height: 12),
                      if (ticket.lottery == SimulationLottery.sevenStar)
                        _balls(ticket.primary, color: _blue, sevenStar: true)
                      else ...[
                        _numberGroup(ticket.lottery.primaryLabel,
                            ticket.primary, const Color(0xFF4A9BD6)),
                        if (ticket.secondary.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _numberGroup(ticket.lottery.secondaryLabel,
                              ticket.secondary, const Color(0xFFE7A51B)),
                        ],
                      ],
                    ]),
              ),
            ]),
          ),
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
                  const Icon(Icons.arrow_drop_down)
                ]),
              ),
              const Spacer(),
              const Text('只看命中期次',
                  style: TextStyle(color: AppColors.textSecondary)),
              Switch.adaptive(
                  value: _winnersOnly,
                  activeColor: _blue,
                  onChanged: (value) => setState(() => _winnersOnly = value)),
            ]),
          ),
          Container(
            width: double.infinity,
            color: const Color(0xFFF3F5F7),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            child: Text(
                _loading
                    ? '正在读取本地开奖记录…'
                    : '已匹配${_draws.length}期 · ${wins == 0 ? '暂无命中号码' : '有号码命中 $wins 期'}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14)),
          ),
          Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _draws.isEmpty
                      ? _empty('暂无本地开奖记录', '先在开奖页面同步该彩种的历史数据')
                      : visible.isEmpty
                          ? _empty('没有符合条件的期次', '关闭“只看命中期次”查看全部结果')
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                              itemCount: visible.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, index) =>
                                  _drawRow(visible[index]),
                            )),
          SafeArea(
              top: false,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                        onPressed: () => Navigator.pop(context),
                        style: FilledButton.styleFrom(backgroundColor: _blue),
                        child: const Text('完成')),
                  ))),
        ]),
      ),
    );
  }

  Widget _numberGroup(String label, List<int> numbers, Color color) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
              width: 42,
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12))),
          Expanded(child: _balls(numbers, color: color))
        ],
      );

  Widget _balls(List<int> numbers,
      {Color color = const Color(0xFF4A9BD6),
      bool sevenStar = false,
      _HistoricalDraw? draw,
      List<int>? selected}) {
    return Wrap(spacing: 7, runSpacing: 7, children: [
      for (var index = 0; index < numbers.length; index++)
        _ball(numbers[index], color,
            hit: draw != null &&
                (sevenStar
                    ? index < widget.ticket.primary.length &&
                        widget.ticket.primary[index] == numbers[index]
                    : (selected ?? widget.ticket.primary)
                        .contains(numbers[index])),
            compact: draw != null),
    ]);
  }

  Widget _ball(int number, Color color,
          {bool hit = false, bool compact = false}) =>
      Container(
        width: compact ? 34 : 37,
        height: compact ? 34 : 37,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hit ? color : Colors.white,
            border: Border.all(
                color: color.withOpacity(hit ? 1 : .65), width: hit ? 1 : .8)),
        child: Text(number.toString().padLeft(2, '0'),
            style: TextStyle(
                color: hit ? Colors.white : color,
                fontSize: compact ? 13 : 14,
                fontWeight: hit ? FontWeight.w700 : FontWeight.w500)),
      );

  Widget _drawRow(_HistoricalDraw draw) {
    final primary = _primaryHits(draw);
    final secondary = _secondaryHits(draw);
    final winning = primary + secondary > 0;
    final lottery = widget.ticket.lottery;
    final primaryColor = lottery == SimulationLottery.doubleColorBall
        ? AppColors.danger
        : const Color(0xFF4A9BD6);
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
          Text(
              lottery == SimulationLottery.sevenStar
                  ? '命中 $primary/7 位'
                  : lottery == SimulationLottery.happyEight
                      ? '命中 $primary 个'
                      : '前区 $primary/${lottery.primaryCount} · 后区 $secondary/${lottery.secondaryCount}',
              style: TextStyle(
                  fontSize: 12,
                  color: winning
                      ? const Color(0xFFD76B68)
                      : AppColors.textTertiary,
                  fontWeight: winning ? FontWeight.w600 : FontWeight.normal)),
        ]),
        const SizedBox(height: 11),
        if (lottery == SimulationLottery.sevenStar)
          _balls(draw.primary, sevenStar: true, draw: draw)
        else ...[
          _balls(draw.primary,
              color: primaryColor, draw: draw, selected: widget.ticket.primary),
          if (draw.secondary.isNotEmpty) ...[
            const SizedBox(height: 8),
            _balls(draw.secondary,
                color: const Color(0xFFE7A51B),
                draw: draw,
                selected: widget.ticket.secondary),
          ],
        ],
      ]),
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
      ]));
}
