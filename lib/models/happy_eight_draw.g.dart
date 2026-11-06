// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'happy_eight_draw.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HappyEightDrawAdapter extends TypeAdapter<HappyEightDraw> {
  @override
  final int typeId = 9;

  @override
  HappyEightDraw read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HappyEightDraw(
      issue: fields[0] as String,
      publishDate: fields[1] as DateTime,
      numbers: (fields[2] as List).cast<String>(),
      announcementUrl: fields[4] as String,
      prizeTiers: (fields[5] as List?)?.cast<HappyEightPrizeTier>(),
      salesAmount: fields[6] as String?,
      poolAmount: fields[7] as String?,
      syncedAt: fields[8] as DateTime?,
      winnerContent: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HappyEightDraw obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.issue)
      ..writeByte(1)
      ..write(obj.publishDate)
      ..writeByte(2)
      ..write(obj.numbers)
      ..writeByte(4)
      ..write(obj.announcementUrl)
      ..writeByte(5)
      ..write(obj.prizeTiers)
      ..writeByte(6)
      ..write(obj.salesAmount)
      ..writeByte(7)
      ..write(obj.poolAmount)
      ..writeByte(8)
      ..write(obj.syncedAt)
      ..writeByte(9)
      ..write(obj.winnerContent);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HappyEightDrawAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HappyEightPrizeTierAdapter extends TypeAdapter<HappyEightPrizeTier> {
  @override
  final int typeId = 10;

  @override
  HappyEightPrizeTier read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HappyEightPrizeTier(
      play: fields[0] as String,
      betCount: fields[1] as String,
      singlePrize: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HappyEightPrizeTier obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.play)
      ..writeByte(1)
      ..write(obj.betCount)
      ..writeByte(2)
      ..write(obj.singlePrize);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HappyEightPrizeTierAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
