import 'package:expensetracker/screens/unit_converter_screen.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
