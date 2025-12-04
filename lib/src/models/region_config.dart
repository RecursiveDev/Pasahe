import '../core/constants/region_constants.dart';
import 'transport_mode.dart';

/// Static configuration mapping TransportMode to the regions where they are available.
///
/// Source: docs/workspace/transport_availability_research.md
///
/// This class provides a centralized configuration for regional transport availability,
/// allowing the app to filter out transport modes that are not available in the user's
/// current location.
class RegionConfig {
  /// Map of transport modes to the list of regions where they are available.
  ///
  /// Special values:
  /// - [Region.nationwide]: Available everywhere
  /// - Specific regions: Only available in those regions
  static final Map<TransportMode, List<Region>> modeAvailability = {
    // Jeepney - Available nationwide (traditional) and in major cities (modern)
    // For MVP, we treat jeepney as nationwide since traditional ones are ubiquitous
    TransportMode.jeepney: [Region.nationwide],

    // Bus - Available nationwide (city and provincial)
    TransportMode.bus: [Region.nationwide],

    // Taxi - Available in major cities only
    TransportMode.taxi: [
      Region.ncr,
      Region.cebu,
      Region.davao,
      Region.cdo,
      Region.luzon, // Baguio and other major Luzon cities
    ],

    // Train (LRT/MRT/PNR) - Metro Manila only
    // PNR extends to CALABARZON but primarily NCR
    TransportMode.train: [
      Region.ncr,
      Region.luzon, // PNR to Laguna/Bicol
    ],

    // Ferry - Available nationwide for inter-island travel
    TransportMode.ferry: [Region.nationwide],

    // Tricycle - Available nationwide in all municipalities
    TransportMode.tricycle: [Region.nationwide],

    // UV Express - Major urban centers
    TransportMode.uvExpress: [
      Region.ncr,
      Region.cebu,
      Region.davao,
      Region.luzon,
    ],

    // Van - Similar to UV Express
    TransportMode.van: [Region.ncr, Region.cebu, Region.davao, Region.luzon],

    // Motorcycle (includes habal-habal and app-based)
    // App-based (TNVS): NCR, Cebu, CDO only
    // Habal-habal: Visayas, Mindanao, rural areas
    // For MVP, we enable motorcycle nationwide since habal-habal fills the gap
    TransportMode.motorcycle: [Region.nationwide],

    // EDSA Carousel - STRICTLY Metro Manila (EDSA corridor only)
    TransportMode.edsaCarousel: [Region.ncr],

    // Pedicab - Common in residential areas, mainly in towns/provinces
    TransportMode.pedicab: [Region.nationwide],

    // Kuliglig - Rural/agricultural areas only
    TransportMode.kuliglig: [Region.luzon, Region.visayas, Region.mindanao],
  };

  /// Checks if a transport mode is available in a specific region.
  ///
  /// Returns true if:
  /// 1. The mode is available [Region.nationwide]
  /// 2. The mode is available in the specific region
  /// 3. The mode is available in the parent region (e.g., NCR is part of Luzon)
  static bool isModeAvailable(TransportMode mode, Region region) {
    final availableRegions = modeAvailability[mode];

    if (availableRegions == null) {
      // If mode is not in config, assume it's available everywhere
      return true;
    }

    // Check for nationwide availability
    if (availableRegions.contains(Region.nationwide)) {
      return true;
    }

    // Check for exact region match
    if (availableRegions.contains(region)) {
      return true;
    }

    // Check for parent region availability
    // NCR is part of Luzon
    if (region == Region.ncr && availableRegions.contains(Region.luzon)) {
      return true;
    }

    // Cebu is part of Visayas
    if (region == Region.cebu && availableRegions.contains(Region.visayas)) {
      return true;
    }

    // Davao and CDO are part of Mindanao
    if ((region == Region.davao || region == Region.cdo) &&
        availableRegions.contains(Region.mindanao)) {
      return true;
    }

    return false;
  }

  /// Returns all transport modes available in a specific region.
  static List<TransportMode> getModesForRegion(Region region) {
    return TransportMode.values.where((mode) {
      return isModeAvailable(mode, region);
    }).toList();
  }

  /// Returns a list of regions where a specific mode is available.
  static List<Region> getRegionsForMode(TransportMode mode) {
    return modeAvailability[mode] ?? [Region.nationwide];
  }
}
