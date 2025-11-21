import 'package:hive/hive.dart';

part 'fare_formula.g.dart';

@HiveType(typeId: 0)
class FareFormula {
  @HiveField(6)
  final String mode;

  @HiveField(0)
  final String subType;

  @HiveField(1)
  final double baseFare;

  @HiveField(2)
  final double perKmRate;

  @HiveField(3)
  final double? provincialMultiplier;

  @HiveField(4)
  final double? minimumFare;

  @HiveField(5)
  final String? notes;

  FareFormula({
    required this.mode,
    required this.subType,
    required this.baseFare,
    required this.perKmRate,
    this.provincialMultiplier,
    this.minimumFare,
    this.notes,
  });

  factory FareFormula.fromJson(Map<String, dynamic> json) {
    return FareFormula(
      mode: json['mode'] ?? 'Unknown',
      subType: json['sub_type'],
      baseFare: (json['base_fare'] as num).toDouble(),
      perKmRate: (json['per_km_rate'] as num).toDouble(),
      provincialMultiplier: json['provincial_multiplier'] != null
          ? (json['provincial_multiplier'] as num).toDouble()
          : null,
      minimumFare: json['minimum_fare'] != null
          ? (json['minimum_fare'] as num).toDouble()
          : null,
      notes: json['notes'],
    );
  }
}
