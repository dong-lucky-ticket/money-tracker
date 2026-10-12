import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/seven_star_draw.dart';
import '../services/seven_star_crawler.dart';
import '../services/seven_star_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/common/empty_state.dart';
import 'lottery_rules_screen.dart';

class SevenStarScreen extends StatefulWidget {
  const SevenStarScreen({super.key});

  @override
  State<SevenStarScreen> createState() => _SevenStarScreenState();
}

class _SevenStarScreenState extends State<SevenStarScreen> {
  final SevenStarSyncService _syncService = SevenStarSyncService();
  List<SevenStarDraw> _draws = const [];
  String? _errorMessage;
  String? _syncMessage;
  String? _busyIssue;
  Timer? _syncMessageTimer;
  bool _isLoading = false;
  int? _drawLimit = 30;

  @override
  void initState() {
    super.initState();
    _loadCachedDraws();
  }

  @override
  void dispose() {
    _syncMessageTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCachedDraws() async {
    try {
      final cached = await _syncService.loadCachedDraws(limit: _drawLimit);
      if (mounted) setState(() => _draws = cached);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = '读取本地开奖记录失败，请稍后重试。');
    }
  }

  Future<void> _refresh() async {
    if (_isLoading) return;
    _syncMessageTimer?.cancel();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _syncMessage = null;
    });
    try {
      final result = await _syncService.refreshLatest(
        limit: _drawLimit ?? 100,
      );
      if (!mounted) return;
      final message = result.addedDrawCount > 0
          ? '已补齐 ${result.addedDrawCount} 期遗漏记录'
          : null;
      setState(() {
        _draws = result.draws;
        _syncMessage = message;
        _isLoading = false;
      });
      if (message != null) _dismissSyncMessageAfterDelay();
    } on SevenStarCrawlException catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.message;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = '更新体彩七星彩开奖数据时发生异常，请稍后重试。';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _changeDrawLimit(int limit) async {
    final selectedLimit = limit == -1 ? null : limit;
    if (_drawLimit == selectedLimit || _isLoading) return;
    setState(() => _drawLimit = selectedLimit);
    await _loadCachedDraws();
    if (selectedLimit != null) await _refresh();
  }

  Future<void> _showDrawActions(SevenStarDraw draw) async {
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

  Future<void> _refetchIssue(String issue) async {
    setState(() {
      _busyIssue = issue;
      _errorMessage = null;
    });
    try {
      final refreshed = await _syncService.refreshIssue(issue);
      if (!mounted) return;
      setState(() {
        final index = _draws.indexWhere((draw) => draw.issue == issue);
        if (index >= 0) _draws = [..._draws]..[index] = refreshed;
        _syncMessage = '第$issue期已重新抓取并覆盖原有数据';
      });
      _dismissSyncMessageAfterDelay();
    } on SevenStarCrawlException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = '重新抓取第$issue期失败，请稍后重试。');
    } finally {
      if (mounted) setState(() => _busyIssue = null);
    }
  }

  Future<void> _deleteDraw(SevenStarDraw draw) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除开奖记录'),
        content: Text('确定删除第${draw.issue}期的体彩七星彩开奖记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;
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

  void _dismissSyncMessageAfterDelay() {
    _syncMessageTimer?.cancel();
    _syncMessageTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _syncMessage = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('体彩七星彩'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _refresh,
            tooltip: '同步体彩七星彩数据',
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const LotteryRulesScreen(lotteryType: '体彩七星彩'),
              ),
            ),
            tooltip: '体彩七星彩玩法规则',
            icon: const Icon(Icons.rule, size: 18),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _draws.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _draws.isEmpty && _errorMessage != null
              ? _buildLoadError()
              : _draws.isEmpty
                  ? const Center(
                      child: EmptyState(
                        icon: Icon(Icons.confirmation_number_outlined,
                            size: 48, color: AppColors.textMuted),
                        title: '暂无开奖记录',
                      ),
                    )
                  : RefreshIndicator(
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
                            _StatusMessage(
                                message: _errorMessage!, isError: true),
                          ],
                          if (_syncMessage != null) ...[
                            const SizedBox(height: 12),
                            _StatusMessage(
                                message: _syncMessage!, isError: false),
                          ],
                          const SizedBox(height: 16),
                          ..._draws.map(_buildDrawItem),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildLoadError() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text('开奖数据更新失败'),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(_errorMessage!, textAlign: TextAlign.center),
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

  Widget _buildHeader() => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('体彩七星彩',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text('中国体彩网历史数据（${_draws.length}条）',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textTertiary)),
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
                  _drawLimit == null ? '全部' : '最近$_drawLimit期',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textTertiary),
                ),
                const Icon(Icons.arrow_drop_down,
                    color: AppColors.textTertiary),
              ],
            ),
          ),
        ],
      );

  Widget _buildDrawItem(SevenStarDraw draw) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onLongPress:
                _busyIssue == null ? () => _showDrawActions(draw) : null,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SevenStarAnnouncementScreen(
                  draw: draw,
                  draws: _draws,
                ),
              ),
            ),
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
                      Text('第${draw.issue}期',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      const Spacer(),
                      Text(DateFormat('yyyy-MM-dd').format(draw.publishDate),
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textTertiary)),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right,
                          size: 20, color: AppColors.textMuted),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      ...draw.numbers.take(6).map(
                            (number) => _DrawBall(
                                number: number, color: AppColors.primary),
                          ),
                      ...draw.numbers.skip(6).map(
                            (number) =>
                                _DrawBall(number: number, color: Colors.orange),
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

class SevenStarAnnouncementScreen extends StatefulWidget {
  final SevenStarDraw draw;
  final List<SevenStarDraw> draws;

  const SevenStarAnnouncementScreen({
    super.key,
    required this.draw,
    List<SevenStarDraw>? draws,
  }) : draws = draws ?? const [];

  @override
  State<SevenStarAnnouncementScreen> createState() =>
      _SevenStarAnnouncementScreenState();
}

class _SevenStarAnnouncementScreenState
    extends State<SevenStarAnnouncementScreen> {
  static const _switchThreshold = 72.0;
  late final List<SevenStarDraw> _draws;
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
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LotteryRulesScreen(
                  lotteryType: '体彩七星彩',
                  issue: draw.issue,
                  primaryNumbers: draw.numbers.take(6).toList(),
                  secondaryNumbers: draw.numbers.skip(6).toList(),
                ),
              ),
            ),
            tooltip: '体彩七星彩玩法规则',
            icon: const Icon(Icons.rule, size: 18),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _draws.length,
        onPageChanged: (index) => setState(() {
          _currentIndex = index;
          _overscrollDistance = 0;
          _overscrollDirection = null;
        }),
        itemBuilder: (context, index) =>
            NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: _SevenStarAnnouncementBody(
            draw: _draws[index],
          ),
        ),
      ),
    );
  }
}

class _SevenStarAnnouncementBody extends StatelessWidget {
  final SevenStarDraw draw;

  const _SevenStarAnnouncementBody({required this.draw});

  @override
  Widget build(BuildContext context) => ListView(
        key: PageStorageKey('seven-star-${draw.issue}'),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(
            '体彩七星彩',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 4),
          Text('发布日期 ${DateFormat('yyyy-MM-dd').format(draw.publishDate)}',
              style: const TextStyle(color: AppColors.textTertiary)),
          const SizedBox(height: 20),
          _DetailSection(
            title: '开奖号码',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('本期开奖号码',
                    style: TextStyle(color: AppColors.textTertiary)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...draw.numbers.take(6).map(
                          (number) => _DrawBall.detail(
                              number: number, color: AppColors.primary),
                        ),
                    ...draw.numbers.skip(6).map(
                          (number) => _DrawBall.detail(
                              number: number, color: Colors.orange),
                        ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _DetailSection(
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
          if (draw.salesAmount != null || draw.poolAmount != null) ...[
            const SizedBox(height: 16),
            _DetailSection(
              title: '销售与奖池',
              child: Column(
                children: [
                  if (draw.salesAmount != null)
                    _InfoRow(label: '本期销售额', value: '${draw.salesAmount}元'),
                  if (draw.poolAmount != null)
                    _InfoRow(label: '开奖后奖池', value: '${draw.poolAmount}元'),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _DetailSection(
            title: '公告链接',
            child: draw.announcementUrl.isEmpty
                ? const Text('暂无公告链接',
                    style: TextStyle(color: AppColors.textTertiary))
                : Tooltip(
                    message: '点击复制',
                    child: GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: draw.announcementUrl));
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

class _DrawBall extends StatelessWidget {
  final String number;
  final Color color;
  final double size;
  final double? fontSize;

  const _DrawBall({
    required this.number,
    required this.color,
  })  : size = 32,
        fontSize = 13;

  const _DrawBall.detail({required this.number, required this.color})
      : size = 34,
        fontSize = null;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Text(number,
            style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.bold)),
      );
}

class _DetailSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _DetailSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary)),
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

class _PrizeTierTable extends StatelessWidget {
  final List<SevenStarPrizeTier> tiers;

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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _StatusMessage extends StatelessWidget {
  final String message;
  final bool isError;

  const _StatusMessage({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isError ? const Color(0xFFFFF1F0) : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isError ? AppColors.danger : AppColors.primary,
            fontSize: 12,
          ),
        ),
      );
}
