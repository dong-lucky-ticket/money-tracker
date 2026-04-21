import 'package:hive/hive.dart';
import 'category.dart';

part 'record.g.dart';

@HiveType(typeId: 1)
class Record extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  Category category;

  @HiveField(3)
  String remark;

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  bool isExpense;

  Record({
    required this.id,
    required this.amount,
    required this.category,
    required this.remark,
    required this.date,
    required this.isExpense,
  });
}
