import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 0)
class Category extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String iconName;

  @HiveField(3)
  String colorHex;

  @HiveField(4)
  bool isExpense;

  @HiveField(5)
  int sortOrder;

  Category({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorHex,
    required this.isExpense,
    this.sortOrder = 0,
  });
}
