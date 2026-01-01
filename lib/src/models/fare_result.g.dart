// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fare_result.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FareResultAdapter extends TypeAdapter<FareResult> {
  @override
  final int typeId = 2;

  @override
  FareResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FareResult(
      transportMode: fields[0] as String,
      fare: fields[1] as double,
      indicatorLevel: fields[2] as IndicatorLevel,
      isRecommended: fields[3] == null ? false : fields[3] as bool,
      passengerCount: fields[4] == null ? 1 : fields[4] as int,
      totalFare: fields[5] == null ? 0.0 : fields[5] as double,
      accuracy: fields[6] as AccuracyLevel,
      routeSource: fields[7] as RouteSource,
    );
  }

  @override
  void write(BinaryWriter writer, FareResult obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.transportMode)
      ..writeByte(1)
      ..write(obj.fare)
      ..writeByte(2)
      ..write(obj.indicatorLevel)
      ..writeByte(3)
      ..write(obj.isRecommended)
      ..writeByte(4)
      ..write(obj.passengerCount)
      ..writeByte(5)
      ..write(obj.totalFare)
      ..writeByte(6)
      ..write(obj.accuracy)
      ..writeByte(7)
      ..write(obj.routeSource);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FareResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class IndicatorLevelAdapter extends TypeAdapter<IndicatorLevel> {
  @override
  final int typeId = 3;

  @override
  IndicatorLevel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return IndicatorLevel.standard;
      case 1:
        return IndicatorLevel.peak;
      case 2:
        return IndicatorLevel.touristTrap;
      default:
        return IndicatorLevel.standard;
    }
  }

  @override
  void write(BinaryWriter writer, IndicatorLevel obj) {
    switch (obj) {
      case IndicatorLevel.standard:
        writer.writeByte(0);
        break;
      case IndicatorLevel.peak:
        writer.writeByte(1);
        break;
      case IndicatorLevel.touristTrap:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IndicatorLevelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
