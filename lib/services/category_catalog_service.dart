import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart';
import '../models/category_group.dart';
import '../utils/category_rules.dart';

class CategoryCatalogService {
  static const _deprecatedDefaultCategoryKeys = {
    'expense::娱乐::entertainment',
    'expense::社交::social',
    'expense::学习::study',
    'expense::礼物::gift',
    'expense::维修::repair',
    'expense::亲友::relatives',
    'expense::快递::express',
    'expense::话费::phone-bill',
    'expense::生活缴费::utility',
  };

  const CategoryCatalogService._();

  static Future<void> syncDefaultCategoryGroups(
    Box<CategoryGroup> categoryGroupsBox,
  ) async {
    final defaultGroups = buildDefaultCategoryGroups();

    for (final group in defaultGroups) {
      final existing = categoryGroupsBox.get(group.id);
      if (existing == null) {
        await categoryGroupsBox.put(group.id, group);
        continue;
      }

      var changed = false;
      if (existing.name != group.name) {
        existing.name = group.name;
        changed = true;
      }
      if (existing.isExpense != group.isExpense) {
        existing.isExpense = group.isExpense;
        changed = true;
      }
      if (existing.sortOrder != group.sortOrder) {
        existing.sortOrder = group.sortOrder;
        changed = true;
      }

      if (changed) {
        await categoryGroupsBox.put(existing.id, existing);
      }
    }
  }

  static Future<void> syncDefaultCategories(
    Box<Category> categoriesBox,
  ) async {
    final defaultCategories = _buildDefaultCategories();

    if (categoriesBox.isEmpty) {
      for (final category in defaultCategories) {
        await categoriesBox.put(category.id, category);
      }
    } else {
      await _syncLegacyDefaultCategories(categoriesBox);
      await _removeDeprecatedDefaultCategories(categoriesBox);
      await _addMissingDefaultCategories(categoriesBox, defaultCategories);
    }

    await _backfillCategoryGroupIds(categoriesBox);
  }

  static List<Category> _buildDefaultCategories() {
    final categories = [
      Category(id: const Uuid().v4(), name: '餐饮', iconName: 'food', colorHex: '#F97316', isExpense: true, sortOrder: 0),
      Category(id: const Uuid().v4(), name: '买菜', iconName: 'grocery', colorHex: '#10B981', isExpense: true, sortOrder: 1),
      Category(id: const Uuid().v4(), name: '水果', iconName: 'fruit', colorHex: '#F59E0B', isExpense: true, sortOrder: 2),
      Category(id: const Uuid().v4(), name: '零食', iconName: 'snacks', colorHex: '#EC4899', isExpense: true, sortOrder: 3),
      Category(id: const Uuid().v4(), name: '话费', iconName: 'phone-bill', colorHex: '#3B82F6', isExpense: true, sortOrder: 4),
      Category(id: const Uuid().v4(), name: '住房', iconName: 'housing', colorHex: '#F59E0B', isExpense: true, sortOrder: 5),
      Category(id: const Uuid().v4(), name: '办公', iconName: 'office', colorHex: '#64748B', isExpense: true, sortOrder: 6),
      Category(id: const Uuid().v4(), name: '水费', iconName: 'water-outline', colorHex: '#3B82F6', isExpense: true, sortOrder: 7),
      Category(id: const Uuid().v4(), name: '电费', iconName: 'lightning-bolt-outline', colorHex: '#F59E0B', isExpense: true, sortOrder: 8),
      Category(id: const Uuid().v4(), name: '燃气费', iconName: 'fire', colorHex: '#EF4444', isExpense: true, sortOrder: 9),
      Category(id: const Uuid().v4(), name: '交通', iconName: 'transport', colorHex: '#14B8A6', isExpense: true, sortOrder: 10),
      Category(id: const Uuid().v4(), name: '旅行', iconName: 'travel', colorHex: '#10B981', isExpense: true, sortOrder: 11),
      Category(id: const Uuid().v4(), name: '汽车', iconName: 'car', colorHex: '#3B82F6', isExpense: true, sortOrder: 12),
      Category(id: const Uuid().v4(), name: '摩托', iconName: 'motorcycle', colorHex: '#0EA5E9', isExpense: true, sortOrder: 13),
      Category(id: const Uuid().v4(), name: '铁路', iconName: 'train', colorHex: '#3B82F6', isExpense: true, sortOrder: 14),
      Category(id: const Uuid().v4(), name: '购物', iconName: 'shopping', colorHex: '#EF4444', isExpense: true, sortOrder: 15),
      Category(id: const Uuid().v4(), name: '日用', iconName: 'daily', colorHex: '#3B82F6', isExpense: true, sortOrder: 16),
      Category(id: const Uuid().v4(), name: '服饰', iconName: 'clothing', colorHex: '#EC4899', isExpense: true, sortOrder: 17),
      Category(id: const Uuid().v4(), name: '数码', iconName: 'digital', colorHex: '#6366F1', isExpense: true, sortOrder: 18),
      Category(id: const Uuid().v4(), name: '门票', iconName: 'ticketing', colorHex: '#0EA5E9', isExpense: true, sortOrder: 19),
      Category(id: const Uuid().v4(), name: '孩子', iconName: 'child', colorHex: '#14B8A6', isExpense: true, sortOrder: 20),
      Category(id: const Uuid().v4(), name: '长辈', iconName: 'elders', colorHex: '#EF4444', isExpense: true, sortOrder: 21),
      Category(id: const Uuid().v4(), name: '礼金', iconName: 'gift-money', colorHex: '#EF4444', isExpense: true, sortOrder: 22),
      Category(id: const Uuid().v4(), name: '医疗', iconName: 'medical', colorHex: '#EF4444', isExpense: true, sortOrder: 23),
      Category(id: const Uuid().v4(), name: '书籍', iconName: 'books', colorHex: '#8B5CF6', isExpense: true, sortOrder: 24),
      Category(id: const Uuid().v4(), name: '考试', iconName: 'study', colorHex: '#2563EB', isExpense: true, sortOrder: 25),
      Category(id: const Uuid().v4(), name: '烟酒', iconName: 'alcohol', colorHex: '#EF4444', isExpense: true, sortOrder: 26),
      Category(id: const Uuid().v4(), name: '彩票', iconName: 'lottery', colorHex: '#EF4444', isExpense: true, sortOrder: 27),
      Category(id: const Uuid().v4(), name: '星愿', iconName: 'wish', colorHex: '#A855F7', isExpense: true, sortOrder: 28),
      Category(id: const Uuid().v4(), name: '工资', iconName: 'salary', colorHex: '#10B981', isExpense: false, sortOrder: 0),
      Category(id: const Uuid().v4(), name: '兼职', iconName: 'part-time', colorHex: '#F59E0B', isExpense: false, sortOrder: 1),
      Category(id: const Uuid().v4(), name: '理财', iconName: 'investment', colorHex: '#3B82F6', isExpense: false, sortOrder: 2),
      Category(id: const Uuid().v4(), name: '礼金', iconName: 'gift-money-income', colorHex: '#EF4444', isExpense: false, sortOrder: 3),
      Category(id: const Uuid().v4(), name: '其它', iconName: 'other', colorHex: '#8B5CF6', isExpense: false, sortOrder: 4),
      Category(id: const Uuid().v4(), name: '彩票', iconName: 'lottery-income', colorHex: '#EF4444', isExpense: false, sortOrder: 5),
    ];

    for (final category in categories) {
      ensureCategoryGroupId(category);
    }

    return categories;
  }

  static Future<void> _removeDeprecatedDefaultCategories(
    Box<Category> categoriesBox,
  ) async {
    final categoriesToDelete = categoriesBox.values.where((category) {
      return _deprecatedDefaultCategoryKeys.contains(
        _defaultCategoryKey(
          name: category.name,
          iconName: category.iconName,
          isExpense: category.isExpense,
        ),
      );
    }).toList();

    for (final category in categoriesToDelete) {
      await categoriesBox.delete(category.id);
    }
  }

  static Future<void> _syncLegacyDefaultCategories(
    Box<Category> categoriesBox,
  ) async {
    for (final category in categoriesBox.values) {
      var changed = false;

      if (isLegacyCommunicationCategory(category)) {
        category.name = '话费';
        category.iconName = 'phone-bill';
        changed = true;
      }

      if (isLegacyRailCategory(category)) {
        category.name = '铁路';
        category.iconName = 'train';
        changed = true;
      }

      if (isLegacyGroceryCategory(category)) {
        category.name = '买菜';
        category.iconName = 'grocery';
        changed = true;
      }

      if (isDefaultDailyCategory(category) &&
          category.groupId != CategoryGroupIds.expenseShopping) {
        category.groupId = CategoryGroupIds.expenseShopping;
        changed = true;
      }

      if (isDefaultTicketingCategory(category) &&
          category.groupId != CategoryGroupIds.expenseShopping) {
        category.groupId = CategoryGroupIds.expenseShopping;
        changed = true;
      }

      if (!changed) {
        continue;
      }

      ensureCategoryGroupId(category);
      await categoriesBox.put(category.id, category);
    }
  }

  static Future<void> _addMissingDefaultCategories(
    Box<Category> categoriesBox,
    List<Category> defaultCategories,
  ) async {
    final existingKeys = {
      for (final category in categoriesBox.values)
        _defaultCategoryKey(
          name: category.name,
          iconName: category.iconName,
          isExpense: category.isExpense,
        ),
    };

    for (final category in defaultCategories) {
      final key = _defaultCategoryKey(
        name: category.name,
        iconName: category.iconName,
        isExpense: category.isExpense,
      );
      if (!existingKeys.contains(key)) {
        await categoriesBox.put(category.id, category);
      }
    }
  }

  static Future<void> _backfillCategoryGroupIds(
    Box<Category> categoriesBox,
  ) async {
    for (final category in categoriesBox.values) {
      if (category.groupId.isNotEmpty) {
        continue;
      }

      ensureCategoryGroupId(category);
      await categoriesBox.put(category.id, category);
    }
  }

  static String _defaultCategoryKey({
    required String name,
    required String iconName,
    required bool isExpense,
  }) {
    return '${isExpense ? 'expense' : 'income'}::${name.trim()}::${iconName.trim()}';
  }
}
