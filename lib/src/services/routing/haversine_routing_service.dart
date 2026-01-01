import 'dart:math';

import 'package:injectable/injectable.dart';
import 'package:latlong2/latlong.dart';

import '../../models/route_result.dart';
import 'routing_service.dart';

/// Routing service that uses the Haversine formula for straight-line distance.
///
/// This is a fallback service when OSRM is unavailable. It calculates the
/// great-circle distance between two points but cannot provide actual road
/// geometry.
///
/// The distance calculated is typically shorter than actual road distance,
/// so fare calculations based on this should be clearly marked as estimates.
@Named('haversine')
@LazySingleton(as: RoutingService)
class HaversineRoutingService implements RoutingService {
  /// Earth's radius in meters.
  static const double _earthRadius = 6371000;

  /// Calculates the straight-line distance (Haversine formula) in meters.
  ///
  /// Returns a RouteResult with:
  /// - Distance: Great-circle distance in meters
  /// - Geometry: A simple two-point line from origin to destination
  /// - Source: [RouteSource.haversine] to indicate this is an estimate
  ///
  /// The geometry is a straight line connecting origin and destination,
  /// which will be displayed on the map to indicate the fallback mode.
  @override
  Future<RouteResult> getRoute(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async {
    final distance = _calculateHaversineDistance(
      originLat,
      originLng,
      destLat,
      destLng,
    );

    // Create a simple straight-line geometry for visualization
    final origin = LatLng(originLat, originLng);
    final destination = LatLng(destLat, destLng);

    // For longer distances, add intermediate points for smoother visualization
    final geometry = _generateStraightLineGeometry(origin, destination);

    // Estimate duration based on average urban speed (~30 km/h)
    // This is a rough estimate for UI purposes only
    final estimatedDuration = (distance / 1000) / 30 * 3600; // seconds

    return RouteResult(
      distance: distance,
      duration: estimatedDuration,
      geometry: geometry,
      source: RouteSource.haversine,
      originCoords: [originLat, originLng],
      destCoords: [destLat, destLng],
    );
  }

  /// Calculates the Haversine distance between two points.
  double _calculateHaversineDistance(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) {
    final dLat = _toRadians(destLat - originLat);
    final dLng = _toRadians(destLng - originLng);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(originLat)) *
            cos(_toRadians(destLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return _earthRadius * c;
  }

  /// Generates a straight-line geometry with intermediate points.
  ///
  /// For short distances (< 5km), returns just origin and destination.
  /// For longer distances, adds intermediate points for smoother map rendering.
  List<LatLng> _generateStraightLineGeometry(
    LatLng origin,
    LatLng destination,
  ) {
    final distance = _calculateHaversineDistance(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude,
    );

    // For short distances, just use two points
    if (distance < 5000) {
      return [origin, destination];
    }

    // For longer distances, interpolate points for smoother display
    final points = <LatLng>[origin];
    final steps = (distance / 2000).ceil().clamp(2, 10); // One point every ~2km

    for (var i = 1; i < steps; i++) {
      final fraction = i / steps;
      final lat =
          origin.latitude + (destination.latitude - origin.latitude) * fraction;
      final lng =
          origin.longitude +
          (destination.longitude - origin.longitude) * fraction;
      points.add(LatLng(lat, lng));
    }

    points.add(destination);
    return points;
  }

  /// Converts degrees to radians.
  double _toRadians(double degree) {
    return degree * pi / 180;
  }
}
