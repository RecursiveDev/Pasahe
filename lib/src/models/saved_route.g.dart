// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_route.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavedRouteAdapter extends TypeAdapter<SavedRoute> {
  @override
  final int typeId = 1;

  @override
  SavedRoute read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedRoute(
      origin: fields[0] as String,
      destination: fields[1] as String,
      fareResults: (fields[2] as List).cast<FareResult>(),
      timestamp: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SavedRoute obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.origin)
      ..writeByte(1)
      ..write(obj.destination)
      ..writeByte(2)
      ..write(obj.fareResults)
      ..writeByte(3)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedRouteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
