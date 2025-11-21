import 'package:hive/hive.dart';

part 'fare_result.g.dart';

@HiveType(typeId: 3)
enum IndicatorLevel {
  @HiveField(0)
  standard,
  @HiveField(1)
  peak,
  @HiveField(2)
  touristTrap,
}

@HiveType(typeId: 2)
class FareResult {
  @HiveField(0)
  final String transportMode;
  @HiveField(1)
  final double fare;
  @HiveField(2)
  final IndicatorLevel indicatorLevel;

  FareResult({
    required this.transportMode,
    required this.fare,
    required this.indicatorLevel,
  });
}