import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'accuracy_level.g.dart';

/// Represents the accuracy level of fare/route information.
///
/// Follows the design in ADR-006.
@HiveType(typeId: 4)
enum AccuracyLevel {
  /// Precise calculation using online services (OSRM, live data).
  @HiveField(0)
  precise,

  /// Estimated calculation using cached data (valid, recent cache).
  @HiveField(1)
  estimated,

  /// Approximate calculation using offline fallbacks (Haversine, static matrices).
  @HiveField(2)
  approximate,
}

/// Extension methods for AccuracyLevel to provide UI helpers.
extension AccuracyLevelX on AccuracyLevel {
  /// Returns a human-readable label.
  String get label {
    switch (this) {
      case AccuracyLevel.precise:
        return 'Precise (Online)';
      case AccuracyLevel.estimated:
        return 'Estimated (Cached)';
      case AccuracyLevel.approximate:
        return 'Approximate (Offline)';
    }
  }

  /// Returns a description of the accuracy level.
  String get description {
    switch (this) {
      case AccuracyLevel.precise:
        return 'Based on real-time road data and current conditions';
      case AccuracyLevel.estimated:
        return 'Based on previously cached route data';
      case AccuracyLevel.approximate:
        return 'Based on straight-line distance calculations';
    }
  }

  /// Returns the appropriate color for UI display.
  Color get color {
    switch (this) {
      case AccuracyLevel.precise:
        return Colors.green;
      case AccuracyLevel.estimated:
        return Colors.yellow.shade700;
      case AccuracyLevel.approximate:
        return Colors.orange;
    }
  }

  /// Returns an icon for the accuracy level.
  IconData get icon {
    switch (this) {
      case AccuracyLevel.precise:
        return Icons.wifi_rounded;
      case AccuracyLevel.estimated:
        return Icons.cached_rounded;
      case AccuracyLevel.approximate:
        return Icons.offline_bolt_rounded;
    }
  }
}
