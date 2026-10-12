// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seven_star_draw.dart';

class SevenStarDrawAdapter extends TypeAdapter<SevenStarDraw> {
  @override
  final int typeId = 7;

  @override
  SevenStarDraw read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var index = 0; index < fieldCount; index++)
        reader.readByte(): reader.read(),
    };
    return SevenStarDraw(
      issue: fields[0] as String,
      publishDate: fields[1] as DateTime,
      numbers: (fields[2] as List).cast<String>(),
      announcementUrl: fields[3] as String,
      prizeTiers: (fields[4] as List? ?? const []).cast<SevenStarPrizeTier>(),
      salesAmount: fields[5] as String?,
      poolAmount: fields[6] as String?,
      syncedAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SevenStarDraw obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.issue)
      ..writeByte(1)
      ..write(obj.publishDate)
      ..writeByte(2)
      ..write(obj.numbers)
      ..writeByte(3)
      ..write(obj.announcementUrl)
      ..writeByte(4)
      ..write(obj.prizeTiers)
      ..writeByte(5)
      ..write(obj.salesAmount)
      ..writeByte(6)
      ..write(obj.poolAmount)
      ..writeByte(7)
      ..write(obj.syncedAt);
  }
}

class SevenStarPrizeTierAdapter extends TypeAdapter<SevenStarPrizeTier> {
  @override
  final int typeId = 8;

  @override
  SevenStarPrizeTier read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var index = 0; index < fieldCount; index++)
        reader.readByte(): reader.read(),
    };
    return SevenStarPrizeTier(
      level: fields[0] as String,
      betCount: fields[1] as String,
      singlePrize: fields[2] as String,
      totalPrize: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SevenStarPrizeTier obj) {
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
}
