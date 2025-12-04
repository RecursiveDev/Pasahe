import 'package:injectable/injectable.dart';
import '../models/transport_mode.dart';
import '../models/fare_result.dart';
import '../core/constants/region_constants.dart';
import 'transport_mode_filter_service.dart';

enum SortCriteria { priceAsc, priceDesc, durationAsc, durationDesc }

@lazySingleton
class FareComparisonService {
  final TransportModeFilterService _filterService;

  FareComparisonService(this._filterService);

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

  /// Sorts a list of fare results based on the specified criteria.
  ///
  /// [results]: The list of FareResult objects to sort.
  /// [criteria]: The sorting criteria (price or duration, ascending or descending).
  ///
  /// Groups fare results by their transport mode.
  ///
  /// [results]: The list of FareResult objects to group.
  ///
  /// Returns a map where keys are TransportMode and values are lists of FareResult.
  Map<TransportMode, List<FareResult>> groupFaresByMode(
    List<FareResult> results,
  ) {
    final grouped = <TransportMode, List<FareResult>>{};

    for (final result in results) {
      // Parse mode string to enum
      final mode = TransportMode.fromString(result.transportMode);

      if (!grouped.containsKey(mode)) {
        grouped[mode] = [];
      }
      grouped[mode]!.add(result);
    }

    return grouped;
  }

  /// Returns a new sorted list of FareResult objects.
  List<FareResult> sortFares(List<FareResult> results, SortCriteria criteria) {
    final sortedResults = List<FareResult>.from(results);

    switch (criteria) {
      case SortCriteria.priceAsc:
        sortedResults.sort((a, b) => a.totalFare.compareTo(b.totalFare));
        break;
      case SortCriteria.priceDesc:
        sortedResults.sort((a, b) => b.totalFare.compareTo(a.totalFare));
        break;
      case SortCriteria.durationAsc:
        // Note: Duration sorting would require duration data in FareResult
        // For now, we'll use the same logic as price or throw
        throw UnimplementedError(
          'Duration sorting requires duration data in FareResult',
        );
      case SortCriteria.durationDesc:
        // Note: Duration sorting would require duration data in FareResult
        throw UnimplementedError(
          'Duration sorting requires duration data in FareResult',
        );
    }

    return sortedResults;
  }

  /// Compares multiple transport modes and returns fare results.
  ///
  /// This method filters fare results based on regional transport availability.
  /// Transport modes that are not available at the given origin location
  /// will be filtered out before returning the results.
  ///
  /// [fareResults]: The list of FareResult objects to compare.
  /// [passengerCount]: Number of passengers (for future use).
  /// [originLat]: Latitude of the origin (for regional filtering).
  /// [originLng]: Longitude of the origin (for regional filtering).
  ///
  /// Note: The actual fare calculation should be done by HybridEngine.
  /// This method handles filtering and comparison logic.
  Future<List<FareResult>> compareFares({
    required List<FareResult> fareResults,
    int passengerCount = 1,
    double? originLat,
    double? originLng,
  }) async {
    // If origin coordinates are not provided, return results as-is
    if (originLat == null || originLng == null) {
      return fareResults;
    }

    // Filter fare results based on regional availability
    final filteredResults = fareResults.where((result) {
      final mode = TransportMode.fromString(result.transportMode);
      return _filterService.isModeValid(mode, originLat, originLng);
    }).toList();

    return filteredResults;
  }

  /// Filters fare results based on a specific region.
  ///
  /// This is useful when you already know the region and don't need
  /// to perform the geo-lookup.
  List<FareResult> filterByRegion(List<FareResult> results, Region region) {
    return results.where((result) {
      final mode = TransportMode.fromString(result.transportMode);
      return _filterService.isModeValid(
        mode,
        // Use dummy coordinates within the region for validation
        // Since we already have the region, we just need a point inside it
        _getRepresentativeCoordinates(region).$1,
        _getRepresentativeCoordinates(region).$2,
      );
    }).toList();
  }

  /// Returns representative coordinates for a region.
  /// Used for validation when we already know the region.
  (double, double) _getRepresentativeCoordinates(Region region) {
    switch (region) {
      case Region.ncr:
        return (14.5995, 120.9842); // Manila
      case Region.cebu:
        return (10.3157, 123.8854); // Cebu City
      case Region.davao:
        return (7.0731, 125.6128); // Davao City
      case Region.cdo:
        return (8.4542, 124.6319); // Cagayan de Oro
      case Region.luzon:
        return (15.0, 121.0); // Central Luzon
      case Region.visayas:
        return (10.7, 123.0); // Visayas
      case Region.mindanao:
        return (7.5, 125.0); // Mindanao
      case Region.nationwide:
        return (14.5995, 120.9842); // Default to Manila
    }
  }
}
