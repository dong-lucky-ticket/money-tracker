import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../models/record.dart';
import '../providers/data_provider.dart';
import '../theme/app_colors.dart';
import '../utils/record_queries.dart';
import '../utils/record_timeline.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/edit_record_sheet.dart';
import '../widgets/record/record_list_item.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '搜索分类或备注',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
          ),
          style: const TextStyle(fontSize: 16, color: Color(0xFF111827)),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.trim();
            });
          },
        ),
      ),
      body: Consumer<DataProvider>(
        builder: (context, provider, child) {
          if (_searchQuery.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icon(
                  MdiIcons.textSearch,
                  size: 64,
                  color: AppColors.border,
                ),
                title: '输入分类或备注进行搜索',
              ),
            );
          }

          final filteredRecords = searchRecords(provider.records, _searchQuery);
          final sections = buildRecordTimelineSections(filteredRecords);

          if (filteredRecords.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icon(
                  MdiIcons.textSearch,
                  size: 64,
                  color: AppColors.border,
                ),
                title: '没有找到相关账单',
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            physics: const BouncingScrollPhysics(),
            children: sections
                .map((section) => _buildDailyRecordList(section, provider))
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildDailyRecordList(
    RecordTimelineSection section,
    DataProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  section.label(),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280)),
                ),
                Row(
                  children: [
                    if (section.income > 0)
                      Text('收入: ${section.income.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6B7280))),
                    if (section.income > 0 && section.expense > 0)
                      const SizedBox(width: 12),
                    if (section.expense > 0)
                      Text('支出: ${section.expense.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6B7280))),
                  ],
                ),
              ],
            ),
          ),
          ...section.records.map((r) => _buildRecordItem(r, provider)),
        ],
      ),
    );
  }

  Widget _buildRecordItem(Record record, DataProvider provider) {
    return RecordListItem(
      record: record,
      onConfirmDelete: () async {
        return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('纭鍒犻櫎'),
              content: const Text('浣犵‘瀹氳鍒犻櫎杩欐潯璐﹀崟鍚楋紵'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text(
                    '鍙栨秷',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text(
                    '鍒犻櫎',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDelete: () => provider.deleteRecord(record.id),
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => EditRecordSheet(record: record, provider: provider),
        );
      },
    );
  }
}
