import 'dart:math';
import 'package:injectable/injectable.dart';

import 'routing_service.dart';

@LazySingleton(as: RoutingService)
class HaversineRoutingService implements RoutingService {
  static const double _earthRadius = 6371000; // Radius in meters

  /// Calculates the straight-line distance (Haversine formula) in meters.
  @override
  Future<double> getDistance(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async {
    final dLat = _toRadians(destLat - originLat);
    final dLng = _toRadians(destLng - originLng);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(originLat)) *
            cos(_toRadians(destLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return _earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }
}