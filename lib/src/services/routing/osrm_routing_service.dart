import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/errors/failures.dart';
import 'routing_service.dart';

// @LazySingleton(as: RoutingService) // Disabled for privacy
class OsrmRoutingService implements RoutingService {
  static const String _baseUrl =
      'http://router.project-osrm.org/route/v1/driving';

  /// Fetches the route distance in meters between two coordinates.
  ///
  /// [originLat], [originLng]: Latitude and Longitude of the starting point.
  /// [destLat], [destLng]: Latitude and Longitude of the destination.
  ///
  /// Returns the distance in meters.
  /// Throws an exception if the request fails or no route is found.
  @override
  Future<double> getDistance(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async {
    // OSRM expects {longitude},{latitude}
    final requestUrl =
        '$_baseUrl/$originLng,$originLat;$destLng,$destLat?overview=false';

    try {
      final response = await http.get(Uri.parse(requestUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['code'] == 'Ok' &&
            data['routes'] != null &&
            (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          return (route['distance'] as num).toDouble();
        } else {
          throw ServerFailure(
            'No route found or OSRM returned error: ${data['code']}',
          );
        }
      } else {
        throw ServerFailure(
          'Failed to load route. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure('Error fetching route: $e');
    }
  }
}
