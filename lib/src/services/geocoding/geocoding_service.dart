import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/location.dart';

abstract class GeocodingService {
  Future<List<Location>> getLocations(String query);
}

class OpenStreetMapGeocodingService implements GeocodingService {
  final http.Client _client;

  OpenStreetMapGeocodingService({http.Client? client})
      : _client = client ?? http.Client();

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
          'User-Agent': 'PhFareEstimator/1.0 (com.example.ph_fare_estimator)',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Location.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load locations: ${response.statusCode}');
      }
    } catch (e) {
      // Return empty list on error to avoid breaking the UI flow
      return [];
    }
  }
}