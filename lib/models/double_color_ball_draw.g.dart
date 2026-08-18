// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'double_color_ball_draw.dart';

class DoubleColorBallDrawAdapter extends TypeAdapter<DoubleColorBallDraw> {
  @override
  final int typeId = 5;

  @override
  DoubleColorBallDraw read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var index = 0; index < fieldCount; index++)
        reader.readByte(): reader.read(),
    };
    return DoubleColorBallDraw(
      issue: fields[0] as String,
      publishDate: fields[1] as DateTime,
      redNumbers: (fields[2] as List).cast<String>(),
      blueNumber: fields[3] as String,
      announcementUrl: fields[4] as String,
      drawOrderNumbers: (fields[5] as List? ?? const []).cast<String>(),
      prizeTiers: (fields[6] as List? ?? const [])
          .cast<DoubleColorBallPrizeTier>(),
      winnerSummary: fields[7] as String?,
      salesAmount: fields[8] as String?,
      poolAmount: fields[9] as String?,
      syncedAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, DoubleColorBallDraw obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.issue)
      ..writeByte(1)
      ..write(obj.publishDate)
      ..writeByte(2)
      ..write(obj.redNumbers)
      ..writeByte(3)
      ..write(obj.blueNumber)
      ..writeByte(4)
      ..write(obj.announcementUrl)
      ..writeByte(5)
      ..write(obj.drawOrderNumbers)
      ..writeByte(6)
      ..write(obj.prizeTiers)
      ..writeByte(7)
      ..write(obj.winnerSummary)
      ..writeByte(8)
      ..write(obj.salesAmount)
      ..writeByte(9)
      ..write(obj.poolAmount)
      ..writeByte(10)
      ..write(obj.syncedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoubleColorBallDrawAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DoubleColorBallPrizeTierAdapter
    extends TypeAdapter<DoubleColorBallPrizeTier> {
  @override
  final int typeId = 6;

  @override
  DoubleColorBallPrizeTier read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var index = 0; index < fieldCount; index++)
        reader.readByte(): reader.read(),
    };
    return DoubleColorBallPrizeTier(
      level: fields[0] as String,
      betCount: fields[1] as String,
      singlePrize: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DoubleColorBallPrizeTier obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.level)
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
      other is DoubleColorBallPrizeTierAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
