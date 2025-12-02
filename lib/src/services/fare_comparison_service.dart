import 'package:injectable/injectable.dart';
import '../models/transport_mode.dart';

@lazySingleton
class FareComparisonService {
  /// Analyzes a route based on distance and location to recommend transport modes.
  ///
  /// [distanceInMeters]: The total distance of the route in meters.
  /// [isMetroManila]: Whether the route is within Metro Manila (simplistic check for now).
  ///
  /// Returns a list of recommended [TransportMode]s.
  List<TransportMode> recommendModes({
    required double distanceInMeters,
    bool isMetroManila = true,
  }) {
    final List<TransportMode> recommendedModes = [];
    final distanceInKm = distanceInMeters / 1000.0;

    // Short distance (< 5km): Jeepney, Tricycle
    if (distanceInKm < 5.0) {
      recommendedModes.add(TransportMode.jeepney);
      recommendedModes.add(TransportMode.tricycle);
      // Taxi is always an option
      recommendedModes.add(TransportMode.taxi);
    }
    // Medium distance (5km - 20km): Bus, UV Express, Taxi, Jeepney (if < 10km)
    else if (distanceInKm >= 5.0 && distanceInKm < 20.0) {
      recommendedModes.add(TransportMode.bus);
      recommendedModes.add(TransportMode.uvExpress);
      recommendedModes.add(TransportMode.taxi);
      if (distanceInKm < 10.0) {
        recommendedModes.add(TransportMode.jeepney);
      }
    }
    // Long distance (>= 20km): Bus, UV Express
    else {
      recommendedModes.add(TransportMode.bus);
      recommendedModes.add(TransportMode.uvExpress);
      // Taxi is less likely but possible (expensive)
      recommendedModes.add(TransportMode.taxi);
    }

    // Metro Manila specific logic
    if (isMetroManila) {
      // Trains are mostly relevant in Metro Manila
      if (distanceInKm > 2.0) {
         recommendedModes.add(TransportMode.train);
      }
      // Ferries (Pasig River) - very specific, added as option if in MM
      recommendedModes.add(TransportMode.ferry);
    } else {
      // Provincial logic (can be expanded later)
      // Remove train if strictly not in MM (though some trains exist outside, e.g. PNR south)
      // For now, keep it simple.
    }

    // Deduplicate just in case
    return recommendedModes.toSet().toList();
  }
}