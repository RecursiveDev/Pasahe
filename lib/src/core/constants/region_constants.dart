import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

/// Defines the supported regions and their geographical bounding boxes.
///
/// This is a simplified implementation for MVP.
/// Ideally, we would use polygon geofencing for more accuracy.
class RegionConstants {
  // NCR (National Capital Region) / Metro Manila
  // Approximate bounds: North (Valenzuela/Caloocan), South (Muntinlupa), East (Marikina), West (Manila Bay)
  static final LatLngBounds ncrBounds = LatLngBounds(
    const LatLng(14.3500, 120.9000), // Southwest (Cavite/Muntinlupa borderish)
    const LatLng(14.7800, 121.1500), // Northeast (Quezon City/Rizal border)
  );

  // Metro Cebu
  // Approximate bounds covering Cebu City, Mandaue, Lapu-Lapu, Talisay
  static final LatLngBounds cebuBounds = LatLngBounds(
    const LatLng(10.2000, 123.7500), // Southwest (Talisay/Minglanilla)
    const LatLng(10.4500, 124.0500), // Northeast (Liloan/Mactan)
  );

  // Metro Davao
  // Approximate bounds covering Davao City proper
  static final LatLngBounds davaoBounds = LatLngBounds(
    const LatLng(6.9000, 125.3000), // Southwest
    const LatLng(7.3500, 125.8000), // Northeast
  );

  // Cagayan de Oro (CDO)
  static final LatLngBounds cdoBounds = LatLngBounds(
    const LatLng(8.4000, 124.5000),
    const LatLng(8.6000, 124.8000),
  );
}

enum Region {
  ncr,
  cebu,
  davao,
  cdo,
  luzon,
  visayas,
  mindanao,
  nationwide, // Default fallback
}
