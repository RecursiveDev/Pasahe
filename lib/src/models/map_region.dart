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

/// Type of map region for hierarchical organization.
@HiveType(typeId: 12)
enum RegionType {
  /// A parent region containing multiple islands (e.g., Luzon, Visayas, Mindanao).
  @HiveField(0)
  islandGroup,

  /// An individual island within a parent group.
  @HiveField(1)
  island,
}

/// Extension methods for [RegionType].
extension RegionTypeX on RegionType {
  /// Returns true if this is a parent region that can contain children.
  bool get isParent => this == RegionType.islandGroup;

  /// Returns true if this is a child island.
  bool get isChild => this == RegionType.island;

  /// Returns a human-readable label.
  String get label {
    switch (this) {
      case RegionType.islandGroup:
        return 'Island Group';
      case RegionType.island:
        return 'Island';
    }
  }
}

/// Represents a downloadable map region with optional hierarchical relationships.
///
/// Supports both island groups (parent regions) and individual islands (child regions).
/// Parent regions can be downloaded as a whole, which downloads all child islands.
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

  // ========== NEW FIELDS FOR HIERARCHICAL SUPPORT ==========

  /// Type of region: islandGroup (parent) or island (child).
  /// Defaults to island for backward compatibility with existing data.
  @HiveField(17)
  final RegionType type;

  /// ID of the parent island group (null for island_group types).
  /// Used to establish parent-child relationships.
  @HiveField(18)
  final String? parentId;

  /// Display priority within parent (lower = displayed first).
  @HiveField(19)
  final int priority;

  MapRegion({
    required this.id,
    required this.name,
    required this.description,
    required this.southWestLat,
    required this.southWestLng,
    required this.northEastLat,
    required this.northEastLng,
    this.minZoom = 8,
    this.maxZoom = 14,
    required this.estimatedTileCount,
    required this.estimatedSizeMB,
    this.status = DownloadStatus.notDownloaded,
    this.downloadProgress = 0.0,
    this.tilesDownloaded = 0,
    this.actualSizeBytes,
    this.lastUpdated,
    this.errorMessage,
    // New fields with defaults for backward compatibility
    this.type = RegionType.island,
    this.parentId,
    this.priority = 100,
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

  /// Returns true if this is a parent island group.
  bool get isParent => type == RegionType.islandGroup;

  /// Returns true if this is a child island.
  bool get isChild => type == RegionType.island;

  /// Returns true if this region has a parent.
  bool get hasParent => parentId != null;

  /// Creates a MapRegion from JSON map.
  factory MapRegion.fromJson(Map<String, dynamic> json) {
    final bounds = json['bounds'] as Map<String, dynamic>;
    final typeStr = json['type'] as String? ?? 'island';

    return MapRegion(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      southWestLat: (bounds['southWestLat'] as num).toDouble(),
      southWestLng: (bounds['southWestLng'] as num).toDouble(),
      northEastLat: (bounds['northEastLat'] as num).toDouble(),
      northEastLng: (bounds['northEastLng'] as num).toDouble(),
      minZoom: json['minZoom'] as int? ?? 8,
      maxZoom: json['maxZoom'] as int? ?? 14,
      estimatedTileCount: json['estimatedTileCount'] as int? ?? 0,
      estimatedSizeMB: json['estimatedSizeMB'] as int? ?? 0,
      type: typeStr == 'island_group'
          ? RegionType.islandGroup
          : RegionType.island,
      parentId: json['parentId'] as String?,
      priority: json['priority'] as int? ?? 100,
    );
  }

  /// Converts this MapRegion to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'bounds': {
        'southWestLat': southWestLat,
        'southWestLng': southWestLng,
        'northEastLat': northEastLat,
        'northEastLng': northEastLng,
      },
      'minZoom': minZoom,
      'maxZoom': maxZoom,
      'estimatedTileCount': estimatedTileCount,
      'estimatedSizeMB': estimatedSizeMB,
      'type': type == RegionType.islandGroup ? 'island_group' : 'island',
      'parentId': parentId,
      'priority': priority,
    };
  }

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
    RegionType? type,
    String? parentId,
    int? priority,
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
      type: type ?? this.type,
      parentId: parentId ?? this.parentId,
      priority: priority ?? this.priority,
    );
  }

  @override
  String toString() {
    return 'MapRegion(id: $id, name: $name, type: ${type.label}, status: ${status.label})';
  }
}

/// Predefined regions for the Philippines.
/// @deprecated Use RegionRepository to load regions from JSON instead.
class PredefinedRegions {
  PredefinedRegions._();

  /// Luzon region.
  static MapRegion luzon = MapRegion(
    id: 'luzon',
    name: 'Luzon',
    description: 'Luzon island group',
    southWestLat: 7.5,
    southWestLng: 116.9,
    northEastLat: 21.2,
    northEastLng: 124.6,
    minZoom: 8,
    maxZoom: 14,
    estimatedTileCount: 80000,
    estimatedSizeMB: 800,
    type: RegionType.islandGroup,
    priority: 1,
  );

  /// Visayas region.
  static MapRegion visayas = MapRegion(
    id: 'visayas',
    name: 'Visayas',
    description: 'Visayas island group',
    southWestLat: 9.0,
    southWestLng: 121.0,
    northEastLat: 13.0,
    northEastLng: 126.2,
    minZoom: 8,
    maxZoom: 14,
    estimatedTileCount: 35000,
    estimatedSizeMB: 350,
    type: RegionType.islandGroup,
    priority: 2,
  );

  /// Mindanao region.
  static MapRegion mindanao = MapRegion(
    id: 'mindanao',
    name: 'Mindanao',
    description: 'Mindanao island group',
    southWestLat: 4.5,
    southWestLng: 119.0,
    northEastLat: 10.7,
    northEastLng: 127.0,
    minZoom: 8,
    maxZoom: 14,
    estimatedTileCount: 50000,
    estimatedSizeMB: 500,
    type: RegionType.islandGroup,
    priority: 3,
  );

  /// All predefined regions.
  static List<MapRegion> get all => [luzon, visayas, mindanao];

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

/// Extended progress class for group downloads.
class GroupDownloadProgress extends RegionDownloadProgress {
  /// Child regions being downloaded.
  final List<MapRegion> children;

  /// Current child being downloaded.
  final MapRegion? currentChild;

  /// Index of current child (0-based).
  final int currentChildIndex;

  const GroupDownloadProgress({
    required super.region,
    required super.tilesDownloaded,
    required super.totalTiles,
    super.bytesDownloaded = 0,
    super.isComplete = false,
    super.errorMessage,
    required this.children,
    this.currentChild,
    this.currentChildIndex = 0,
  });

  /// Progress message for UI.
  String get progressMessage {
    if (currentChild != null) {
      return 'Downloading ${currentChild!.name} (${currentChildIndex + 1}/${children.length})';
    }
    return 'Downloading ${region.name}';
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
