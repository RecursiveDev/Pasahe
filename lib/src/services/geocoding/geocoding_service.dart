import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/location.dart';
import '../../core/errors/failures.dart';

abstract class GeocodingService {
  Future<List<Location>> getLocations(String query);
  Future<Location> getCurrentLocationAddress();
  Future<Location> getAddressFromLatLng(double latitude, double longitude);
}

@LazySingleton(as: GeocodingService)
class OpenStreetMapGeocodingService implements GeocodingService {
  final http.Client _client;

  OpenStreetMapGeocodingService() : _client = http.Client();

  @override
  Future<List<Location>> getLocations(String query) async {
    if (query.trim().isEmpty) return [];

    // Nominatim API usage policy requires a User-Agent.
    // Limiting to Philippines (countrycodes=ph) as per app context.
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=5&countrycodes=ph',
    );

    try {
      final response = await _client.get(
        url,
        headers: {
          'User-Agent': 'PhFareCalculator/1.0 (com.example.ph_fare_calculator)',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final results = data.map((json) => Location.fromJson(json)).toList();
        if (results.isEmpty) {
          throw LocationNotFoundFailure();
        }
        return results;
      } else {
        throw ServerFailure('Failed to load locations: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure();
    }
  }

  @override
  Future<Location> getAddressFromLatLng(
    double latitude,
    double longitude,
  ) async {
    try {
      // Reverse geocode using Nominatim
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$latitude&lon=$longitude&format=json&addressdetails=1',
      );

      final response = await _client.get(
        url,
        headers: {'User-Agent': 'PHFareCalculator/1.0'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Extract address from Nominatim response
        final address = data['address'] as Map<String, dynamic>?;
        String displayName =
            data['display_name'] as String? ?? 'Unknown Location';

        // Try to build a more concise name from address components
        if (address != null) {
          final road = address['road'] as String?;
          final suburb = address['suburb'] as String?;
          final city =
              address['city'] as String? ?? address['municipality'] as String?;

          if (road != null && city != null) {
            displayName = '$road, $city';
          } else if (suburb != null && city != null) {
            displayName = '$suburb, $city';
          } else if (city != null) {
            displayName = city;
          }
        }

        return Location(
          name: displayName,
          latitude: latitude,
          longitude: longitude,
        );
      } else {
        throw ServerFailure(
          'Failed to reverse geocode location: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure();
    }
  }

  @override
  Future<Location> getCurrentLocationAddress() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationServiceDisabledFailure();
      }

      // Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw LocationPermissionDeniedFailure();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw LocationPermissionDeniedForeverFailure();
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      );

      // Use the new reverse geocoding method
      return await getAddressFromLatLng(position.latitude, position.longitude);
    } on LocationServiceDisabledFailure {
      rethrow;
    } on LocationPermissionDeniedFailure {
      rethrow;
    } on LocationPermissionDeniedForeverFailure {
      rethrow;
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure();
    }
  }
}
