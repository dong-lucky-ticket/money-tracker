import 'package:flutter/material.dart';

import '../../models/record.dart';
import '../../theme/app_colors.dart';
import '../../utils/color_utils.dart';
import '../../utils/icon_mapper.dart';

class RecordListItem extends StatelessWidget {
  final Record record;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleVoided;
  final Future<bool?> Function()? onConfirmDelete;
  final EdgeInsetsGeometry margin;

  const RecordListItem({
    super.key,
    required this.record,
    this.onTap,
    this.onDelete,
    this.onToggleVoided,
    this.onConfirmDelete,
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor =
        record.isVoided ? Colors.grey : colorFromHex(record.category.colorHex);
    final amountColor = record.isVoided
        ? Colors.grey
        : (record.isExpense ? AppColors.danger : AppColors.success);
    final canDelete = onDelete != null;
    final canToggleVoided = onToggleVoided != null;

    return Dismissible(
      key: Key(record.id),
      direction: canDelete && canToggleVoided
          ? DismissDirection.horizontal
          : canDelete
              ? DismissDirection.endToStart
              : canToggleVoided
                  ? DismissDirection.startToEnd
                  : DismissDirection.none,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart && canDelete) {
          return await (onConfirmDelete?.call() ?? Future.value(true));
        }
        if (direction == DismissDirection.startToEnd && canToggleVoided) {
          onToggleVoided?.call();
          return false;
        }
        return false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDelete?.call();
        }
      },
      background: canToggleVoided
          ? Container(
              margin: margin,
              decoration: BoxDecoration(
                color: record.isVoided ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              child: Icon(
                record.isVoided ? Icons.restore : Icons.block,
                color: Colors.white,
              ),
            )
          : canDelete
              ? Container(
                  margin: margin,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                )
              : null,
      secondaryBackground: canDelete
          ? Container(
              margin: margin,
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            )
          : null,
      child: GestureDetector(
        onTap: record.isVoided ? null : onTap,
        child: Container(
          margin: margin,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                record.isVoided ? Colors.white.withOpacity(0.75) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (!record.isVoided)
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  IconMapper.getIcon(record.category.iconName),
                  color: categoryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          record.category.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: record.isVoided
                                ? Colors.grey
                                : AppColors.textPrimary,
                            decoration: record.isVoided
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (record.isVoided) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '已废弃',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (record.remark.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        record.remark,
                        style: TextStyle(
                          fontSize: 12,
                          color: record.isVoided
                              ? Colors.grey.shade400
                              : AppColors.textMuted,
                          decoration: record.isVoided
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                '${record.isExpense ? '-' : '+'}${record.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                  decoration:
                      record.isVoided ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
