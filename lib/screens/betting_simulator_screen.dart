import 'dart:math';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/lottery_simulation.dart';
import '../models/double_color_ball_draw.dart';
import '../models/happy_eight_draw.dart';
import '../models/qilecai_draw.dart';
import '../models/seven_star_draw.dart';
import '../models/super_lotto_draw.dart';
import '../services/double_color_ball_repository.dart';
import '../services/happy_eight_repository.dart';
import '../services/qilecai_repository.dart';
import '../services/lottery_simulation_repository.dart';
import '../services/seven_star_repository.dart';
import '../services/super_lotto_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/lottery/simulation_ticket_numbers.dart';
import 'betting_simulation_records_screen.dart';
import 'lottery_rules_screen.dart';
import 'historical_match_sheet.dart';

enum _DanTuoMode { none, front, back, both }

class _SimulationDraft {
  final Set<int> primary = {};
  final Set<int> secondary = {};
  final Set<int> primaryDan = {};
  final Set<int> primaryTuo = {};
  final Set<int> secondaryDan = {};
  final Set<int> secondaryTuo = {};
  final List<int?> digits = List.filled(7, null);
  final List<SimulationTicket> tickets = [];
  int happyEightCount = 10;
  int multiple = 1;
  bool additional = false;
  _DanTuoMode danTuoMode = _DanTuoMode.none;
  int? editingTicketIndex;

  void clearSelection() {
    primary.clear();
    secondary.clear();
    primaryDan.clear();
    primaryTuo.clear();
    secondaryDan.clear();
    secondaryTuo.clear();
    digits.fillRange(0, 7, null);
    editingTicketIndex = null;
  }

  int get lines => tickets.fold(0, (sum, ticket) => sum + ticket.lines);
  int get amount => lines * multiple * (additional ? 3 : 2);
}

class _RecentDraw {
  final String issue;
  final List<String> primary;
  final List<String> secondary;

  const _RecentDraw(this.issue, this.primary, [this.secondary = const []]);
}

class BettingSimulatorScreen extends StatefulWidget {
  const BettingSimulatorScreen({super.key});

  @override
  State<BettingSimulatorScreen> createState() => _BettingSimulatorScreenState();
}

class _BettingSimulatorScreenState extends State<BettingSimulatorScreen> {
  static const _blue = Color(0xFF1D67D4);
  final _random = Random();
  final _repository = LotterySimulationRepository();
  final _drafts = {
    for (final kind in SimulationLottery.values) kind: _SimulationDraft()
  };
  final _scrollController = ScrollController();
  final Set<SimulationLottery> _changedDrafts = {};
  SimulationLottery _kind = SimulationLottery.superLotto;
  bool _saving = false;
  List<_RecentDraw> _recentDraws = const [];
  bool _recentDrawsLoading = true;
  bool _recentDrawsExpanded = false;

  _SimulationDraft get _draft => _drafts[_kind]!;

  bool get _frontDanTuo =>
      (_kind == SimulationLottery.doubleColorBall &&
          _draft.danTuoMode != _DanTuoMode.none) ||
      (_kind == SimulationLottery.superLotto &&
          (_draft.danTuoMode == _DanTuoMode.front ||
              _draft.danTuoMode == _DanTuoMode.both));

  bool get _backDanTuo =>
      _kind == SimulationLottery.superLotto &&
      (_draft.danTuoMode == _DanTuoMode.back ||
          _draft.danTuoMode == _DanTuoMode.both);

  @override
  void initState() {
    super.initState();
    _loadDraftCache();
    _loadRecentDraws(_kind);
  }

  SimulationTicket get _currentTicket {
    return SimulationTicket(
      lottery: _kind,
      primary: _kind == SimulationLottery.sevenStar
          ? _draft.digits.take(6).whereType<int>().toList()
          : _frontDanTuo
              ? {..._draft.primaryDan, ..._draft.primaryTuo}.toList()
              : _draft.primary.toList(),
      secondary: _kind == SimulationLottery.sevenStar
          ? (_draft.digits[6] == null ? [] : [_draft.digits[6]!])
          : _backDanTuo
              ? {..._draft.secondaryDan, ..._draft.secondaryTuo}.toList()
              : _draft.secondary.toList(),
      primaryDan: _frontDanTuo ? _draft.primaryDan.toList() : const [],
      primaryTuo: _frontDanTuo ? _draft.primaryTuo.toList() : const [],
      secondaryDan: _backDanTuo ? _draft.secondaryDan.toList() : const [],
      secondaryTuo: _backDanTuo ? _draft.secondaryTuo.toList() : const [],
      happyEightCount: _draft.happyEightCount,
    );
  }

  String get _nextDrawLabel {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final drawWeekdays = switch (_kind) {
      SimulationLottery.superLotto => {
          DateTime.monday,
          DateTime.wednesday,
          DateTime.saturday
        },
      SimulationLottery.doubleColorBall => {
          DateTime.tuesday,
          DateTime.thursday,
          DateTime.sunday
        },
      SimulationLottery.sevenStar => {
          DateTime.tuesday,
          DateTime.friday,
          DateTime.sunday
        },
      SimulationLottery.happyEight => {1, 2, 3, 4, 5, 6, 7},
      SimulationLottery.qilecai => {
          DateTime.monday,
          DateTime.wednesday,
          DateTime.friday
        },
    };
    final today = DateTime.now();
    var nextDraw = DateTime(today.year, today.month, today.day);
    while (!drawWeekdays.contains(nextDraw.weekday)) {
      nextDraw = nextDraw.add(const Duration(days: 1));
    }
    return '下一期开奖：${nextDraw.month}月${nextDraw.day}日 ${weekdays[nextDraw.weekday - 1]}';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDraftCache() async {
    try {
      for (final kind in SimulationLottery.values) {
        final tickets = await _repository.loadDraftTickets(kind);
        if (!_changedDrafts.contains(kind)) {
          _drafts[kind]!.tickets
            ..clear()
            ..addAll(tickets);
        }
      }
    } catch (_) {
      // Keep the simulator usable if cached drafts cannot be read.
    } finally {
      if (mounted) setState(() {});
    }
  }

  Future<bool> _persistDraftTickets(SimulationLottery kind) async {
    try {
      await _repository.saveDraftTickets(kind, _drafts[kind]!.tickets);
      return true;
    } catch (_) {
      if (mounted) _message('号码缓存失败，请检查存储空间');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _blue,
      appBar: AppBar(
        title: const Text('模拟下注'),
        centerTitle: true,
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: '模拟记录',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  BettingSimulationRecordsScreen(initialLottery: _kind),
            )),
            icon: const Icon(Icons.receipt_long_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildLotterySelector(),
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: ColoredBox(
                color: AppColors.pageBackground,
                child: Column(
                  children: [
                    _buildToolbar(),
                    Expanded(
                      child: ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
                        children: [
                          _buildRecentDraws(),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: Row(children: [
                              Expanded(
                                child: Text(
                                  _nextDrawLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textTertiary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: _randomSelection,
                                icon: const Icon(Icons.shuffle, size: 17),
                                label: const Text('机选'),
                                style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(
                                        color: AppColors.border)),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 12),
                          if (_kind == SimulationLottery.sevenStar)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildDigitPicker(),
                            )
                          else
                            ..._buildNumberPickers(),
                        ],
                      ),
                    ),
                    _selectionFooter(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLotterySelector() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: SimulationLottery.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final kind = SimulationLottery.values[index];
          final selected = kind == _kind;
          return InkWell(
            onTap: _saving ? null : () => _selectLottery(kind),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(kind.shortLabel,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.white70,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w400,
                        fontSize: 17,
                      )),
                  const SizedBox(height: 7),
                  Container(
                    height: 3,
                    width: 24,
                    decoration: BoxDecoration(
                        color: selected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(3)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _selectLottery(SimulationLottery kind) {
    if (kind == _kind) return;
    setState(() {
      _kind = kind;
      _recentDrawsExpanded = false;
      _recentDraws = const [];
      _recentDrawsLoading = true;
      _scrollController.jumpTo(0);
    });
    _loadRecentDraws(kind);
  }

  void _setDanTuoMode(_DanTuoMode mode) {
    if (_draft.danTuoMode == mode) return;
    setState(() {
      _draft.danTuoMode = mode;
      _draft.clearSelection();
    });
  }

  Widget _buildToolbar() {
    return SizedBox(
      height: 48,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Expanded(
            child: _kind == SimulationLottery.happyEight
                ? DropdownButton<int>(
                    value: _draft.happyEightCount,
                    underline: const SizedBox.shrink(),
                    isExpanded: true,
                    items: List.generate(
                        10,
                        (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text('${happyEightPlayLabel(i + 1)}玩法'))),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _draft.happyEightCount = value;
                        _draft.primary.clear();
                      });
                    },
                  )
                : (_kind == SimulationLottery.doubleColorBall ||
                        _kind == SimulationLottery.superLotto)
                    ? DropdownButton<_DanTuoMode>(
                        value: _draft.danTuoMode,
                        underline: const SizedBox.shrink(),
                        isExpanded: true,
                        items: _kind == SimulationLottery.doubleColorBall
                            ? const [
                                DropdownMenuItem(
                                    value: _DanTuoMode.none,
                                    child: Text('基本投注')),
                                DropdownMenuItem(
                                    value: _DanTuoMode.front,
                                    child: Text('胆拖投注')),
                              ]
                            : const [
                                DropdownMenuItem(
                                    value: _DanTuoMode.none,
                                    child: Text('基本投注')),
                                DropdownMenuItem(
                                    value: _DanTuoMode.front,
                                    child: Text('前区胆拖')),
                                DropdownMenuItem(
                                    value: _DanTuoMode.back,
                                    child: Text('后区胆拖')),
                                DropdownMenuItem(
                                    value: _DanTuoMode.both,
                                    child: Text('双区胆拖')),
                              ],
                        onChanged: (value) {
                          if (value == null) return;
                          _setDanTuoMode(value);
                        },
                      )
                    : const Text('基本投注',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          TextButton(
              onPressed: _openBasket,
              style: TextButton.styleFrom(
                fixedSize: const Size.fromHeight(28),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: Text('已选 (${_draft.tickets.length})')),
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              tooltip: '历史中奖匹配',
              onPressed: _currentTicket.isValid ? _openHistoricalMatch : null,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.manage_search, color: _blue, size: 20),
            ),
          ),
          const SizedBox(height: 18, child: VerticalDivider(width: 12)),
          TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => LotteryRulesScreen(lotteryType: _kind.label),
            )),
            style: TextButton.styleFrom(
              fixedSize: const Size.fromHeight(28),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('游戏规则'),
          ),
        ]),
      ),
    );
  }

  Future<void> _loadRecentDraws(SimulationLottery kind) async {
    try {
      late final List<_RecentDraw> draws;
      switch (kind) {
        case SimulationLottery.superLotto:
          draws = (await SuperLottoRepository().loadRecent(limit: 10))
              .map((draw) => _mapSuperLottoDraw(draw))
              .toList();
        case SimulationLottery.doubleColorBall:
          draws = (await DoubleColorBallRepository().loadRecent(limit: 10))
              .map((draw) => _mapDoubleColorBallDraw(draw))
              .toList();
        case SimulationLottery.sevenStar:
          draws = (await SevenStarRepository().loadRecent(limit: 10))
              .map((draw) => _mapSevenStarDraw(draw))
              .toList();
        case SimulationLottery.happyEight:
          draws = (await HappyEightRepository().loadRecent(limit: 10))
              .map((draw) => _mapHappyEightDraw(draw))
              .toList();
        case SimulationLottery.qilecai:
          draws = (await QilecaiRepository().loadRecent(limit: 10))
              .map((draw) => _mapQilecaiDraw(draw))
              .toList();
      }
      if (!mounted || kind != _kind) return;
      setState(() {
        _recentDraws = draws;
        _recentDrawsLoading = false;
      });
    } catch (_) {
      if (!mounted || kind != _kind) return;
      setState(() {
        _recentDraws = const [];
        _recentDrawsLoading = false;
      });
    }
  }

  _RecentDraw _mapSuperLottoDraw(SuperLottoDraw draw) =>
      _RecentDraw(draw.issue, draw.frontNumbers, draw.backNumbers);

  _RecentDraw _mapDoubleColorBallDraw(DoubleColorBallDraw draw) =>
      _RecentDraw(draw.issue, draw.redNumbers, [draw.blueNumber]);

  _RecentDraw _mapSevenStarDraw(SevenStarDraw draw) => _RecentDraw(draw.issue,
      draw.numbers.take(6).toList(), draw.numbers.skip(6).take(1).toList());

  _RecentDraw _mapHappyEightDraw(HappyEightDraw draw) =>
      _RecentDraw(draw.issue, draw.numbers);

  _RecentDraw _mapQilecaiDraw(QilecaiDraw draw) =>
      _RecentDraw(draw.issue, draw.redNumbers, [draw.blueNumber]);

  Widget _buildRecentDraws() {
    final visible = _recentDrawsExpanded
        ? _recentDraws.take(10).toList()
        : _recentDraws.take(1).toList();
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFEFF2F5),
        border: Border(
          top: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (_recentDrawsLoading)
          const SizedBox(
            height: 38,
            child: Center(
              child: Text('正在读取开奖记录',
                  style:
                      TextStyle(color: AppColors.textTertiary, fontSize: 12)),
            ),
          )
        else if (_recentDraws.isEmpty)
          const SizedBox(
            height: 38,
            child: Center(
              child: Text('暂无本地开奖记录',
                  style:
                      TextStyle(color: AppColors.textTertiary, fontSize: 12)),
            ),
          )
        else
          for (var index = 0; index < visible.length; index++)
            _recentDrawRow(visible[index], index),
      ]),
    );
  }

  Widget _recentDrawRow(_RecentDraw draw, int index) {
    final latest = index == 0;
    final primaryColor = _kind == SimulationLottery.doubleColorBall ||
            _kind == SimulationLottery.qilecai
        ? AppColors.danger
        : _blue;
    final secondaryColor = _kind == SimulationLottery.doubleColorBall ||
            _kind == SimulationLottery.qilecai
        ? _blue
        : AppColors.warning;
    return Material(
      color: latest ? const Color(0xFFEFF2F5) : const Color(0xFFE9EDF1),
      child: InkWell(
        onTap: latest && _recentDraws.length > 1
            ? () => setState(() => _recentDrawsExpanded = !_recentDrawsExpanded)
            : null,
        child: SizedBox(
          height: 34,
          child: Padding(
            padding: const EdgeInsets.only(left: 8, right: 4),
            child: Row(children: [
              SizedBox(
                width: 64,
                child: Text('第${draw.issue}期',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: latest
                            ? AppColors.textSecondary
                            : AppColors.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    ...draw.primary.map((number) => _recentNumber(
                        number, primaryColor,
                        pad: _kind != SimulationLottery.sevenStar)),
                    if (draw.secondary.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text('+',
                            style: TextStyle(
                                color: AppColors.textTertiary, fontSize: 12)),
                      ),
                      ...draw.secondary.map((number) => _recentNumber(
                          number, secondaryColor,
                          pad: _kind != SimulationLottery.sevenStar)),
                    ],
                  ]),
                ),
              ),
              if (index == 0 && _recentDraws.length > 1)
                SizedBox(
                  width: 24,
                  child: Icon(
                    _recentDrawsExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 19,
                    color: AppColors.textTertiary,
                  ),
                )
              else
                const SizedBox(width: 24),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _recentNumber(String value, Color color, {bool pad = true}) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Text(pad ? value.padLeft(2, '0') : value,
            style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.w700)),
      );

  Future<void> _openHistoricalMatch() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HistoricalMatchSheet(ticket: _currentTicket),
    );
  }

  List<Widget> _buildNumberPickers() {
    if (_frontDanTuo || _backDanTuo) {
      final isSuperLotto = _kind == SimulationLottery.superLotto;
      final frontColor = isSuperLotto ? _blue : AppColors.danger;
      return [
        if (_frontDanTuo) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _numberSection(
              title: isSuperLotto ? '前区胆码' : '红球胆码',
              hint: isSuperLotto
                  ? '胆码1-4个，每注必含，不能与拖码重复'
                  : '胆码1-5个，每注必含，不能与拖码重复',
              max: _kind.primaryMax,
              selection: _draft.primaryDan,
              color: frontColor,
              limit: isSuperLotto ? 4 : 5,
              excluded: _draft.primaryTuo,
              blockedMessage: '该号码已选为拖码',
              keyPrefix: 'dan',
            ),
          ),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 22),
              child: Divider(height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _numberSection(
              title: isSuperLotto ? '前区拖码' : '红球拖码',
              hint: isSuperLotto
                  ? '胆码+拖码合计不少于6个前区号码'
                  : '胆码+拖码合计不少于7个红球',
              max: _kind.primaryMax,
              selection: _draft.primaryTuo,
              color: frontColor,
              excluded: _draft.primaryDan,
              blockedMessage: '该号码已选为胆码',
              keyPrefix: 'tuo',
            ),
          ),
        ] else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _numberSection(
              title: _kind.primaryLabel,
              hint: '至少选择 ${_kind.primaryCount} 个号码',
              max: _kind.primaryMax,
              selection: _draft.primary,
              color: frontColor,
            ),
          ),
        ],
        const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 22),
            child: Divider(height: 1)),
        if (_backDanTuo) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _numberSection(
              title: '后区胆码',
              hint: '胆码1个，每注必含，不能与拖码重复',
              max: _kind.secondaryMax,
              selection: _draft.secondaryDan,
              color: AppColors.warning,
              limit: 1,
              excluded: _draft.secondaryTuo,
              blockedMessage: '该号码已选为拖码',
              keyPrefix: 'backDan',
            ),
          ),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 22),
              child: Divider(height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _numberSection(
              title: '后区拖码',
              hint: '拖码至少2个，与胆码不重复',
              max: _kind.secondaryMax,
              selection: _draft.secondaryTuo,
              color: AppColors.warning,
              excluded: _draft.secondaryDan,
              blockedMessage: '该号码已选为胆码',
              keyPrefix: 'backTuo',
            ),
          ),
        ] else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _numberSection(
              title: isSuperLotto ? '后区' : _kind.secondaryLabel,
              hint: isSuperLotto
                  ? '至少选择 ${_kind.secondaryCount} 个号码'
                  : '至少选择 1 个号码，多个蓝球为复式',
              max: _kind.secondaryMax,
              selection: _draft.secondary,
              color: _kind == SimulationLottery.doubleColorBall
                  ? _blue
                  : AppColors.warning,
              keyPrefix: isSuperLotto ? null : 'blue',
            ),
          ),
        ],
      ];
    }

    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _numberSection(
          title: _kind == SimulationLottery.happyEight
              ? '号码区'
              : _kind.primaryLabel,
          hint: _kind == SimulationLottery.happyEight
              ? '至少选择 ${_draft.happyEightCount} 个号码，超出按复式计算'
              : '至少选择 ${_kind.primaryCount} 个号码',
          max: _kind.primaryMax,
          selection: _draft.primary,
          color: (_kind == SimulationLottery.doubleColorBall ||
                  _kind == SimulationLottery.qilecai)
              ? AppColors.danger
              : _blue,
          limit: null,
        ),
      ),
      if (_kind.secondaryCount > 0) ...[
        const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 22),
            child: Divider(height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _numberSection(
            title: _kind.secondaryLabel,
            hint: '至少选择 ${_kind.secondaryCount} 个号码',
            max: _kind.secondaryMax,
            selection: _draft.secondary,
            color: _kind == SimulationLottery.doubleColorBall
                ? _blue
                : AppColors.warning,
          ),
        ),
      ],
    ];
  }

  Widget _numberSection(
      {required String title,
      required String hint,
      required int max,
      required Set<int> selection,
      required Color color,
      int? limit,
      Set<int> excluded = const {},
      String blockedMessage = '该号码已在另一分区选中',
      String? keyPrefix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w700)),
              Text(hint,
                  style: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 13)),
            ]),
        const SizedBox(height: 18),
        LayoutBuilder(builder: (context, constraints) {
          final columns = (constraints.maxWidth / 49).floor().clamp(5, 12);
          const spacing = 8.0;
          final size =
              (constraints.maxWidth - (columns - 1) * spacing) / columns;
          return Wrap(spacing: spacing, runSpacing: 14, children: [
            for (var number = 1; number <= max; number++)
              SizedBox(
                key: ValueKey(keyPrefix == null
                    ? 'pick-${_kind.name}-$number'
                    : 'pick-${_kind.name}-$keyPrefix-$number'),
                width: size,
                height: size,
                child: _ball(
                  label: number.toString().padLeft(2, '0'),
                  selected: selection.contains(number),
                  color: color,
                  enabled: !excluded.contains(number),
                  onTap: () {
                    if (excluded.contains(number)) {
                      _message(blockedMessage);
                      return;
                    }
                    if (!selection.contains(number) &&
                        limit != null &&
                        selection.length >= limit) {
                      _message('当前玩法最多选择 $limit 个号码');
                      return;
                    }
                    setState(() => selection.contains(number)
                        ? selection.remove(number)
                        : selection.add(number));
                  },
                ),
              ),
          ]);
        }),
      ],
    );
  }

  Widget _buildDigitPicker() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('每位选择1个数字，同一数字可出现在不同位置',
          style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
      const SizedBox(height: 12),
      for (var position = 0; position < 7; position++) ...[
        Text(position == 6 ? '后区 · 第7位' : '前区 · 第${position + 1}位',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        LayoutBuilder(builder: (context, constraints) {
          final size = (constraints.maxWidth - 4 * 10) / 5;
          return Wrap(spacing: 10, runSpacing: 10, children: [
            for (var digit = 0; digit < 10; digit++)
              SizedBox(
                  key: ValueKey('digit-picker-$position-$digit'),
                  width: size,
                  height: min(size, 44),
                  child: _ball(
                    label: '$digit',
                    selected: _draft.digits[position] == digit,
                    color: position == 6 ? AppColors.warning : _blue,
                    onTap: () => setState(() => _draft.digits[position] =
                        _draft.digits[position] == digit ? null : digit),
                  )),
          ]);
        }),
        const SizedBox(height: 20),
      ],
    ]);
  }

  Widget _ball(
      {required String label,
      required bool selected,
      required Color color,
      required VoidCallback onTap,
      bool enabled = true}) {
    final textColor = !enabled
        ? AppColors.textMuted
        : selected
            ? Colors.white
            : color;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: !enabled
            ? AppColors.surfaceSoft
            : selected
                ? color
                : Colors.white,
        elevation: selected ? 0 : 1,
        shadowColor: Colors.black12,
        shape: CircleBorder(
            side: BorderSide(color: selected ? color : AppColors.border)),
        child: InkWell(
          onTap: enabled ? onTap : null,
          customBorder: const CircleBorder(),
          child: Center(
              child: Text(label,
                  style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w500))),
        ),
      ),
    );
  }

  Widget _selectionFooter() {
    final lines = _currentTicket.lines;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
              gradient:
                  const LinearGradient(colors: [_blue, Color(0xFF1559BC)]),
              borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            IconButton(
              tooltip: '清空选号',
              onPressed: () => setState(_draft.clearSelection),
              icon: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: '已选 ',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    TextSpan(
                      text: '$lines注，共${lines * 2}元',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _yellowButton(
                _draft.editingTicketIndex == null ? '选好了' : '保存修改',
                lines > 0
                    ? () async {
                        final kind = _kind;
                        setState(() {
                          _changedDrafts.add(kind);
                          final editingIndex = _draft.editingTicketIndex;
                          if (editingIndex != null &&
                              editingIndex >= 0 &&
                              editingIndex < _draft.tickets.length) {
                            _draft.tickets[editingIndex] = _currentTicket;
                          } else {
                            _draft.tickets.add(_currentTicket);
                          }
                          _draft.clearSelection();
                        });
                        final persisted = _persistDraftTickets(kind);
                        _openBasket();
                        await persisted;
                      }
                    : null),
          ]),
        ),
      ),
    );
  }

  Widget _yellowButton(String text, VoidCallback? onPressed,
          {bool compact = false}) =>
      FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFFD638),
          foregroundColor: const Color(0xFF173458),
          disabledBackgroundColor: const Color(0xFFE4D68E),
          disabledForegroundColor: const Color(0xFF536879),
          minimumSize: compact ? Size.zero : null,
          fixedSize: compact ? const Size.fromHeight(34) : null,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 20,
            vertical: compact ? 0 : 8,
          ),
          tapTargetSize: compact ? MaterialTapTargetSize.shrinkWrap : null,
        ),
        onPressed: onPressed,
        child: Text(text,
            style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: compact ? 13 : null)),
      );

  void _randomSelection() {
    final ticket = _randomTicket();
    setState(() => _restoreSelection(ticket));
    _scrollController.jumpTo(0);
  }

  SimulationTicket _randomTicket() {
    if (_kind == SimulationLottery.doubleColorBall && _frontDanTuo) {
      return SimulationTicket.danTuoRandom(_kind, _random, front: true);
    }
    if (_kind == SimulationLottery.superLotto &&
        (_frontDanTuo || _backDanTuo)) {
      return SimulationTicket.danTuoRandom(
        _kind,
        _random,
        front: _frontDanTuo,
        back: _backDanTuo,
      );
    }
    return SimulationTicket.random(_kind, _random,
        happyEightCount: _draft.happyEightCount);
  }

  void _restoreSelection(SimulationTicket ticket) {
    _draft.clearSelection();
    if (_kind == SimulationLottery.sevenStar) {
      for (var i = 0; i < 6; i++) {
        _draft.digits[i] = ticket.primary[i];
      }
      _draft.digits[6] = ticket.secondary.single;
    } else {
      _draft.danTuoMode = ticket.isPrimaryDanTuo && ticket.isSecondaryDanTuo
          ? _DanTuoMode.both
          : ticket.isPrimaryDanTuo
              ? _DanTuoMode.front
              : ticket.isSecondaryDanTuo
                  ? _DanTuoMode.back
                  : _DanTuoMode.none;
      if (ticket.isPrimaryDanTuo) {
        _draft.primaryDan.addAll(ticket.primaryDan);
        _draft.primaryTuo.addAll(ticket.primaryTuo);
      } else {
        _draft.primary.addAll(ticket.primary);
      }
      if (ticket.isSecondaryDanTuo) {
        _draft.secondaryDan.addAll(ticket.secondaryDan);
        _draft.secondaryTuo.addAll(ticket.secondaryTuo);
      } else {
        _draft.secondary.addAll(ticket.secondary);
      }
    }
    _draft.happyEightCount = ticket.happyEightCount;
  }

  Future<void> _openBasket() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.pageBackground,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      clipBehavior: Clip.antiAlias,
      builder: (sheetContext) =>
          StatefulBuilder(builder: (sheetContext, updateSheet) {
        void update(VoidCallback change) {
          setState(change);
          updateSheet(() {});
        }

        return SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.88,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
              child: Row(children: [
                Expanded(
                    child: Text('${_kind.shortLabel}明细',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 18))),
                TextButton(
                  onPressed: _saving || _draft.tickets.isEmpty
                      ? null
                      : () async {
                          final kind = _kind;
                          update(() {
                            _changedDrafts.add(kind);
                            _draft.tickets.clear();
                            _draft.clearSelection();
                          });
                          await _persistDraftTickets(kind);
                        },
                  child: const Text('清空全部'),
                ),
                IconButton(
                    tooltip: '关闭明细',
                    onPressed:
                        _saving ? null : () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close)),
              ]),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final count in [1, 5, 10])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Center(
                        child: OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () async {
                                  final kind = _kind;
                                  update(() {
                                    _changedDrafts.add(kind);
                                    _draft.tickets.addAll(List.generate(
                                        count, (_) => _randomTicket()));
                                  });
                                  await _persistDraftTickets(kind);
                                },
                          style: OutlinedButton.styleFrom(
                            fixedSize: const Size.fromHeight(32),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            textStyle: const TextStyle(fontSize: 14),
                          ),
                          child: Text('+机选$count注'),
                        ),
                      ),
                    ),
                  Center(
                    child: TextButton(
                      onPressed: _saving
                          ? null
                          : () {
                              if (_draft.editingTicketIndex != null) {
                                setState(_draft.clearSelection);
                                updateSheet(() {});
                              }
                              Navigator.pop(sheetContext);
                              _scrollController.jumpTo(0);
                            },
                      style: TextButton.styleFrom(
                        fixedSize: const Size.fromHeight(32),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                      child: const Text('+继续选号'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _draft.tickets.isEmpty
                  ? const Center(
                      child: Text('还没有号码，先机选或继续选号',
                          style: TextStyle(color: AppColors.textTertiary)))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      itemCount: _draft.tickets.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final ticketIndex = _draft.tickets.length - 1 - index;
                        final ticket = _draft.tickets[ticketIndex];
                        void editTicket() {
                          if (_saving) return;
                          update(() {
                            _restoreSelection(ticket);
                            _draft.editingTicketIndex = ticketIndex;
                          });
                          Navigator.pop(sheetContext);
                          _scrollController.jumpTo(0);
                        }

                        final playTag = ticket.playLabel;

                        return Container(
                          padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            border: Border(
                                bottom: BorderSide(color: AppColors.border)),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 23),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border:
                                          Border.all(color: AppColors.border),
                                    ),
                                    child: IconButton(
                                      tooltip: '删除此项',
                                      onPressed: _saving
                                          ? null
                                          : () async {
                                              final kind = _kind;
                                              update(() {
                                                _changedDrafts.add(kind);
                                                _draft.tickets
                                                    .removeAt(ticketIndex);
                                                final editingIndex =
                                                    _draft.editingTicketIndex;
                                                if (editingIndex ==
                                                    ticketIndex) {
                                                  _draft.clearSelection();
                                                } else if (editingIndex !=
                                                        null &&
                                                    editingIndex >
                                                        ticketIndex) {
                                                  _draft.editingTicketIndex =
                                                      editingIndex - 1;
                                                }
                                              });
                                              await _persistDraftTickets(kind);
                                            },
                                      constraints:
                                          const BoxConstraints.tightFor(
                                              width: 24, height: 24),
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(Icons.close, size: 13),
                                    ),
                                  ),
                                  Expanded(
                                    child: InkWell(
                                      key: ValueKey(
                                          'ticket-content-$ticketIndex'),
                                      onTap: _saving ? null : editTicket,
                                      borderRadius: BorderRadius.circular(6),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        child: SimulationTicketNumbers(
                                            ticket: ticket),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: '编辑号码',
                                    onPressed: _saving ? null : editTicket,
                                    constraints: const BoxConstraints.tightFor(
                                        width: 32, height: 36),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.chevron_right,
                                        color: AppColors.textTertiary,
                                        size: 22),
                                  ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 0,
                                left: 0,
                                child: IgnorePointer(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _blue.withOpacity(.08),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      playTag,
                                      style: const TextStyle(
                                        color: _blue,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 8,
                                child: IgnorePointer(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _blue.withOpacity(.08),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${ticket.lines}注',
                                      style: const TextStyle(
                                        color: _blue,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: _blue, borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  Row(children: [
                    const Text('倍数',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    IconButton(
                        tooltip: '减少倍数',
                        onPressed: _saving || _draft.multiple <= 1
                            ? null
                            : () => update(() => _draft.multiple--),
                        constraints: const BoxConstraints.tightFor(
                            width: 32, height: 32),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.remove, size: 18),
                        color: Colors.white,
                        disabledColor: Colors.white38),
                    Text('${_draft.multiple}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14)),
                    IconButton(
                        tooltip: '增加倍数',
                        onPressed: _saving || _draft.multiple >= 99
                            ? null
                            : () => update(() => _draft.multiple++),
                        constraints: const BoxConstraints.tightFor(
                            width: 32, height: 32),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.add, size: 18),
                        color: Colors.white,
                        disabledColor: Colors.white38),
                    const Spacer(),
                    if (_kind == SimulationLottery.superLotto) ...[
                      SizedBox(
                        width: 26,
                        height: 26,
                        child: Checkbox(
                          value: _draft.additional,
                          activeColor: const Color(0xFFFFD638),
                          checkColor: _blue,
                          side: const BorderSide(color: Colors.white70),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          onChanged: _saving
                              ? null
                              : (value) => update(
                                  () => _draft.additional = value ?? false),
                        ),
                      ),
                      const Text('追加投注',
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                    const SizedBox(width: 8),
                    Text('最高99倍',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 10)),
                  ]),
                  const Divider(height: 8, color: Colors.white24),
                  Row(children: [
                    Expanded(
                      child: Text(
                        '共计 ${_draft.lines} 注  ¥${_draft.amount} 元',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    _yellowButton(
                        _saving ? '保存中…' : '保存记录',
                        _saving || _draft.tickets.isEmpty
                            ? null
                            : () async {
                                update(() => _saving = true);
                                final saved = await _saveRecord();
                                if (!mounted) return;
                                setState(() => _saving = false);
                                if (!sheetContext.mounted) return;
                                if (saved) {
                                  Navigator.pop(sheetContext);
                                } else {
                                  updateSheet(() {});
                                }
                              }),
                  ]),
                ]),
              ),
            ),
          ]),
        );
      }),
    );
  }

  Future<bool> _saveRecord() async {
    final draft = _draft;
    final record = SimulationRecord(
      id: const Uuid().v4(),
      createdAt: DateTime.now(),
      lottery: _kind,
      tickets: draft.tickets,
      multiple: draft.multiple,
      additional: draft.additional,
    );
    try {
      await _repository.save(record);
      if (!mounted) return true;
      _message('模拟记录已保存，可从右上角查看');
      return true;
    } catch (_) {
      if (mounted) _message('保存失败，请重试，已选号码已保留');
      return false;
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}
