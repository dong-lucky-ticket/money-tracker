import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/super_lotto_draw.dart';
import '../services/super_lotto_crawler.dart';
import '../services/super_lotto_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/common/empty_state.dart';
import 'super_lotto_announcement_screen.dart';
import 'lottery_rules_screen.dart';

class LotteryScreen extends StatefulWidget {
  final String lotteryType;

  const LotteryScreen({super.key, required this.lotteryType});

  @override
  State<LotteryScreen> createState() => _LotteryScreenState();
}

class _LotteryScreenState extends State<LotteryScreen> {
  final SuperLottoSyncService _syncService = SuperLottoSyncService();
  List<SuperLottoDraw> _draws = const [];
  String? _errorMessage;
  int _completedAnnouncements = 0;
  int _totalAnnouncements = 0;
  int _failedAnnouncements = 0;
  bool _isLoading = false;
  int? _drawLimit = 30;
  String? _busyIssue;
  String? _syncMessage;
  Timer? _syncMessageTimer;

  bool get _isSporttery => widget.lotteryType == '体彩';

  @override
  void initState() {
    super.initState();
    if (_isSporttery) {
      _loadCachedDraws();
    }
  }

  Future<void> _loadCachedDraws() async {
    try {
      final cached = await _syncService.loadCachedDraws(limit: _drawLimit);
      if (mounted && cached.isNotEmpty) {
        setState(() => _draws = cached);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = '读取本地开奖记录失败，请稍后重试。');
      }
    }
  }

  Future<void> _refresh() async {
    if (_isLoading) {
      return;
    }

    _syncMessageTimer?.cancel();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _completedAnnouncements = 0;
      _totalAnnouncements = 0;
      _failedAnnouncements = 0;
      _syncMessage = null;
    });

    try {
      final result = await _syncService.refreshLatest(
        limit: _drawLimit ?? 100,
        onListingLoaded: (draws) {
          if (!mounted) {
            return;
          }
          setState(() => _draws = draws);
        },
        onAnnouncementProgress: (completed, total) {
          if (!mounted) {
            return;
          }
          setState(() {
            _completedAnnouncements = completed;
            _totalAnnouncements = total;
          });
        },
      );
      if (!mounted) {
        return;
      }
      final syncMessage = _buildSyncMessage(result);
      setState(() {
        _draws = result.draws;
        _failedAnnouncements = result.failedAnnouncementIssues.length;
        _syncMessage = syncMessage;
        _isLoading = false;
      });
      if (syncMessage != null) {
        _dismissSyncMessageAfterDelay();
      }
    } on SuperLottoCrawlException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = '更新开奖数据时发生异常，请稍后重试。';
        _isLoading = false;
      });
    }
  }

  Future<void> _changeDrawLimit(int limit) async {
    final selectedLimit = limit == -1 ? null : limit;
    if (_drawLimit == selectedLimit || _isLoading) {
      return;
    }
    setState(() => _drawLimit = selectedLimit);
    await _loadCachedDraws();
    if (selectedLimit != null) {
      await _refresh();
    }
  }

  Future<void> _refetchIssue(String value) async {
    final issue = value.trim();
    if (_busyIssue != null || issue.isEmpty) return;
    setState(() {
      _busyIssue = issue;
      _errorMessage = null;
    });
    try {
      final refreshed = await _syncService.refreshIssue(issue);
      if (!mounted) return;
      setState(() {
        final index = _draws.indexWhere((draw) => draw.issue == issue);
        if (index >= 0) {
          _draws = [..._draws]..[index] = refreshed;
        }
        _syncMessage = '第$issue期已重新抓取并覆盖原有数据';
      });
      _dismissSyncMessageAfterDelay();
    } on SuperLottoCrawlException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = '重新抓取第$issue期失败，请稍后重试。');
    } finally {
      if (mounted) setState(() => _busyIssue = null);
    }
  }

  Future<void> _deleteDraw(SuperLottoDraw draw) async {
    if (_busyIssue != null) return;
    setState(() {
      _busyIssue = draw.issue;
      _errorMessage = null;
    });
    try {
      await _syncService.deleteIssue(draw.issue);
      if (!mounted) return;
      setState(() {
        _draws = _draws.where((item) => item.issue != draw.issue).toList();
        _syncMessage = '第${draw.issue}期已删除';
      });
      _dismissSyncMessageAfterDelay();
    } catch (_) {
      if (mounted) setState(() => _errorMessage = '删除第${draw.issue}期失败，请稍后重试。');
    } finally {
      if (mounted) setState(() => _busyIssue = null);
    }
  }

  Future<void> _showDrawActions(SuperLottoDraw draw) async {
    if (_busyIssue != null) return;
    final action = await showCupertinoModalPopup<String>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: Text('第${draw.issue}期'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(sheetContext).pop('refetch'),
            child: const Text('重新抓取本期'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(sheetContext).pop('delete'),
            child: const Text('删除本期'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(sheetContext).pop(),
          child: const Text('取消'),
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'refetch') {
      await _refetchIssue(draw.issue);
    } else if (action == 'delete') {
      await _deleteDraw(draw);
    }
  }

  void _dismissSyncMessageAfterDelay() {
    _syncMessageTimer?.cancel();
    _syncMessageTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _syncMessage = null);
      }
    });
  }

  @override
  void dispose() {
    _syncMessageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canGoBack = Navigator.of(context).canPop();
    final hasLeadingActions = canGoBack || _isSporttery;
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text(widget.lotteryType),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: canGoBack && _isSporttery ? 104 : 56,
        leading: hasLeadingActions
            ? Row(
                children: [
                  if (canGoBack)
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      tooltip: '返回',
                      icon: const Icon(Icons.arrow_back),
                    ),
                  if (_isSporttery)
                    IconButton(
                      onPressed: _isLoading ? null : _refresh,
                      tooltip: '同步大乐透数据',
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync),
                    ),
                ],
              )
            : null,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const LotteryRulesScreen(lotteryType: '体彩'),
              ),
            ),
            icon: const Icon(Icons.rule, size: 18),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isSporttery ? _buildSportteryBody() : _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: EmptyState(
        icon: const Icon(
          Icons.confirmation_number_outlined,
          size: 48,
          color: AppColors.textMuted,
        ),
        title: '暂未记录${widget.lotteryType}开奖信息',
        subtitle: '开奖期号和中奖表格将在这里展示',
      ),
    );
  }

  Widget _buildSportteryBody() {
    if (_draws.isEmpty && _isLoading) {
      return _LoadingState(message: _loadingMessage);
    }
    if (_draws.isEmpty && _errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            const Text(
              '开奖数据更新失败',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }
    if (_draws.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: Icon(
            Icons.confirmation_number_outlined,
            size: 48,
            color: AppColors.textMuted,
          ),
          title: '暂无开奖记录',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildHeader(),
          if (_isLoading) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            _StatusMessage(message: _errorMessage!, isError: true),
          ],
          if (_syncMessage != null) ...[
            const SizedBox(height: 12),
            _StatusMessage(message: _syncMessage!, isError: false),
          ],
          if (_failedAnnouncements > 0) ...[
            const SizedBox(height: 12),
            _StatusMessage(
              message: '$_failedAnnouncements 期公告详情暂未解析成功，可下拉重试。',
              isError: true,
            ),
          ],
          const SizedBox(height: 16),
          ..._draws.map(_buildDrawItem),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '超级大乐透',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '江苏体彩网历史数据（${_draws.length}条）',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        PopupMenuButton<int>(
          enabled: !_isLoading,
          tooltip: '选择显示范围',
          onSelected: _changeDrawLimit,
          itemBuilder: (context) => const [
            PopupMenuItem(value: 30, child: Text('最近30期')),
            PopupMenuItem(value: 50, child: Text('最近50期')),
            PopupMenuItem(value: 100, child: Text('最近100期')),
            PopupMenuItem(value: -1, child: Text('全部')),
          ],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isLoading
                    ? _loadingMessage
                    : _drawLimit == null
                        ? '全部'
                        : '最近$_drawLimit期',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: AppColors.textTertiary),
            ],
          ),
        ),
      ],
    );
  }

  String get _loadingMessage {
    if (_totalAnnouncements == 0) {
      return '正在获取${_drawLimit ?? 100}期开奖结果';
    }
    return '正在解析公告 $_completedAnnouncements/$_totalAnnouncements';
  }

  String? _buildSyncMessage(SuperLottoSyncResult result) {
    final messages = <String>[];
    if (result.addedDrawCount > 0) {
      messages.add('已补齐 ${result.addedDrawCount} 期遗漏记录');
    }
    if (result.skippedAnnouncementCount > 0) {
      messages.add('复用 ${result.skippedAnnouncementCount} 期已解析公告');
    }
    return messages.isEmpty ? null : messages.join('，');
  }

  Widget _buildDrawItem(SuperLottoDraw draw) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onLongPress: _busyIssue == null ? () => _showDrawActions(draw) : null,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SuperLottoAnnouncementScreen(
                  draw: draw,
                  draws: _draws,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '第${draw.issue}期',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('yyyy-MM-dd').format(draw.publishDate),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    ...draw.frontNumbers.map(
                      (number) =>
                          _DrawBall(number: number, color: AppColors.danger),
                    ),
                    ...draw.backNumbers.map(
                      (number) =>
                          _DrawBall(number: number, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  final String message;
  final bool isError;

  const _StatusMessage({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.warning : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(isError ? Icons.info_outline : Icons.info,
              size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: color, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  final String message;

  const _LoadingState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}

class _DrawBall extends StatelessWidget {
  final String number;
  final Color color;

  const _DrawBall({required this.number, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        number,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
