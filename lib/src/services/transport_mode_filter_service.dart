import 'package:injectable/injectable.dart';
import 'package:latlong2/latlong.dart';
import '../models/transport_mode.dart';
import '../models/region_config.dart';
import '../core/constants/region_constants.dart';

@lazySingleton
class TransportModeFilterService {
  /// Determines the region of a given location.
  ///
  /// Checks regions in order of specificity (City > Region > Nationwide).
  Region getRegionForLocation(double lat, double lng) {
    final point = LatLng(lat, lng);

    if (RegionConstants.ncrBounds.contains(point)) {
      return Region.ncr;
    }
    if (RegionConstants.cebuBounds.contains(point)) {
      return Region.cebu;
    }
    if (RegionConstants.davaoBounds.contains(point)) {
      return Region.davao;
    }
    if (RegionConstants.cdoBounds.contains(point)) {
      return Region.cdo;
    }

    // Fallback for broader regions if we had polygon data for Luzon/Visayas/Mindanao
    // For MVP, we default to nationwide if not in a specific urban center.
    // Ideally, we'd check latitude ranges:
    // Luzon: > 12.5
    // Visayas: 9.0 - 12.5
    // Mindanao: < 9.0
    if (lat > 12.5) {
      return Region.luzon;
    } else if (lat >= 9.0 && lat <= 12.5) {
      return Region.visayas;
    } else {
      return Region.mindanao;
    }
  }

  /// Returns a list of available transport modes for a given location.
  List<TransportMode> getAvailableModes(double lat, double lng) {
    final region = getRegionForLocation(lat, lng);

    // Get all modes and filter based on the region
    return TransportMode.values.where((mode) {
      // 1. Check strict region availability from config
      final isAvailableInRegion = RegionConfig.isModeAvailable(mode, region);

      // 2. We can add extra dynamic logic here if needed (e.g. time of day)

      return isAvailableInRegion;
    }).toList();
  }

  /// Checks if a specific mode is valid for the given location.
  bool isModeValid(TransportMode mode, double lat, double lng) {
    final region = getRegionForLocation(lat, lng);
    return RegionConfig.isModeAvailable(mode, region);
  }
}
