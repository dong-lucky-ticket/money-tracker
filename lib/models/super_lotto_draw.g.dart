// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'super_lotto_draw.dart';

class SuperLottoDrawAdapter extends TypeAdapter<SuperLottoDraw> {
  @override
  final int typeId = 3;

  @override
  SuperLottoDraw read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var index = 0; index < fieldCount; index++)
        reader.readByte(): reader.read(),
    };
    return SuperLottoDraw(
      issue: fields[0] as String,
      publishDate: fields[1] as DateTime,
      frontNumbers: (fields[2] as List).cast<String>(),
      backNumbers: (fields[3] as List).cast<String>(),
      announcementUrl: fields[4] as String,
      drawTime: fields[5] as String?,
      drawLocation: fields[6] as String?,
      drawOrderNumbers: (fields[7] as List? ?? const []).cast<String>(),
      prizeTiers: (fields[8] as List? ?? const []).cast<SuperLottoPrizeTier>(),
      winnerSummary: fields[9] as String?,
      syncedAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SuperLottoDraw obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.issue)
      ..writeByte(1)
      ..write(obj.publishDate)
      ..writeByte(2)
      ..write(obj.frontNumbers)
      ..writeByte(3)
      ..write(obj.backNumbers)
      ..writeByte(4)
      ..write(obj.announcementUrl)
      ..writeByte(5)
      ..write(obj.drawTime)
      ..writeByte(6)
      ..write(obj.drawLocation)
      ..writeByte(7)
      ..write(obj.drawOrderNumbers)
      ..writeByte(8)
      ..write(obj.prizeTiers)
      ..writeByte(9)
      ..write(obj.winnerSummary)
      ..writeByte(10)
      ..write(obj.syncedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuperLottoDrawAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SuperLottoPrizeTierAdapter extends TypeAdapter<SuperLottoPrizeTier> {
  @override
  final int typeId = 4;

  @override
  SuperLottoPrizeTier read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var index = 0; index < fieldCount; index++)
        reader.readByte(): reader.read(),
    };
    return SuperLottoPrizeTier(
      level: fields[0] as String,
      betCount: fields[1] as String,
      singlePrize: fields[2] as String,
      totalPrize: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SuperLottoPrizeTier obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.level)
      ..writeByte(1)
      ..write(obj.betCount)
      ..writeByte(2)
      ..write(obj.singlePrize)
      ..writeByte(3)
      ..write(obj.totalPrize);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuperLottoPrizeTierAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
