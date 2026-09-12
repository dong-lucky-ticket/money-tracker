import 'dart:io';

import 'package:expensetracker/screens/unit_converter_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  test('converts traditional and international length units', () {
    final meter =
        unitCategories.first.units.firstWhere((unit) => unit.symbol == 'm');
    final chi =
        unitCategories.first.units.firstWhere((unit) => unit.symbol == '尺');
    final nauticalMile =
        unitCategories.first.units.firstWhere((unit) => unit.symbol == 'nmi');

    expect(chi.convertTo(meter, 1), closeTo(1 / 3, 0.0000001));
    expect(nauticalMile.convertTo(meter, 1), 1852);
  });

  test('converts temperature with offsets', () {
    final celsius =
        unitCategories.firstWhere((category) => category.name == '温度').units[0];
    final fahrenheit =
        unitCategories.firstWhere((category) => category.name == '温度').units[1];
    final kelvin =
        unitCategories.firstWhere((category) => category.name == '温度').units[2];

    expect(celsius.convertTo(fahrenheit, 0), 32);
    expect(fahrenheit.convertTo(celsius, 212), 100);
    expect(celsius.convertTo(kelvin, 0), 273.15);
  });

  testWidgets('restores the last conversion from local settings',
      (tester) async {
    final directory = await Directory.systemTemp.createTemp('unit-converter');
    Hive.init(directory.path);
    final box = await Hive.openBox('settingsBox');
    await box.putAll({
      'unitConverter.categoryIndex': 4,
      'unitConverter.fromIndex': 1,
      'unitConverter.toIndex': 0,
      'unitConverter.input': '212',
    });

    await tester.pumpWidget(const MaterialApp(home: UnitConverterScreen()));
    await tester.pumpAndSettle();

    final input = tester.widget<TextField>(find.byType(TextField));
    expect(input.controller?.text, '212');
    expect(find.text('温度'), findsOneWidget);
    expect(find.text('华氏度 (°F)'), findsOneWidget);
    expect(find.text('摄氏度 (°C)'), findsOneWidget);
    expect(find.text('100 °C'), findsOneWidget);

    await Hive.close();
    await directory.delete(recursive: true);
  });
}
