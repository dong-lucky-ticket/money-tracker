import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/category.dart';
import 'models/category_group.dart';
import 'models/record.dart';
import 'providers/data_provider.dart';
import 'screens/main_tab_screen.dart';
import 'services/error_log_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final errorLogService = ErrorLogService.instance;

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(
      errorLogService.recordFlutterError(
        details,
        source: 'flutter_framework',
      ),
    );
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    unawaited(
      errorLogService.record(
        error,
        stackTrace: stackTrace,
        source: 'platform_dispatcher',
      ),
    );
    return true;
  };

  ErrorWidget.builder = (details) {
    return _GlobalErrorFallback(
      message: details.exceptionAsString(),
    );
  };

  runZonedGuarded(
    () {
      runApp(const AppBootstrap());
    },
    (error, stackTrace) {
      unawaited(
        errorLogService.record(
          error,
          stackTrace: stackTrace,
          source: 'zone_guarded',
        ),
      );
    },
  );
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  static const Duration _minimumSplashDuration = Duration(milliseconds: 1500);

  DataProvider? _dataProvider;
  DataSyncProgress _progress = const DataSyncProgress(
    message: '正在启动应用',
    detail: '准备加载本地账本数据',
    isIndeterminate: true,
  );
  String? _errorMessage;
  bool _showSlowHint = false;
  Timer? _slowHintTimer;
  int _bootstrapToken = 0;

  @override
  void initState() {
    super.initState();
    _startBootstrap();
  }

  @override
  void dispose() {
    _slowHintTimer?.cancel();
    super.dispose();
  }

  void _startBootstrap() {
    final bootstrapToken = ++_bootstrapToken;
    final minimumSplashFuture = Future<void>.delayed(_minimumSplashDuration);

    _slowHintTimer?.cancel();
    _dataProvider = null;

    setState(() {
      _errorMessage = null;
      _showSlowHint = false;
      _progress = const DataSyncProgress(
        message: '正在启动应用',
        detail: '准备加载本地账本数据',
        isIndeterminate: true,
      );
    });

    _slowHintTimer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted || _dataProvider != null || _errorMessage != null) {
        return;
      }

      setState(() {
        _showSlowHint = true;
      });
    });

    _initialize(
      bootstrapToken: bootstrapToken,
      minimumSplashFuture: minimumSplashFuture,
    );
  }

  Future<void> _initialize({
    required int bootstrapToken,
    required Future<void> minimumSplashFuture,
  }) async {
    try {
      await Hive.initFlutter();
      await ErrorLogService.instance.init();
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(CategoryAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(CategoryGroupAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(RecordAdapter());
      }

      final dataProvider = DataProvider();
      await dataProvider.init(
        onProgress: (progress) {
          if (!mounted || bootstrapToken != _bootstrapToken) {
            return;
          }

          setState(() {
            _progress = progress;
          });
        },
      );

      await minimumSplashFuture;

      if (!mounted || bootstrapToken != _bootstrapToken) {
        return;
      }

      _slowHintTimer?.cancel();
      setState(() {
        _dataProvider = dataProvider;
      });
    } catch (e, stackTrace) {
      await ErrorLogService.instance.record(
        e,
        stackTrace: stackTrace,
        source: 'bootstrap_initialize',
      );
      await minimumSplashFuture;

      if (!mounted || bootstrapToken != _bootstrapToken) {
        return;
      }

      _slowHintTimer?.cancel();
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dataProvider != null) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: _dataProvider!),
          ChangeNotifierProvider.value(value: ErrorLogService.instance),
        ],
        child: const MyApp(),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _BootstrapScreen(
        progress: _progress,
        errorMessage: _errorMessage,
        showSlowHint: _showSlowHint,
        onRetry: _errorMessage == null ? null : _startBootstrap,
      ),
    );
  }
}

class _BootstrapScreen extends StatelessWidget {
  final DataSyncProgress progress;
  final String? errorMessage;
  final bool showSlowHint;
  final VoidCallback? onRetry;

  const _BootstrapScreen({
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

class _GlobalErrorFallback extends StatelessWidget {
  final String message;

  const _GlobalErrorFallback({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F9FC),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x110F172A),
                    blurRadius: 24,
                    offset: Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFDC2626),
                    size: 34,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '页面暂时无法显示',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '应用已尝试记录错误信息，你可以返回上一页后重试。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFF4B5563).withOpacity(0.95),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();

    return MaterialApp(
      title: '记账助储',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      locale: const Locale('zh', 'CN'),
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF0F2F5),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A90E2)),
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: dataProvider.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      home: const MainTabScreen(),
    );
  }
}
