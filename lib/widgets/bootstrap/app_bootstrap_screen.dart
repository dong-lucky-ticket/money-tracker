import 'package:flutter/material.dart';

import '../../models/data_sync_progress.dart';

class AppBootstrapScreen extends StatelessWidget {
  final DataSyncProgress progress;
  final String? errorMessage;
  final bool showSlowHint;
  final VoidCallback? onRetry;

  const AppBootstrapScreen({
    super.key,
    required this.progress,
    required this.errorMessage,
    required this.showSlowHint,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isError = errorMessage != null;
    final statusText = isError
        ? '启动失败，请重新尝试'
        : showSlowHint
            ? (progress.detail ?? '正在整理本地数据')
            : '正在进入你的账本';

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF6FBFF),
              Color(0xFFE8F1FF),
              Color(0xFFF8F5EF),
            ],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -80,
              right: -40,
              child: _SplashGlow(
                size: 220,
                colors: [Color(0x554A90E2), Color(0x114A90E2)],
              ),
            ),
            const Positioned(
              left: -70,
              bottom: 120,
              child: _SplashGlow(
                size: 200,
                colors: [Color(0x33F59E0B), Color(0x11F59E0B)],
              ),
            ),
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: Column(
                  children: [
                    const Spacer(),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        children: [
                          const _SplashIllustration(),
                          const SizedBox(height: 36),
                          Text(
                            '记账助储',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF14304A),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '把每一笔日常，都慢慢存成底气',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: const Color(0xFF4B6378),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(999),
                              border:
                                  Border.all(color: const Color(0x33FFFFFF)),
                            ),
                            child: const Text(
                              '记录支出 · 看见趋势 · 留住结余',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF56718A),
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOut,
                      constraints: const BoxConstraints(maxWidth: 420),
                      padding: EdgeInsets.fromLTRB(
                        18,
                        16,
                        18,
                        isError && onRetry != null ? 18 : 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(isError ? 0.92 : 0.72),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isError
                              ? const Color(0x22DC2626)
                              : const Color(0x22FFFFFF),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x110F172A),
                            blurRadius: 30,
                            offset: Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              if (isError)
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 18,
                                  color: Color(0xFFDC2626),
                                )
                              else
                                const _SplashLoadingDots(),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 240),
                                  child: Text(
                                    statusText,
                                    key: ValueKey(statusText),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF31465A),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (showSlowHint && !isError) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                minHeight: 4,
                                value: progress.value,
                                backgroundColor: const Color(0x1A4A90E2),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF4A90E2),
                                ),
                              ),
                            ),
                          ],
                          if (isError && errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF7C2D12),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                          if (isError && onRetry != null) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: onRetry,
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF1D4ED8),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text('重新尝试'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashGlow extends StatelessWidget {
  final double size;
  final List<Color> colors;

  const _SplashGlow({
    required this.size,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}

class _SplashIllustration extends StatelessWidget {
  const _SplashIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 210,
            height: 210,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFEBF5FF),
                  Color(0xFFD7E9FF),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x223B82F6),
                  blurRadius: 40,
                  offset: Offset(0, 22),
                ),
              ],
            ),
          ),
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: const Color(0xFFE7EEF8)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x120F172A),
                  blurRadius: 24,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.savings_rounded,
                  size: 52,
                  color: Color(0xFF2563EB),
                ),
                SizedBox(height: 10),
                Text(
                  'Balance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF17324D),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            top: 28,
            right: 20,
            child: _SplashTag(
              icon: Icons.arrow_downward_rounded,
              label: '支出',
              color: Color(0xFFF97316),
            ),
          ),
          const Positioned(
            left: 8,
            bottom: 46,
            child: _SplashTag(
              icon: Icons.arrow_upward_rounded,
              label: '收入',
              color: Color(0xFF10B981),
            ),
          ),
          Positioned(
            right: 4,
            bottom: 14,
            child: Transform.rotate(
              angle: -0.12,
              child: Container(
                width: 78,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF17324D),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '本月',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9FB7CF),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '结余',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SplashTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x110F172A),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashLoadingDots extends StatefulWidget {
  const _SplashLoadingDots();

  @override
  State<_SplashLoadingDots> createState() => _SplashLoadingDotsState();
}

class _SplashLoadingDotsState extends State<_SplashLoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (index) {
              final phase = (_controller.value - index * 0.18) % 1.0;
              final opacity = 0.35 + (1 - phase).clamp(0.0, 1.0) * 0.65;
              return Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2).withOpacity(opacity),
                  shape: BoxShape.circle,
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
