import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../services/data_bootstrap_service.dart';
import '../theme/app_colors.dart';
import '../widgets/common/app_card.dart';

typedef UnitToBase = double Function(double value);
typedef UnitFromBase = double Function(double value);

class UnitDefinition {
  final String name;
  final String symbol;
  final UnitToBase toBase;
  final UnitFromBase fromBase;

  const UnitDefinition({
    required this.name,
    required this.symbol,
    required this.toBase,
    required this.fromBase,
  });

  double convertTo(UnitDefinition target, double value) {
    return target.fromBase(toBase(value));
  }
}

class UnitCategory {
  final String name;
  final IconData icon;
  final List<UnitDefinition> units;
  final List<String> references;

  const UnitCategory({
    required this.name,
    required this.icon,
    required this.units,
    required this.references,
  });
}

double _identity(double value) => value;

UnitDefinition _linearUnit(String name, String symbol, double factor) {
  return UnitDefinition(
    name: name,
    symbol: symbol,
    toBase: (value) => value * factor,
    fromBase: (value) => value / factor,
  );
}

final List<UnitCategory> unitCategories = [
  UnitCategory(
    name: '长度',
    icon: Icons.straighten_outlined,
    units: [
      _linearUnit('毫米', 'mm', 0.001),
      _linearUnit('厘米', 'cm', 0.01),
      _linearUnit('米', 'm', 1),
      _linearUnit('千米', 'km', 1000),
      _linearUnit('寸', '寸', 1 / 30),
      _linearUnit('尺', '尺', 1 / 3),
      _linearUnit('丈', '丈', 10 / 3),
      _linearUnit('里', '里', 500),
      _linearUnit('英寸', 'in', 0.0254),
      _linearUnit('英尺', 'ft', 0.3048),
      _linearUnit('码', 'yd', 0.9144),
      _linearUnit('英里', 'mi', 1609.344),
      _linearUnit('海里', 'nmi', 1852),
    ],
    references: ['1 海里 = 1852 米', '1 英里 = 1.609344 千米', '1 丈 = 10 尺 = 100 寸'],
  ),
  UnitCategory(
    name: '面积',
    icon: Icons.crop_square,
    units: [
      _linearUnit('平方毫米', 'mm²', 0.000001),
      _linearUnit('平方厘米', 'cm²', 0.0001),
      _linearUnit('平方米', 'm²', 1),
      _linearUnit('平方千米', 'km²', 1000000),
      _linearUnit('公顷', 'ha', 10000),
      _linearUnit('亩', '亩', 2000 / 3),
      _linearUnit('平方英尺', 'ft²', 0.09290304),
      _linearUnit('英亩', 'acre', 4046.8564224),
    ],
    references: ['1 公顷 = 15 亩', '1 亩约等于 666.67 平方米', '1 英亩 = 4046.8564224 平方米'],
  ),
  UnitCategory(
    name: '重量',
    icon: Icons.scale_outlined,
    units: [
      _linearUnit('毫克', 'mg', 0.001),
      _linearUnit('克', 'g', 1),
      _linearUnit('千克', 'kg', 1000),
      _linearUnit('吨', 't', 1000000),
      _linearUnit('两', '两', 50),
      _linearUnit('斤', '斤', 500),
      _linearUnit('盎司', 'oz', 28.349523125),
      _linearUnit('磅', 'lb', 453.59237),
    ],
    references: [
      '1 斤 = 10 两 = 500 克',
      '1 磅 = 453.59237 克',
      '1 常衡盎司约等于 28.35 克'
    ],
  ),
  UnitCategory(
    name: '体积',
    icon: Icons.local_drink_outlined,
    units: [
      _linearUnit('毫升', 'mL', 0.001),
      _linearUnit('升', 'L', 1),
      _linearUnit('立方米', 'm³', 1000),
      _linearUnit('美制加仑', 'US gal', 3.785411784),
      _linearUnit('英制加仑', 'UK gal', 4.54609),
      _linearUnit('美制品脱', 'US pt', 0.473176473),
      _linearUnit('美制夸脱', 'US qt', 0.946352946),
      _linearUnit('美制液量盎司', 'US fl oz', 0.0295735295625),
    ],
    references: ['1 立方米 = 1000 升', '美制加仑与英制加仑定义不同', '1 美制加仑约等于 3.785 升'],
  ),
  UnitCategory(
    name: '温度',
    icon: Icons.thermostat_outlined,
    units: [
      const UnitDefinition(
        name: '摄氏度',
        symbol: '°C',
        toBase: _identity,
        fromBase: _identity,
      ),
      UnitDefinition(
        name: '华氏度',
        symbol: '°F',
        toBase: (value) => (value - 32) * 5 / 9,
        fromBase: (value) => value * 9 / 5 + 32,
      ),
      UnitDefinition(
        name: '开尔文',
        symbol: 'K',
        toBase: (value) => value - 273.15,
        fromBase: (value) => value + 273.15,
      ),
    ],
    references: ['0 °C = 32 °F', '0 °C = 273.15 K', '温度换算不是简单的比例换算'],
  ),
  UnitCategory(
    name: '速度',
    icon: Icons.speed_outlined,
    units: [
      _linearUnit('米/秒', 'm/s', 1),
      _linearUnit('千米/小时', 'km/h', 1 / 3.6),
      _linearUnit('英里/小时', 'mph', 0.44704),
      _linearUnit('节', 'kn', 0.5144444444),
    ],
    references: [
      '1 节 = 1 海里/小时',
      '1 米/秒 = 3.6 千米/小时',
      '1 英里/小时约等于 1.609 千米/小时'
    ],
  ),
  UnitCategory(
    name: '时间',
    icon: Icons.schedule_outlined,
    units: [
      _linearUnit('毫秒', 'ms', 0.001),
      _linearUnit('秒', 's', 1),
      _linearUnit('分钟', 'min', 60),
      _linearUnit('小时', 'h', 3600),
      _linearUnit('天', 'd', 86400),
      _linearUnit('周', 'week', 604800),
    ],
    references: ['1 天 = 24 小时', '1 周 = 7 天', '月份和年份长度不固定，因此不纳入固定换算'],
  ),
  UnitCategory(
    name: '数据',
    icon: Icons.storage_outlined,
    units: [
      _linearUnit('比特', 'bit', 0.125),
      _linearUnit('字节', 'B', 1),
      _linearUnit('千字节', 'KB', 1000),
      _linearUnit('兆字节', 'MB', 1000000),
      _linearUnit('吉字节', 'GB', 1000000000),
      _linearUnit('太字节', 'TB', 1000000000000),
      _linearUnit('千字节（二进制）', 'KiB', 1024),
      _linearUnit('兆字节（二进制）', 'MiB', 1048576),
      _linearUnit('吉字节（二进制）', 'GiB', 1073741824),
    ],
    references: [
      '1 字节 = 8 比特',
      'KB 采用 1000 字节，KiB 采用 1024 字节',
      '存储设备常用十进制，系统内存常见二进制'
    ],
  ),
];

class UnitConverterScreen extends StatefulWidget {
  const UnitConverterScreen({super.key});

  @override
  State<UnitConverterScreen> createState() => _UnitConverterScreenState();
}

class _UnitConverterScreenState extends State<UnitConverterScreen> {
  static const _categoryKey = 'unitConverter.categoryIndex';
  static const _fromKey = 'unitConverter.fromIndex';
  static const _toKey = 'unitConverter.toIndex';
  static const _inputKey = 'unitConverter.input';

  late final TextEditingController _inputController;
  int _categoryIndex = 0;
  int _fromIndex = 2;
  int _toIndex = 3;
  bool _isRestoring = true;

  UnitCategory get _category => unitCategories[_categoryIndex];
  UnitDefinition get _fromUnit => _category.units[_fromIndex];
  UnitDefinition get _toUnit => _category.units[_toIndex];

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController(text: '1')
      ..addListener(_onInputChanged);
    _restorePreferences();
  }

  @override
  void dispose() {
    _inputController
      ..removeListener(_onInputChanged)
      ..dispose();
    super.dispose();
  }

  void _onInputChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
    if (!_isRestoring) {
      _savePreferences();
    }
  }

  void _selectCategory(int index) {
    setState(() {
      _categoryIndex = index;
      _fromIndex = _category.units.length > 2 ? 2 : 0;
      _toIndex =
          _category.units.length > 3 ? 3 : (_category.units.length > 1 ? 1 : 0);
    });
    _savePreferences();
  }

  void _swapUnits() {
    setState(() {
      final oldFrom = _fromIndex;
      _fromIndex = _toIndex;
      _toIndex = oldFrom;
    });
    _savePreferences();
  }

  Future<Box> _settingsBox() async {
    if (Hive.isBoxOpen(DataBootstrapService.settingsBoxName)) {
      return Hive.box(DataBootstrapService.settingsBoxName);
    }
    return Hive.openBox(DataBootstrapService.settingsBoxName);
  }

  Future<void> _restorePreferences() async {
    try {
      final box = await _settingsBox();
      final categoryIndex = box.get(_categoryKey);
      final savedCategoryIndex = categoryIndex is int ? categoryIndex : 0;
      final safeCategoryIndex =
          savedCategoryIndex >= 0 && savedCategoryIndex < unitCategories.length
              ? savedCategoryIndex
              : 0;
      final category = unitCategories[safeCategoryIndex];
      final savedFromIndex = box.get(_fromKey);
      final savedToIndex = box.get(_toKey);
      final fromIndex = savedFromIndex is int ? savedFromIndex : 2;
      final toIndex = savedToIndex is int ? savedToIndex : 3;
      final safeFromIndex = fromIndex >= 0 && fromIndex < category.units.length
          ? fromIndex
          : (category.units.length > 2 ? 2 : 0);
      final safeToIndex = toIndex >= 0 && toIndex < category.units.length
          ? toIndex
          : (category.units.length > 3
              ? 3
              : (category.units.length > 1 ? 1 : 0));
      final savedInput = box.get(_inputKey);
      final input =
          savedInput is String && savedInput.isNotEmpty ? savedInput : '1';

      if (!mounted) {
        return;
      }
      _inputController.value = TextEditingValue(
        text: input,
        selection: TextSelection.collapsed(offset: input.length),
      );
      setState(() {
        _categoryIndex = safeCategoryIndex;
        _fromIndex = safeFromIndex;
        _toIndex = safeToIndex;
        _isRestoring = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }

  Future<void> _savePreferences() async {
    if (_isRestoring) {
      return;
    }
    try {
      final box = await _settingsBox();
      await box.putAll({
        _categoryKey: _categoryIndex,
        _fromKey: _fromIndex,
        _toKey: _toIndex,
        _inputKey: _inputController.text,
      });
    } catch (_) {
      // Preference caching is best effort and must not block conversion.
    }
  }

  double? get _convertedValue {
    final value = double.tryParse(_inputController.text.trim());
    if (value == null || !value.isFinite) {
      return null;
    }
    return _fromUnit.convertTo(_toUnit, value);
  }

  String _formatValue(double? value) {
    if (value == null || !value.isFinite) {
      return '--';
    }
    if (value.abs() >= 1000000000 || (value != 0 && value.abs() < 0.000001)) {
      return value.toStringAsExponential(6);
    }
    final text = value.toStringAsFixed(8);
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('单位换算'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          _buildCategorySelector(),
          const SizedBox(height: 16),
          _buildConverterCard(),
          const SizedBox(height: 16),
          _buildReferenceCard(),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: unitCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = unitCategories[index];
          final selected = index == _categoryIndex;
          return ChoiceChip(
            selected: selected,
            avatar: Icon(category.icon,
                size: 17,
                color: selected ? Colors.white : AppColors.textTertiary),
            label: Text(category.name),
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            selectedColor: AppColors.primary,
            backgroundColor: Colors.white,
            side: BorderSide(
                color: selected ? AppColors.primary : AppColors.border),
            onSelected: (_) => _selectCategory(index),
          );
        },
      ),
    );
  }

  Widget _buildConverterCard() {
    return AppCard(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('输入数值',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _inputController,
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true, signed: true),
            decoration: InputDecoration(
              suffixText: _fromUnit.symbol,
              hintText: '请输入数值',
              filled: true,
              fillColor: AppColors.surfaceMuted,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                  child: _buildUnitDropdown('从', _fromIndex, (value) {
                if (value == null) {
                  return;
                }
                setState(() => _fromIndex = value);
                _savePreferences();
              })),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: IconButton(
                  onPressed: _swapUnits,
                  tooltip: '交换单位',
                  icon: const Icon(Icons.swap_horiz),
                  color: AppColors.primary,
                ),
              ),
              Expanded(
                  child: _buildUnitDropdown('到', _toIndex, (value) {
                if (value == null) {
                  return;
                }
                setState(() => _toIndex = value);
                _savePreferences();
              })),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('换算结果',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                const SizedBox(height: 6),
                Text(
                  '${_formatValue(_convertedValue)} ${_toUnit.symbol}',
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitDropdown(
      String label, int value, ValueChanged<int?> onChanged) {
    return DropdownButtonFormField<int>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surfaceMuted,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
      items: [
        for (var index = 0; index < _category.units.length; index++)
          DropdownMenuItem(
            value: index,
            child: Text(
                '${_category.units[index].name} (${_category.units[index].symbol})',
                overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildReferenceCard() {
    return AppCard(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_category.icon, size: 18, color: AppColors.textTertiary),
              const SizedBox(width: 8),
              const Text('常用换算',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 8),
          ..._category.references.map(
            (reference) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold)),
                  Expanded(
                      child: Text(reference,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.35))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
