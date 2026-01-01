import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/location.dart';
import '../../core/errors/failures.dart';
import '../offline/offline_mode_service.dart';
import 'geocoding_cache_service.dart';

abstract class GeocodingService {
  Future<List<Location>> getLocations(String query);
  Future<Location> getCurrentLocationAddress();
  Future<Location> getAddressFromLatLng(double latitude, double longitude);
}

@LazySingleton(as: GeocodingService)
class OpenStreetMapGeocodingService implements GeocodingService {
  final http.Client _client;
  final GeocodingCacheService _cacheService;
  final OfflineModeService _offlineModeService;

  OpenStreetMapGeocodingService(
    this._cacheService,
    this._offlineModeService,
  ) : _client = http.Client();

  @override
  Future<List<Location>> getLocations(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return [];

    // 1. Support coordinate-based location selection (lat,lng)
    final coordsLocation = _parseCoordinates(trimmedQuery);
    if (coordsLocation != null) {
      return [coordsLocation];
    }

    final cacheKey = trimmedQuery.toLowerCase();

    // 2. Try to get from cache
    final cachedResults = await _cacheService.getCachedResults(cacheKey);

    // 3. If offline, return cached results or throw failure
    if (_offlineModeService.isCurrentlyOffline) {
      if (cachedResults != null && cachedResults.isNotEmpty) {
        return cachedResults;
      }
      throw const NetworkFailure(
        'Offline: Search results not cached for this location.',
      );
    }

    // 4. If online, use cached results if available to save API calls
    // but still allow falling back to network if needed.
    // However, per requirements, we should integrate cache.
    if (cachedResults != null && cachedResults.isNotEmpty) {
      return cachedResults;
    }

    // Nominatim API usage policy requires a User-Agent.
    // Limiting to Philippines (countrycodes=ph) as per app context.
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(trimmedQuery)}&format=json&addressdetails=1&limit=5&countrycodes=ph',
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

        // Cache the successful search results
        await _cacheService.cacheResults(cacheKey, results);
        
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
    final cacheKey = '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}';

    // 1. Try to get from cache
    final cachedResults = await _cacheService.getCachedResults(cacheKey);
    if (cachedResults != null && cachedResults.isNotEmpty) {
      return cachedResults.first;
    }

    // 2. If offline, return coordinate-based location name
    if (_offlineModeService.isCurrentlyOffline) {
      return Location(
        name: '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
        latitude: latitude,
        longitude: longitude,
      );
    }

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

        final location = Location(
          name: displayName,
          latitude: latitude,
          longitude: longitude,
        );

        // Cache the reverse geocoding result
        await _cacheService.cacheResults(cacheKey, [location]);

        return location;
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

  /// Parses a string for coordinates in "lat,lng" format.
  Location? _parseCoordinates(String query) {
    final parts = query.split(',');
    if (parts.length == 2) {
      final lat = double.tryParse(parts[0].trim());
      final lon = double.tryParse(parts[1].trim());
      if (lat != null &&
          lon != null &&
          lat >= -90 &&
          lat <= 90 &&
          lon >= -180 &&
          lon <= 180) {
        return Location(
          name: '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}',
          latitude: lat,
          longitude: lon,
        );
      }
    }
    return null;
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
