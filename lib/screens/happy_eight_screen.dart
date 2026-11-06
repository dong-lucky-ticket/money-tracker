import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/happy_eight_draw.dart';
import '../services/happy_eight_crawler.dart';
import '../services/happy_eight_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/common/empty_state.dart';
import 'happy_eight_announcement_screen.dart';

class HappyEightScreen extends StatefulWidget {
  const HappyEightScreen({super.key});

  @override
  State<HappyEightScreen> createState() => _HappyEightScreenState();
}

class _HappyEightScreenState extends State<HappyEightScreen> {
  final _syncService = HappyEightSyncService();
  List<HappyEightDraw> _draws = const [];
  String? _error;
  String? _message;
  String? _busyIssue;
  Timer? _messageTimer;
  bool _loading = false;
  int? _limit = 30;

  @override
  void initState() {
    super.initState();
    _loadCached();
  }

  Future<void> _loadCached() async {
    try {
      final draws = await _syncService.loadCachedDraws(limit: _limit);
      if (mounted) setState(() => _draws = draws);
    } catch (_) {
      if (mounted) setState(() => _error = '读取本地开奖记录失败，请稍后重试。');
    }
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    try {
      final result = await _syncService.refreshLatest(
        limit: _limit ?? 100,
        onListingLoaded: (draws) {
          if (mounted) setState(() => _draws = draws);
        },
      );
      if (!mounted) return;
      setState(() {
        _draws = result.draws;
        _message = result.addedDrawCount == 0
            ? null
            : '已补齐 ${result.addedDrawCount} 期遗漏记录';
        _loading = false;
      });
      _dismissMessage();
    } on HappyEightCrawlException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = '更新开奖数据时发生异常，请稍后重试。';
          _loading = false;
        });
      }
    }
  }

  Future<void> _changeLimit(int value) async {
    final limit = value == -1 ? null : value;
    if (_loading || _limit == limit) return;
    setState(() => _limit = limit);
    await _loadCached();
    if (limit != null) await _refresh();
  }

  Future<void> _showActions(HappyEightDraw draw) async {
    if (_busyIssue != null) return;
    final action = await showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text('第${draw.issue}期'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, 'refresh'),
            child: const Text('重新抓取本期'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, 'delete'),
            child: const Text('删除本期'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
      ),
    );
    if (!mounted) return;
    if (action == 'refresh') {
      setState(() => _busyIssue = draw.issue);
      try {
        final updated = await _syncService.refreshIssue(draw.issue);
        if (mounted) {
          setState(() {
            _draws = [
              for (final item in _draws)
                item.issue == draw.issue ? updated : item
            ];
            _message = '第${draw.issue}期已重新抓取并覆盖原有数据';
          });
          _dismissMessage();
        }
      } on HappyEightCrawlException catch (error) {
        if (mounted) setState(() => _error = error.message);
      } finally {
        if (mounted) setState(() => _busyIssue = null);
      }
    } else if (action == 'delete') {
      setState(() => _busyIssue = draw.issue);
      try {
        await _syncService.deleteIssue(draw.issue);
        if (mounted) {
          setState(
              () => _draws.removeWhere((item) => item.issue == draw.issue));
        }
      } finally {
        if (mounted) setState(() => _busyIssue = null);
      }
    }
  }

  void _dismissMessage() {
    _messageTimer?.cancel();
    if (_message != null) {
      _messageTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _message = null);
      });
    }
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.pageBackground,
        appBar: AppBar(
          title: const Text('福彩快乐8'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          actions: [
            IconButton(
              tooltip: '同步福彩快乐8数据',
              onPressed: _loading ? null : _refresh,
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.sync),
            ),
          ],
        ),
        body: _body(),
      );

  Widget _body() {
    if (_draws.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_draws.isEmpty && _error != null) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_outlined,
            size: 48, color: AppColors.textMuted),
        const SizedBox(height: 12),
        Text(_error!, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        OutlinedButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('重试')),
      ]));
    }
    if (_draws.isEmpty) {
      return const Center(
          child: EmptyState(
              icon: Icon(Icons.confirmation_number_outlined,
                  size: 48, color: AppColors.textMuted),
              title: '暂无开奖记录',
              subtitle: '点击右上角同步开奖数据'));
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Row(children: [
            const Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('福彩快乐8',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  SizedBox(height: 4),
                  Text('中国福彩网历史数据',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textTertiary)),
                ])),
            PopupMenuButton<int>(
              enabled: !_loading,
              tooltip: '选择显示范围',
              onSelected: _changeLimit,
              itemBuilder: (_) => const [
                PopupMenuItem(value: 30, child: Text('最近30期')),
                PopupMenuItem(value: 50, child: Text('最近50期')),
                PopupMenuItem(value: 100, child: Text('最近100期')),
                PopupMenuItem(value: -1, child: Text('全部')),
              ],
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_limit == null ? '全部' : '最近$_limit期',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textTertiary)),
                const Icon(Icons.arrow_drop_down,
                    color: AppColors.textTertiary),
              ]),
            ),
          ]),
          if (_loading)
            const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator()),
          if (_error != null) _status(_error!, true),
          if (_message != null) _status(_message!, false),
          const SizedBox(height: 16),
          ..._draws.map(_drawItem),
        ],
      ),
    );
  }

  Widget _status(String text, bool error) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(text,
            style: TextStyle(
                color: error ? AppColors.warning : AppColors.primary)),
      );

  Widget _drawItem(HappyEightDraw draw) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onLongPress: _busyIssue == null ? () => _showActions(draw) : null,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    HappyEightAnnouncementScreen(draw: draw, draws: _draws))),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text('第${draw.issue}期',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      const Spacer(),
                      Text(DateFormat('yyyy-MM-dd').format(draw.publishDate),
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textTertiary)),
                      const Icon(Icons.chevron_right,
                          size: 20, color: AppColors.textMuted),
                    ]),
                    const SizedBox(height: 14),
                    Wrap(
                        spacing: 6,
                        runSpacing: 7,
                        children: draw.numbers
                            .map((number) => Container(
                                  width: 30,
                                  height: 30,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                      color: Color(0xFFE34B4B),
                                      shape: BoxShape.circle),
                                  child: Text(number,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                ))
                            .toList()),
                  ]),
            ),
          ),
        ),
      );
}
