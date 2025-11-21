import 'package:hive/hive.dart';
import 'fare_result.dart';

part 'saved_route.g.dart';

@HiveType(typeId: 1)
class SavedRoute extends HiveObject {
  @HiveField(0)
  final String origin;

  @HiveField(1)
  final String destination;

  @HiveField(2)
  final List<FareResult> fareResults;

  @HiveField(3)
  final DateTime timestamp;

  SavedRoute({
    required this.origin,
    required this.destination,
    required this.fareResults,
    required this.timestamp,
  });
}