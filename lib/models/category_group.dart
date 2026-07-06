import 'package:hive/hive.dart';

part 'category_group.g.dart';

@HiveType(typeId: 2)
class CategoryGroup extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  bool isExpense;

  @HiveField(3)
  int sortOrder;

  CategoryGroup({
    required this.id,
    required this.name,
    required this.isExpense,
    this.sortOrder = 0,
  });
}

class CategoryGroupIds {
  static const expenseFood = 'expense_food';
  static const expenseHome = 'expense_home';
  static const expenseTransport = 'expense_transport';
  static const expenseShopping = 'expense_shopping';
  static const expenseFamily = 'expense_family';
  static const expenseHealth = 'expense_health';
  static const expenseEntertainment = 'expense_entertainment';

  static const incomeWork = 'income_work';
  static const incomeInvestment = 'income_investment';
  static const incomeRelationship = 'income_relationship';
  static const incomeWindfall = 'income_windfall';
}

List<CategoryGroup> buildDefaultCategoryGroups() {
  return [
    CategoryGroup(
      id: CategoryGroupIds.expenseFood,
      name: '饮食生鲜',
      isExpense: true,
      sortOrder: 0,
    ),
    CategoryGroup(
      id: CategoryGroupIds.expenseHome,
      name: '居家生活',
      isExpense: true,
      sortOrder: 1,
    ),
    CategoryGroup(
      id: CategoryGroupIds.expenseTransport,
      name: '交通出行',
      isExpense: true,
      sortOrder: 2,
    ),
    CategoryGroup(
      id: CategoryGroupIds.expenseShopping,
      name: '购物消费',
      isExpense: true,
      sortOrder: 3,
    ),
    CategoryGroup(
      id: CategoryGroupIds.expenseFamily,
      name: '家庭人情',
      isExpense: true,
      sortOrder: 4,
    ),
    CategoryGroup(
      id: CategoryGroupIds.expenseHealth,
      name: '健康成长',
      isExpense: true,
      sortOrder: 5,
    ),
    CategoryGroup(
      id: CategoryGroupIds.expenseEntertainment,
      name: '娱乐偏好',
      isExpense: true,
      sortOrder: 6,
    ),
    CategoryGroup(
      id: CategoryGroupIds.incomeWork,
      name: '工作收入',
      isExpense: false,
      sortOrder: 0,
    ),
    CategoryGroup(
      id: CategoryGroupIds.incomeInvestment,
      name: '投资收益',
      isExpense: false,
      sortOrder: 1,
    ),
    CategoryGroup(
      id: CategoryGroupIds.incomeRelationship,
      name: '人情往来',
      isExpense: false,
      sortOrder: 2,
    ),
    CategoryGroup(
      id: CategoryGroupIds.incomeWindfall,
      name: '偶发所得',
      isExpense: false,
      sortOrder: 3,
    ),
  ];
}
