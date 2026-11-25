import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/lottery_simulation.dart';
import '../services/lottery_simulation_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/lottery/simulation_ticket_numbers.dart';
import 'historical_record_match_screen.dart';

class BettingSimulationRecordsScreen extends StatefulWidget {
  final SimulationLottery? initialLottery;

  const BettingSimulationRecordsScreen({super.key, this.initialLottery});

  @override
  State<BettingSimulationRecordsScreen> createState() =>
      _BettingSimulationRecordsScreenState();
}

class _BettingSimulationRecordsScreenState
    extends State<BettingSimulationRecordsScreen> {
  final _repository = LotterySimulationRepository();
  List<SimulationRecord> _records = [];
  SimulationLottery? _filter;
  bool _loading = true;
  bool _deleting = false;
  String? _error;
  final Set<String> _expandedRecordIds = {};

  List<SimulationRecord> get _visibleRecords {
    final records = _records
        .where((record) => _filter == null || record.lottery == _filter)
        .toList();
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return records;
  }

  @override
  void initState() {
    super.initState();
    _filter = widget.initialLottery;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final records = await _repository.load();
      if (mounted) {
        setState(() {
          _records = records;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = '读取模拟记录失败，请重试';
          _loading = false;
        });
      }
    }
  }

  Future<void> _delete(List<SimulationRecord> records) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(records.length == 1 ? '删除模拟记录' : '清空模拟记录'),
        content: Text(
            '将删除${_filter == null ? '' : _filter!.shortLabel}的 ${records.length} 条记录，删除后无法恢复。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('删除')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      final ids = records.map((record) => record.id).toSet();
      await _repository.delete(ids);
      if (mounted) {
        setState(
            () => _records.removeWhere((record) => ids.contains(record.id)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('删除失败，请重试')));
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  void _openHistoricalMatch(SimulationRecord record) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => HistoricalRecordMatchScreen(record: record),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleRecords;
    final totalAmount =
        visible.fold<int>(0, (sum, record) => sum + record.amount);
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('模拟记录'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: '清空当前记录',
            onPressed:
                _deleting || visible.isEmpty ? null : () => _delete(visible),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Column(children: [
        _buildFilters(),
        if (!_loading && _error == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 2),
            child: Row(children: [
              Text('共 ${visible.length} 条记录',
                  style: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 12)),
              const Spacer(),
              Text('合计虚拟 ¥$totalAmount',
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(_error!),
                        TextButton(onPressed: _load, child: const Text('重试')),
                      ]))
                    : visible.isEmpty
                        ? const Center(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                Icon(Icons.receipt_long_outlined,
                                    color: AppColors.textMuted, size: 56),
                                SizedBox(height: 12),
                                Text('还没有模拟记录',
                                    style: TextStyle(
                                        color: AppColors.textTertiary)),
                              ]))
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                            itemCount: visible.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) =>
                                _recordCard(visible[index]),
                          )),
      ]),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: SimulationLottery.values.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final lottery =
              index == 0 ? null : SimulationLottery.values[index - 1];
          final selected = _filter == lottery;
          return Center(
            child: ChoiceChip(
              label: Text(lottery?.label ?? '全部'),
              selected: selected,
              showCheckmark: false,
              onSelected:
                  _deleting ? null : (_) => setState(() => _filter = lottery),
              backgroundColor: Colors.white,
              selectedColor: AppColors.primary,
              side: BorderSide(
                  color: selected ? AppColors.primary : AppColors.border),
              labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        },
      ),
    );
  }

  String _lotteryAsset(SimulationLottery lottery) => switch (lottery) {
        SimulationLottery.superLotto => 'assets/lottery/dlt.jpg',
        SimulationLottery.doubleColorBall => 'assets/lottery/block-ssq-m.png',
        SimulationLottery.sevenStar => 'assets/lottery/qxc.jpg',
        SimulationLottery.happyEight => 'assets/lottery/block-kl8-m.png',
        SimulationLottery.qilecai => 'assets/lottery/block-qlc-m.png',
      };

  Widget _lotteryIcon(SimulationLottery lottery) => Container(
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(4),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Image.asset(
          _lotteryAsset(lottery),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Center(
            child: Text(lottery.shortLabel,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      );

  Widget _ticketBadge(int index) => Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withOpacity(.12)),
        child: Text('$index',
            style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
      );

  Widget _ticketCard(SimulationRecord record, int displayIndex) {
    // Tickets are stored in selection order; display them newest first to
    // mirror the basket list.
    final ticketIndex = record.tickets.length - 1 - displayIndex;
    final ticket = record.tickets[ticketIndex];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ticketBadge(displayIndex + 1),
              const SizedBox(width: 10),
              Expanded(child: SimulationTicketNumbers(ticket: ticket)),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text('${ticket.playLabel} · ${ticket.lines}注',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _toggleExpand(String id) {
    setState(() {
      if (!_expandedRecordIds.add(id)) {
        _expandedRecordIds.remove(id);
      }
    });
  }

  Widget _recordCard(SimulationRecord record) {
    final date = DateFormat('yyyy-MM-dd HH:mm')
        .format(record.createdAt.toLocal());
    final expanded = _expandedRecordIds.contains(record.id);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        InkWell(
          onTap: () => _toggleExpand(record.id),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
            child: Row(children: [
              _lotteryIcon(record.lottery),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.lottery.label,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(date,
                        style: const TextStyle(
                            color: AppColors.textTertiary, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                        '${record.lines}注 · ${record.multiple}倍${record.additional ? ' · 追加' : ''}',
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('¥${record.amount}',
                      style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.icon(
                onPressed: _deleting
                    ? null
                    : () => _openHistoricalMatch(record),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.manage_search, size: 16),
                label: const Text('历史中奖匹配'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _deleting ? null : () => _delete([record]),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('删除记录'),
              ),
            ],
          ),
        ),
        if (expanded) ...[
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                for (var i = 0; i < record.tickets.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _ticketCard(record, i),
                ],
              ],
            ),
          ),
        ],
      ]),
    );
  }
}