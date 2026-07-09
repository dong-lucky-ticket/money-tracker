import 'package:flutter/material.dart';

import '../../models/report_time_range.dart';

class ReportRangePickerSheet extends StatelessWidget {
  final ReportTimeRangePreset selectedPreset;

  const ReportRangePickerSheet({
    super.key,
    required this.selectedPreset,
  });

  static Future<ReportTimeRangePreset?> show(
    BuildContext context, {
    required ReportTimeRangePreset selectedPreset,
  }) {
    return showModalBottomSheet<ReportTimeRangePreset>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return ReportRangePickerSheet(selectedPreset: selectedPreset);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.72;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const Text(
                '选择统计范围',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '先切范围，再结合日期锚点查看不同周期',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: ReportTimeRange.quickPresets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final preset = ReportTimeRange.quickPresets[index];
                    return _ReportRangeOptionTile(
                      preset: preset,
                      isSelected: preset == selectedPreset,
                      onTap: () => Navigator.pop(context, preset),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportRangeOptionTile extends StatelessWidget {
  final ReportTimeRangePreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReportRangeOptionTile({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = _labelFor(preset);
    final description = _descriptionFor(preset);
    final accentColor =
        isSelected ? const Color(0xFF4A90E2) : const Color(0xFFD1D5DB);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8FBFF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isSelected ? const Color(0xFFBFDBFE) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 3,
              height: 34,
              margin: const EdgeInsets.only(top: 1, right: 12),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              isSelected ? Icons.check_rounded : Icons.add_rounded,
              size: 18,
              color: isSelected
                  ? const Color(0xFF4A90E2)
                  : const Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  String _labelFor(ReportTimeRangePreset preset) {
    switch (preset) {
      case ReportTimeRangePreset.last7Days:
        return '近7天';
      case ReportTimeRangePreset.last30Days:
        return '近30天';
      case ReportTimeRangePreset.thisMonth:
        return '本月';
      case ReportTimeRangePreset.last6Months:
        return '近半年';
      case ReportTimeRangePreset.thisYear:
        return '本年';
      case ReportTimeRangePreset.custom:
        return '自定义区间';
    }
  }

  String _descriptionFor(ReportTimeRangePreset preset) {
    switch (preset) {
      case ReportTimeRangePreset.last7Days:
        return '适合看最近一周的波动和短期变化';
      case ReportTimeRangePreset.last30Days:
        return '适合看最近一个月的连续趋势';
      case ReportTimeRangePreset.thisMonth:
        return '按当前锚点所在月份统计';
      case ReportTimeRangePreset.last6Months:
        return '适合观察半年内的大类走势和阶段性消费';
      case ReportTimeRangePreset.thisYear:
        return '按当前锚点所在年份统计';
      case ReportTimeRangePreset.custom:
        return '手动指定开始和结束日期';
    }
  }
}
