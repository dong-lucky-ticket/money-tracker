import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'models/data_sync_progress.dart';
import 'providers/data_provider.dart';
import 'screens/main_tab_screen.dart';
import 'services/app_bootstrap_service.dart';
import 'services/app_error_handler_service.dart';
import 'services/error_log_service.dart';
import 'widgets/bootstrap/app_bootstrap_screen.dart';

void main() {
  final errorLogService = ErrorLogService.instance;

  AppErrorHandlerService.run(
    errorLogService: errorLogService,
    appRunner: () async {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ));
      runApp(const AppBootstrap());
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
  ErrorLogService? _errorLogService;
  DataSyncProgress _progress = AppBootstrapService.initialProgress;
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
    _errorLogService = null;

    setState(() {
      _errorMessage = null;
      _showSlowHint = false;
      _progress = AppBootstrapService.initialProgress;
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
      final snapshot = await AppBootstrapService.bootstrap(
        onProgress: (progress) {
          if (!mounted || bootstrapToken != _bootstrapToken) {
            return;
          }

          setState(() {
            _progress = progress;
          });
        },
      );
      final dataProvider = snapshot.dataProvider;

      await minimumSplashFuture;

      if (!mounted || bootstrapToken != _bootstrapToken) {
        return;
      }

      _slowHintTimer?.cancel();
      setState(() {
        _dataProvider = dataProvider;
        _errorLogService = snapshot.errorLogService;
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
          ChangeNotifierProvider.value(value: _errorLogService!),
        ],
        child: const MyApp(),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AppBootstrapScreen(
        progress: _progress,
        errorMessage: _errorMessage,
        showSlowHint: _showSlowHint,
        onRetry: _errorMessage == null ? null : _startBootstrap,
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
