import 'package:hive/hive.dart';

import '../models/lottery_simulation.dart';

class LotterySimulationRepository {
  static const boxName = 'lotterySimulationRecords';

  Future<Box> _getBox() async {
    if (Hive.isBoxOpen(boxName)) return Hive.box(boxName);
    return Hive.openBox(boxName);
  }

  Future<List<SimulationRecord>> load() async {
    final box = await _getBox();
    return box.values
        .map((value) => SimulationRecord.fromMap(value as Map))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> save(SimulationRecord record) async {
    if (record.tickets.isEmpty ||
        record.multiple < 1 ||
        record.multiple > 99 ||
        record.tickets.any(
            (ticket) => !ticket.isValid || ticket.lottery != record.lottery)) {
      throw ArgumentError('无效的模拟投注');
    }
    final box = await _getBox();
    await box.put(record.id, record.toMap());
    await box.flush();
  }

  Future<void> delete(Iterable<String> ids) async {
    final box = await _getBox();
    await box.deleteAll(ids);
  }
}
