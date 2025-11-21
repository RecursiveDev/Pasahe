class Location {
  final String name;
  final double latitude;
  final double longitude;

  Location({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      name: json['display_name'] ?? 'Unknown Location',
      latitude: double.parse(json['lat']),
      longitude: double.parse(json['lon']),
    );
  }
}