import '../models/category.dart';
import '../models/category_group.dart';

void ensureCategoryGroupId(Category category) {
  if (category.groupId.isNotEmpty) {
    return;
  }

  category.groupId = resolveCategoryGroupId(category);
}

String resolveCategoryGroupId(Category category) {
  switch (_categoryTypeKey(category.iconName, category.isExpense)) {
    case 'expense::food':
    case 'expense::vegetables':
    case 'expense::grocery':
    case 'expense::fruit':
    case 'expense::snacks':
      return CategoryGroupIds.expenseFood;
    case 'expense::communication':
    case 'expense::housing':
    case 'expense::office':
    case 'expense::repair':
    case 'expense::express':
    case 'expense::phone-bill':
    case 'expense::utility':
    case 'expense::water-outline':
    case 'expense::lightning-bolt-outline':
    case 'expense::fire':
      return CategoryGroupIds.expenseHome;
    case 'expense::transport':
    case 'expense::car':
    case 'expense::motorcycle':
    case 'expense::train':
    case 'expense::travel':
      return CategoryGroupIds.expenseTransport;
    case 'expense::daily':
    case 'expense::shopping':
    case 'expense::clothing':
    case 'expense::digital':
      return CategoryGroupIds.expenseShopping;
    case 'expense::child':
    case 'expense::elders':
    case 'expense::gift-money':
    case 'expense::gift':
    case 'expense::relatives':
      return CategoryGroupIds.expenseFamily;
    case 'expense::medical':
    case 'expense::books':
    case 'expense::study':
      return CategoryGroupIds.expenseHealth;
    case 'expense::lottery':
    case 'expense::wish':
    case 'expense::alcohol':
    case 'expense::social':
    case 'expense::entertainment':
      return CategoryGroupIds.expenseEntertainment;
    case 'income::salary':
    case 'income::part-time':
      return CategoryGroupIds.incomeWork;
    case 'income::investment':
      return CategoryGroupIds.incomeInvestment;
    case 'income::gift-money-income':
      return CategoryGroupIds.incomeRelationship;
    case 'income::lottery-income':
    case 'income::other':
      return CategoryGroupIds.incomeWindfall;
    default:
      return category.isExpense
          ? CategoryGroupIds.expenseHome
          : CategoryGroupIds.incomeWindfall;
  }
}

Category? findCategoryByName(
  Iterable<Category> categories,
  String name, {
  required bool isExpense,
}) {
  for (final category in categories) {
    if (category.isExpense == isExpense && category.name == name) {
      return category;
    }
  }

  return null;
}

Category? resolveLegacyRecordCategory({
  required Category category,
  required Iterable<Category> categories,
}) {
  if (isLegacyCommunicationCategory(category)) {
    return findCategoryByName(categories, '话费', isExpense: true);
  }

  if (isLegacyRailCategory(category)) {
    return findCategoryByName(categories, '铁路', isExpense: true);
  }

  if (isLegacyGroceryCategory(category)) {
    return findCategoryByName(categories, '买菜', isExpense: true);
  }

  return null;
}

Category? resolveUtilityCategoryFromRemark({
  required Category category,
  required String remark,
  required Iterable<Category> categories,
}) {
  if (!isLegacyUtilityCategory(category)) {
    return null;
  }

  if (remark.contains('水费')) {
    return findCategoryByName(categories, '水费', isExpense: true);
  }

  if (remark.contains('电费')) {
    return findCategoryByName(categories, '电费', isExpense: true);
  }

  if (remark.contains('燃气费') || remark.contains('燃气')) {
    return findCategoryByName(categories, '燃气费', isExpense: true);
  }

  return null;
}

bool isLegacyUtilityCategory(Category category) {
  if (!category.isExpense) {
    return false;
  }

  return category.iconName == 'utility' || category.name == '生活缴费';
}

bool isLegacyCommunicationCategory(Category category) {
  if (!category.isExpense) {
    return false;
  }

  return category.iconName == 'communication' || category.name == '通讯';
}

bool isLegacyRailCategory(Category category) {
  if (!category.isExpense) {
    return false;
  }

  return category.iconName == 'train' && category.name == '火车高铁';
}

bool isLegacyGroceryCategory(Category category) {
  if (!category.isExpense) {
    return false;
  }

  return category.iconName == 'vegetables' || category.name == '蔬菜';
}

bool isDefaultDailyCategory(Category category) {
  if (!category.isExpense) {
    return false;
  }

  return category.iconName == 'daily' || category.name == '日用';
}

bool isSameCategorySnapshot(Category a, Category b) {
  return a.id == b.id &&
      a.name == b.name &&
      a.iconName == b.iconName &&
      a.colorHex == b.colorHex &&
      a.groupId == b.groupId &&
      a.isExpense == b.isExpense &&
      a.sortOrder == b.sortOrder;
}

String _categoryTypeKey(String iconName, bool isExpense) {
  return '${isExpense ? 'expense' : 'income'}::${iconName.trim()}';
}
