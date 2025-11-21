/// Abstract interface for routing services that calculate distances between locations.
/// 
/// This interface allows for different routing service implementations to be swapped
/// out without affecting the core business logic of the fare calculation engine.
abstract class RoutingService {
  /// Calculates the route distance between two coordinate pairs.
  /// 
  /// [originLat], [originLng]: Latitude and Longitude of the starting point.
  /// [destLat], [destLng]: Latitude and Longitude of the destination.
  /// 
  /// Returns the distance in meters.
  /// Throws an exception if the request fails or no route is found.
  Future<double> getDistance(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  );
}