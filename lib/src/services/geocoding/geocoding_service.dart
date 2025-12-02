import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import '../../models/location.dart';
import '../../core/errors/failures.dart';

abstract class GeocodingService {
  Future<List<Location>> getLocations(String query);
}

@LazySingleton(as: GeocodingService)
class OpenStreetMapGeocodingService implements GeocodingService {
  final http.Client _client;

  OpenStreetMapGeocodingService()
      : _client = http.Client();

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
}