import 'package:expensetracker/models/category.dart';
import 'package:expensetracker/utils/category_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps orphan phone bill snapshots to the active category', () {
    final activeCategory = Category(
      id: 'active-phone-bill',
      name: '话费',
      iconName: 'phone-bill',
      colorHex: '#3B82F6',
      isExpense: true,
      groupId: 'expense_home',
    );
    final orphanCategory = Category(
      id: 'old-phone-bill',
      name: '话费',
      iconName: 'phone-bill',
      colorHex: '#3B82F6',
      isExpense: true,
      groupId: 'expense_home',
    );

    final resolved = resolveLegacyRecordCategory(
      category: orphanCategory,
      categories: [activeCategory],
    );

    expect(resolved, same(activeCategory));
  });
}
