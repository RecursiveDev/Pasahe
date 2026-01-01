import 'package:hive/hive.dart';
import 'accuracy_level.dart';
import 'route_result.dart';

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
  @HiveField(3, defaultValue: false)
  final bool isRecommended;

  @HiveField(4, defaultValue: 1)
  final int passengerCount;

  @HiveField(5, defaultValue: 0.0)
  final double totalFare;

  /// Accuracy level of the calculation.
  @HiveField(6)
  final AccuracyLevel accuracy;

  /// Source of the route calculation.
  @HiveField(7)
  final RouteSource routeSource;

  FareResult({
    required this.transportMode,
    required this.fare,
    required this.indicatorLevel,
    this.isRecommended = false,
    this.passengerCount = 1,
    required this.totalFare,
    this.accuracy = AccuracyLevel.precise,
    this.routeSource = RouteSource.osrm,
  });
}

