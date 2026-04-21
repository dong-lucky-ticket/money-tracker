import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/category.dart';
import 'models/record.dart';
import 'providers/data_provider.dart';
import 'screens/main_tab_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(RecordAdapter());

  final dataProvider = DataProvider();
  await dataProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: dataProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    
    return MaterialApp(
      title: '蓝账本',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF0F2F5),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A90E2)),
        fontFamily: 'Roboto', // Fallback font
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: dataProvider.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      home: const MainTabScreen(),
    );
  }
}
