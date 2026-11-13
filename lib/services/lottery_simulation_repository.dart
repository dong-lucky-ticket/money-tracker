import 'package:hive/hive.dart';

import '../models/lottery_simulation.dart';

class LotterySimulationRepository {
  static const boxName = 'lotterySimulationRecords';
  static const draftBoxName = 'lotterySimulationDrafts';

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

  Future<List<SimulationTicket>> loadDraftTickets(
      SimulationLottery lottery) async {
    final box = await Hive.openBox(draftBoxName);
    final tickets =
        box.get(lottery.name, defaultValue: const <dynamic>[]) as List;
    return tickets
        .map((ticket) => SimulationTicket.fromMap(ticket as Map))
        .toList();
  }

  Future<void> saveDraftTickets(
      SimulationLottery lottery, List<SimulationTicket> tickets) async {
    if (tickets.any((ticket) => !ticket.isValid || ticket.lottery != lottery)) {
      throw ArgumentError('无效的模拟号码');
    }
    final box = await Hive.openBox(draftBoxName);
    await box.put(
        lottery.name, tickets.map((ticket) => ticket.toMap()).toList());
    await box.flush();
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
