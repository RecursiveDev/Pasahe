import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';

part 'map_region.g.dart';

/// Status of a map region download.
@HiveType(typeId: 10)
enum DownloadStatus {
  /// Region has not been downloaded.
  @HiveField(0)
  notDownloaded,

  /// Region is currently being downloaded.
  @HiveField(1)
  downloading,

  /// Region has been downloaded and is available offline.
  @HiveField(2)
  downloaded,

  /// An update is available for this region.
  @HiveField(3)
  updateAvailable,

  /// Download is paused.
  @HiveField(4)
  paused,

  /// Download failed due to an error.
  @HiveField(5)
  error,
}

/// Extension methods for [DownloadStatus].
extension DownloadStatusX on DownloadStatus {
  /// Returns true if the region is available for offline use.
  bool get isAvailableOffline =>
      this == DownloadStatus.downloaded ||
      this == DownloadStatus.updateAvailable;

  /// Returns true if the region is currently downloading.
  bool get isInProgress =>
      this == DownloadStatus.downloading || this == DownloadStatus.paused;

  /// Returns a human-readable label for the status.
  String get label {
    switch (this) {
      case DownloadStatus.notDownloaded:
        return 'Not downloaded';
      case DownloadStatus.downloading:
        return 'Downloading';
      case DownloadStatus.downloaded:
        return 'Downloaded';
      case DownloadStatus.updateAvailable:
        return 'Update available';
      case DownloadStatus.paused:
        return 'Paused';
      case DownloadStatus.error:
        return 'Error';
    }
  }
}

/// Represents a downloadable map region.
///
/// Contains the geographic bounds and metadata for a region
/// that can be downloaded for offline use.
@HiveType(typeId: 11)
class MapRegion extends HiveObject {
  /// Unique identifier for the region.
  @HiveField(0)
  final String id;

  /// Display name of the region.
  @HiveField(1)
  final String name;

  /// Description of the region.
  @HiveField(2)
  final String description;

  /// Southwest latitude of the bounds.
  @HiveField(3)
  final double southWestLat;

  /// Southwest longitude of the bounds.
  @HiveField(4)
  final double southWestLng;

  /// Northeast latitude of the bounds.
  @HiveField(5)
  final double northEastLat;

  /// Northeast longitude of the bounds.
  @HiveField(6)
  final double northEastLng;

  /// Minimum zoom level to download.
  @HiveField(7)
  final int minZoom;

  /// Maximum zoom level to download.
  @HiveField(8)
  final int maxZoom;

  /// Estimated tile count for the region.
  @HiveField(9)
  final int estimatedTileCount;

  /// Estimated size in megabytes.
  @HiveField(10)
  final int estimatedSizeMB;

  /// Current download status.
  @HiveField(11)
  DownloadStatus status;

  /// Download progress (0.0 to 1.0).
  @HiveField(12)
  double downloadProgress;

  /// Number of tiles downloaded.
  @HiveField(13)
  int tilesDownloaded;

  /// Actual size on disk in bytes (after download).
  @HiveField(14)
  int? actualSizeBytes;

  /// Timestamp when the region was last updated.
  @HiveField(15)
  DateTime? lastUpdated;

  /// Error message if download failed.
  @HiveField(16)
  String? errorMessage;

  MapRegion({
    required this.id,
    required this.name,
    required this.description,
    required this.southWestLat,
    required this.southWestLng,
    required this.northEastLat,
    required this.northEastLng,
    this.minZoom = 10,
    this.maxZoom = 16,
    required this.estimatedTileCount,
    required this.estimatedSizeMB,
    this.status = DownloadStatus.notDownloaded,
    this.downloadProgress = 0.0,
    this.tilesDownloaded = 0,
    this.actualSizeBytes,
    this.lastUpdated,
    this.errorMessage,
  });

  /// Gets the southwest corner of the bounds.
  LatLng get southWest => LatLng(southWestLat, southWestLng);

  /// Gets the northeast corner of the bounds.
  LatLng get northEast => LatLng(northEastLat, northEastLng);

  /// Gets the center of the region.
  LatLng get center => LatLng(
    (southWestLat + northEastLat) / 2,
    (southWestLng + northEastLng) / 2,
  );

  /// Creates a copy with updated fields.
  MapRegion copyWith({
    String? id,
    String? name,
    String? description,
    double? southWestLat,
    double? southWestLng,
    double? northEastLat,
    double? northEastLng,
    int? minZoom,
    int? maxZoom,
    int? estimatedTileCount,
    int? estimatedSizeMB,
    DownloadStatus? status,
    double? downloadProgress,
    int? tilesDownloaded,
    int? actualSizeBytes,
    DateTime? lastUpdated,
    String? errorMessage,
  }) {
    return MapRegion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      southWestLat: southWestLat ?? this.southWestLat,
      southWestLng: southWestLng ?? this.southWestLng,
      northEastLat: northEastLat ?? this.northEastLat,
      northEastLng: northEastLng ?? this.northEastLng,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      estimatedTileCount: estimatedTileCount ?? this.estimatedTileCount,
      estimatedSizeMB: estimatedSizeMB ?? this.estimatedSizeMB,
      status: status ?? this.status,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      tilesDownloaded: tilesDownloaded ?? this.tilesDownloaded,
      actualSizeBytes: actualSizeBytes ?? this.actualSizeBytes,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() {
    return 'MapRegion(id: $id, name: $name, status: ${status.label})';
  }
}

/// Predefined regions for the Philippines.
class PredefinedRegions {
  PredefinedRegions._();

  /// Metro Manila region.
  static MapRegion metroManila = MapRegion(
    id: 'metro_manila',
    name: 'Metro Manila',
    description:
        'National Capital Region including all 16 cities and 1 municipality',
    southWestLat: 14.35,
    southWestLng: 120.90,
    northEastLat: 14.80,
    northEastLng: 121.15,
    minZoom: 10,
    maxZoom: 16,
    estimatedTileCount: 15000,
    estimatedSizeMB: 150,
  );

  /// Cebu Metro region.
  static MapRegion cebuMetro = MapRegion(
    id: 'cebu_metro',
    name: 'Cebu City & Metro',
    description: 'Cebu City and surrounding metropolitan area',
    southWestLat: 10.20,
    southWestLng: 123.80,
    northEastLat: 10.45,
    northEastLng: 124.00,
    minZoom: 10,
    maxZoom: 16,
    estimatedTileCount: 8000,
    estimatedSizeMB: 80,
  );

  /// Davao City region.
  static MapRegion davaoCity = MapRegion(
    id: 'davao_city',
    name: 'Davao City',
    description: 'Davao City and surrounding areas',
    southWestLat: 6.90,
    southWestLng: 125.45,
    northEastLat: 7.20,
    northEastLng: 125.70,
    minZoom: 10,
    maxZoom: 16,
    estimatedTileCount: 6000,
    estimatedSizeMB: 60,
  );

  /// All predefined regions.
  static List<MapRegion> get all => [metroManila, cebuMetro, davaoCity];

  /// Gets a region by ID.
  static MapRegion? getById(String id) {
    try {
      return all.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Progress information for a region download.
class RegionDownloadProgress {
  /// The region being downloaded.
  final MapRegion region;

  /// Number of tiles downloaded.
  final int tilesDownloaded;

  /// Total tiles to download.
  final int totalTiles;

  /// Bytes downloaded so far.
  final int bytesDownloaded;

  /// Whether the download is complete.
  final bool isComplete;

  /// Error message if download failed.
  final String? errorMessage;

  const RegionDownloadProgress({
    required this.region,
    required this.tilesDownloaded,
    required this.totalTiles,
    this.bytesDownloaded = 0,
    this.isComplete = false,
    this.errorMessage,
  });

  /// Progress as a fraction (0.0 to 1.0).
  double get progress => totalTiles > 0 ? tilesDownloaded / totalTiles : 0.0;

  /// Progress as a percentage (0 to 100).
  int get percentage => (progress * 100).round();

  /// Whether there was an error.
  bool get hasError => errorMessage != null;

  @override
  String toString() {
    return 'RegionDownloadProgress(${region.name}: $percentage%, $tilesDownloaded/$totalTiles tiles)';
  }
}

/// Storage usage information.
class StorageInfo {
  /// Total app storage usage in bytes.
  final int appStorageBytes;

  /// Map cache storage usage in bytes.
  final int mapCacheBytes;

  /// Available storage on device in bytes.
  final int availableBytes;

  /// Total storage on device in bytes.
  final int totalBytes;

  const StorageInfo({
    required this.appStorageBytes,
    required this.mapCacheBytes,
    required this.availableBytes,
    required this.totalBytes,
  });

  /// Map cache storage in MB.
  double get mapCacheMB => mapCacheBytes / (1024 * 1024);

  /// App storage in MB.
  double get appStorageMB => appStorageBytes / (1024 * 1024);

  /// Available storage in GB.
  double get availableGB => availableBytes / (1024 * 1024 * 1024);

  /// Total used percentage.
  double get usedPercentage =>
      totalBytes > 0 ? (totalBytes - availableBytes) / totalBytes : 0.0;

  /// Formatted string for map cache size.
  String get mapCacheFormatted {
    if (mapCacheBytes < 1024 * 1024) {
      return '${(mapCacheBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${mapCacheMB.toStringAsFixed(1)} MB';
  }

  /// Formatted string for available storage.
  String get availableFormatted {
    return '${availableGB.toStringAsFixed(1)} GB';
  }
}
