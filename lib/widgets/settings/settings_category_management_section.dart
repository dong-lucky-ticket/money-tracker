import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/settings_category_management_controller.dart';
import '../../providers/data_provider.dart';
import '../common/segmented_selector.dart';
import 'settings_category_groups_panel.dart';
import 'settings_section.dart';

class SettingsCategoryManagementSection extends StatefulWidget {
  const SettingsCategoryManagementSection({super.key});

  @override
  State<SettingsCategoryManagementSection> createState() =>
      _SettingsCategoryManagementSectionState();
}

class _SettingsCategoryManagementSectionState
    extends State<SettingsCategoryManagementSection> {
  final SettingsCategoryManagementController _controller =
      const SettingsCategoryManagementController();
  bool _isExpense = true;

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: SegmentedSelector<bool>(
            value: _isExpense,
            onChanged: (value) => setState(() => _isExpense = value),
            padding: const EdgeInsets.all(3),
            itemPadding: const EdgeInsets.symmetric(vertical: 8),
            options: const [
              SegmentedOption(value: true, label: '支出分类'),
              SegmentedOption(value: false, label: '收入分类'),
            ],
          ),
        ),
        Consumer<DataProvider>(
          builder: (context, provider, child) {
            return SettingsCategoryGroupsPanel(
              isExpense: _isExpense,
              provider: provider,
              onDeleteCategory: (category) {
                _controller.confirmDelete(
                  context,
                  category: category,
                  provider: provider,
                );
              },
              onManageGroups: () {
                _controller.showGroupManagementSheet(
                  context,
                  provider,
                  isExpense: _isExpense,
                );
              },
              onAddCategory: () {
                _controller.showAddCategoryDialog(
                  context,
                  isExpense: _isExpense,
                );
              },
            );
          },
        ),
      ],
    );
  }
}
