import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'controllers/app_bootstrap_controller.dart';
import 'providers/data_provider.dart';
import 'screens/main_tab_screen.dart';
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
  late final AppBootstrapController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppBootstrapController()..startBootstrap();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final dataProvider = _controller.dataProvider;
        final errorLogService = _controller.errorLogService;
        final operationLogService = _controller.operationLogService;

        if (dataProvider != null &&
            errorLogService != null &&
            operationLogService != null) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: dataProvider),
              ChangeNotifierProvider.value(value: errorLogService),
              ChangeNotifierProvider.value(value: operationLogService),
            ],
            child: const MyApp(),
          );
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: AppBootstrapScreen(
            progress: _controller.progress,
            errorMessage: _controller.errorMessage,
            showSlowHint: _controller.showSlowHint,
            onRetry: _controller.errorMessage == null
                ? null
                : _controller.startBootstrap,
          ),
        );
      },
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
