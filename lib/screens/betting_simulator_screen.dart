import 'dart:math';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/lottery_simulation.dart';
import '../services/lottery_simulation_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/lottery/simulation_ticket_numbers.dart';
import 'betting_simulation_records_screen.dart';
import 'lottery_rules_screen.dart';

class _SimulationDraft {
  final Set<int> primary = {};
  final Set<int> secondary = {};
  final List<int?> digits = List.filled(7, null);
  final List<SimulationTicket> tickets = [];
  int happyEightCount = 10;
  int multiple = 1;
  bool additional = false;

  void clearSelection() {
    primary.clear();
    secondary.clear();
    digits.fillRange(0, 7, null);
  }

  int get lines => tickets.fold(0, (sum, ticket) => sum + ticket.lines);
  int get amount => lines * multiple * (additional ? 3 : 2);
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
  SimulationLottery _kind = SimulationLottery.superLotto;
  bool _saving = false;

  _SimulationDraft get _draft => _drafts[_kind]!;

  SimulationTicket get _currentTicket => SimulationTicket(
        lottery: _kind,
        primary: _kind == SimulationLottery.sevenStar
            ? _draft.digits.whereType<int>().toList()
            : _draft.primary.toList(),
        secondary: _draft.secondary.toList(),
        happyEightCount: _draft.happyEightCount,
      );

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
                  const BorderRadius.vertical(top: Radius.circular(22)),
              child: ColoredBox(
                color: AppColors.pageBackground,
                child: Column(
                  children: [
                    _buildToolbar(),
                    Expanded(
                      child: ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        children: [
                          Row(children: [
                            const Expanded(
                                child: Text('仅作模拟 · 每注2元',
                                    style: TextStyle(
                                        color: AppColors.textTertiary,
                                        fontSize: 12))),
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
                          const SizedBox(height: 12),
                          if (_kind == SimulationLottery.sevenStar)
                            _buildDigitPicker()
                          else ...[
                            _numberSection(
                              title: _kind == SimulationLottery.happyEight
                                  ? '号码区'
                                  : _kind.primaryLabel,
                              hint: _kind == SimulationLottery.happyEight
                                  ? '请选择 ${_draft.happyEightCount} 个号码'
                                  : '至少选择 ${_kind.primaryCount} 个号码',
                              max: _kind.primaryMax,
                              selection: _draft.primary,
                              color: _kind == SimulationLottery.doubleColorBall
                                  ? AppColors.danger
                                  : _blue,
                              limit: _kind == SimulationLottery.happyEight
                                  ? _draft.happyEightCount
                                  : null,
                            ),
                            if (_kind.secondaryCount > 0) ...[
                              const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 22),
                                  child: Divider(height: 1)),
                              _numberSection(
                                title: _kind.secondaryLabel,
                                hint: '至少选择 ${_kind.secondaryCount} 个号码',
                                max: _kind.secondaryMax,
                                selection: _draft.secondary,
                                color:
                                    _kind == SimulationLottery.doubleColorBall
                                        ? _blue
                                        : AppColors.warning,
                              ),
                            ],
                          ],
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
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: SimulationLottery.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final kind = SimulationLottery.values[index];
          final selected = kind == _kind;
          return InkWell(
            onTap: _saving
                ? null
                : () => setState(() {
                      _kind = kind;
                      _scrollController.jumpTo(0);
                    }),
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

  Widget _buildToolbar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
              : const Text('基本投注',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        TextButton(
            onPressed: _openBasket,
            child: Text('已选 (${_draft.tickets.length})')),
        const SizedBox(height: 20, child: VerticalDivider(width: 12)),
        TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => LotteryRulesScreen(lotteryType: _kind.label),
          )),
          child: const Text('游戏规则'),
        ),
      ]),
    );
  }

  Widget _numberSection(
      {required String title,
      required String hint,
      required int max,
      required Set<int> selection,
      required Color color,
      int? limit}) {
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
                width: size,
                height: size,
                child: _ball(
                  label: number.toString().padLeft(2, '0'),
                  selected: selection.contains(number),
                  color: color,
                  onTap: () {
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
      required VoidCallback onTap}) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? color : Colors.white,
        elevation: selected ? 0 : 1,
        shadowColor: Colors.black12,
        shape: CircleBorder(
            side: BorderSide(color: selected ? color : AppColors.border)),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(
              child: Text(label,
                  style: TextStyle(
                      color: selected ? Colors.white : color,
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
                '选好了',
                lines > 0
                    ? () {
                        setState(() {
                          _draft.tickets.add(_currentTicket);
                          _draft.clearSelection();
                        });
                        _openBasket();
                      }
                    : null),
          ]),
        ),
      ),
    );
  }

  Widget _yellowButton(String text, VoidCallback? onPressed) => FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFFD638),
          foregroundColor: const Color(0xFF173458),
          disabledBackgroundColor: const Color(0xFFE4D68E),
          disabledForegroundColor: const Color(0xFF536879),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        ),
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
      );

  void _randomSelection() {
    final ticket = _randomTicket();
    setState(() => _restoreSelection(ticket));
    _scrollController.jumpTo(0);
  }

  SimulationTicket _randomTicket() => SimulationTicket.random(_kind, _random,
      happyEightCount: _draft.happyEightCount);

  void _restoreSelection(SimulationTicket ticket) {
    _draft.clearSelection();
    if (_kind == SimulationLottery.sevenStar) {
      for (var i = 0; i < 7; i++) {
        _draft.digits[i] = ticket.primary[i];
      }
    } else {
      _draft.primary.addAll(ticket.primary);
      _draft.secondary.addAll(ticket.secondary);
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
                      : () => update(_draft.tickets.clear),
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
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final count in [1, 5, 10])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => update(() {
                                  _draft.tickets.addAll(List.generate(
                                      count, (_) => _randomTicket()));
                                }),
                        child: Text('+机选$count注'),
                      ),
                    ),
                  TextButton(
                      onPressed:
                          _saving ? null : () => Navigator.pop(sheetContext),
                      child: const Text('+继续选号')),
                ],
              ),
            ),
            Expanded(
              child: _draft.tickets.isEmpty
                  ? const Center(
                      child: Text('还没有号码，先机选或继续选号',
                          style: TextStyle(color: AppColors.textTertiary)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _draft.tickets.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final ticket = _draft.tickets[index];
                        return Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(children: [
                            IconButton(
                              tooltip: '删除此项',
                              onPressed: _saving
                                  ? null
                                  : () => update(
                                      () => _draft.tickets.removeAt(index)),
                              icon: const Icon(Icons.cancel_outlined,
                                  color: AppColors.textMuted, size: 21),
                            ),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  SimulationTicketNumbers(ticket: ticket),
                                  const SizedBox(height: 6),
                                  Text('${ticket.playLabel} · ${ticket.lines}注',
                                      style: const TextStyle(
                                          color: AppColors.textTertiary,
                                          fontSize: 12)),
                                ])),
                            IconButton(
                              tooltip: '编辑号码',
                              onPressed: _saving
                                  ? null
                                  : () {
                                      if (_currentTicket.primary.isNotEmpty) {
                                        _message('请先处理选号区中的号码，再编辑明细');
                                        return;
                                      }
                                      update(() {
                                        _draft.tickets.removeAt(index);
                                        _restoreSelection(ticket);
                                      });
                                      Navigator.pop(sheetContext);
                                      _scrollController.jumpTo(0);
                                    },
                              icon: const Icon(Icons.chevron_right,
                                  color: AppColors.textMuted),
                            ),
                          ]),
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: _blue, borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  Row(children: [
                    const Text('倍数', style: TextStyle(color: Colors.white70)),
                    IconButton(
                        tooltip: '减少倍数',
                        onPressed: _saving || _draft.multiple <= 1
                            ? null
                            : () => update(() => _draft.multiple--),
                        icon: const Icon(Icons.remove),
                        color: Colors.white,
                        disabledColor: Colors.white38),
                    Text('${_draft.multiple}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 17)),
                    IconButton(
                        tooltip: '增加倍数',
                        onPressed: _saving || _draft.multiple >= 99
                            ? null
                            : () => update(() => _draft.multiple++),
                        icon: const Icon(Icons.add),
                        color: Colors.white,
                        disabledColor: Colors.white38),
                    const Spacer(),
                    Text('最高99倍',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 11)),
                  ]),
                  if (_kind == SimulationLottery.superLotto)
                    InkWell(
                      onTap: _saving
                          ? null
                          : () => update(
                              () => _draft.additional = !_draft.additional),
                      child: Row(children: [
                        Checkbox(
                          value: _draft.additional,
                          activeColor: const Color(0xFFFFD638),
                          checkColor: _blue,
                          side: const BorderSide(color: Colors.white70),
                          onChanged: _saving
                              ? null
                              : (value) => update(
                                  () => _draft.additional = value ?? false),
                        ),
                        const Text('追加投注（每注加1元）',
                            style:
                                TextStyle(color: Colors.white, fontSize: 13)),
                      ]),
                    ),
                  const Divider(color: Colors.white24),
                  Row(children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('共 ${_draft.lines} 注 × ${_draft.multiple} 倍',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13)),
                          Text('虚拟金额 ¥${_draft.amount}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16)),
                        ])),
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
                  const SizedBox(height: 6),
                  const Text('只保存模拟记录，不产生真实投注',
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
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
      setState(draft.tickets.clear);
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
