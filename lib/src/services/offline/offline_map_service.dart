import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart' as fmtc;
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
import 'package:latlong2/latlong.dart';

import '../../models/connectivity_status.dart';
import '../../models/map_region.dart';
import '../../repositories/region_repository.dart';
import '../connectivity/connectivity_service.dart';

/// Service for managing offline map tiles using flutter_map_tile_caching (FMTC).
///
/// Provides functionality to download, delete, and manage map regions for
/// offline use. Supports pause/resume of downloads and progress tracking.
/// Now uses [RegionRepository] to load hierarchical regions from JSON.
@lazySingleton
class OfflineMapService {
  final ConnectivityService _connectivityService;
  final RegionRepository _regionRepository;

  /// Stream controller for download progress updates.
  final StreamController<RegionDownloadProgress> _progressController =
      StreamController<RegionDownloadProgress>.broadcast();

  /// Whether a download is currently in progress.
  bool _isDownloading = false;

  /// Whether cancellation has been requested for the current download.
  bool _cancelRequested = false;

  /// The region currently being downloaded (for status reset on cancel).
  MapRegion? _currentDownloadingRegion;

  /// Whether the service has been initialized.
  bool _isInitialized = false;

  /// The FMTC store for tile caching.
  fmtc.FMTCStore? _store;

  /// Hive box for storing region metadata.
  Box<MapRegion>? _regionsBox;

  /// All regions loaded from JSON.
  List<MapRegion> _allRegions = [];

  /// Store name for the tile cache.
  static const String _storeName = 'ph_fare_calculator_tiles';

  /// Store name for the regions Hive box.
  static const String _regionsBoxName = 'offline_maps';

  /// Creates a new [OfflineMapService] instance.
  @factoryMethod
  OfflineMapService(this._connectivityService, this._regionRepository);

  /// Stream of download progress updates.
  Stream<RegionDownloadProgress> get progressStream =>
      _progressController.stream;

  /// Whether a download is currently in progress.
  bool get isDownloading => _isDownloading;

  /// Gets all loaded regions.
  List<MapRegion> get allRegions => List.unmodifiable(_allRegions);

  /// Initializes the FMTC backend and store.
  ///
  /// Must be called before using any other methods.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize FMTC backend
      await fmtc.FMTCObjectBoxBackend().initialise();

      // Get or create the store
      _store = fmtc.FMTCStore(_storeName);

      // Ensure the store exists with default settings
      await _store!.manage.create();
    } catch (e) {
      // ignore: avoid_print
      print('Failed to initialize FMTC backend: $e');
    }

    // Initialize Hive persistence for regions
    try {
      if (!Hive.isBoxOpen(_regionsBoxName)) {
        _regionsBox = await Hive.openBox<MapRegion>(_regionsBoxName);
      } else {
        _regionsBox = Hive.box<MapRegion>(_regionsBoxName);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Failed to initialize Hive box for offline maps: $e');
    }

    // Load regions from JSON
    await _loadRegionsFromJson();

    // Restore saved region states from Hive
    await _restoreRegionStates();

    _isInitialized = true;
  }

  /// Loads regions from JSON and caches them.
  Future<void> _loadRegionsFromJson() async {
    try {
      _allRegions = await _regionRepository.loadAllRegions();
    } catch (e) {
      // ignore: avoid_print
      print('Failed to load regions from JSON: $e');
      // Fall back to predefined regions for backward compatibility
      _allRegions = PredefinedRegions.all;
    }
  }

  /// Restores download states from Hive for all regions.
  Future<void> _restoreRegionStates() async {
    if (_regionsBox == null) return;

    for (final region in _allRegions) {
      final savedRegion = _regionsBox!.get(region.id);
      if (savedRegion != null) {
        // Restore state from persistence
        region.status = savedRegion.status;
        region.downloadProgress = savedRegion.downloadProgress;
        region.tilesDownloaded = savedRegion.tilesDownloaded;
        region.actualSizeBytes = savedRegion.actualSizeBytes;
        region.lastUpdated = savedRegion.lastUpdated;
        region.errorMessage = savedRegion.errorMessage;
      }
    }
  }

  /// Gets all island groups (parent regions).
  Future<List<MapRegion>> getIslandGroups() async {
    return _allRegions.where((r) => r.type == RegionType.islandGroup).toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
  }

  /// Gets all islands for a given parent group.
  Future<List<MapRegion>> getIslandsForGroup(String parentId) async {
    return _allRegions.where((r) => r.parentId == parentId).toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
  }

  /// Gets a region by ID.
  MapRegion? getRegionById(String id) {
    try {
      return _allRegions.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Gets the FMTC store for use with tile providers.
  fmtc.FMTCStore get store {
    _ensureInitialized();
    return _store!;
  }

  /// Downloads a map region for offline use.
  ///
  /// Returns a stream of [RegionDownloadProgress] updates.
  /// The download can be cancelled using [cancelDownload].
  Stream<RegionDownloadProgress> downloadRegion(MapRegion region) async* {
    _ensureInitialized();

    // Reset cancellation flag at the very start, before any early returns
    _cancelRequested = false;

    // Check connectivity first
    final status = await _connectivityService.currentStatus;
    if (status == ConnectivityStatus.offline) {
      yield RegionDownloadProgress(
        region: region,
        tilesDownloaded: 0,
        totalTiles: region.estimatedTileCount,
        errorMessage: 'No internet connection available',
      );
      return;
    }

    _isDownloading = true;
    _currentDownloadingRegion = region;
    region.status = DownloadStatus.downloading;

    // Create the downloadable region
    final downloadableRegion =
        fmtc.RectangleRegion(
          LatLngBounds(region.southWest, region.northEast),
        ).toDownloadable(
          minZoom: region.minZoom,
          maxZoom: region.maxZoom,
          options: TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.ph_fare_calculator',
          ),
        );

    int tilesDownloaded = 0;
    int bytesDownloaded = 0;
    int totalTiles = region.estimatedTileCount;

    try {
      // Start the download
      final downloadStream = _store!.download.startForeground(
        region: downloadableRegion,
      );

      await for (final event in downloadStream.downloadProgress) {
        // FMTC v10 DownloadProgress properties
        final progressPercent = event.percentageProgress;
        tilesDownloaded = ((progressPercent / 100) * totalTiles).round();

        // Update region progress
        region.downloadProgress = progressPercent / 100;
        region.tilesDownloaded = tilesDownloaded;

        final progress = RegionDownloadProgress(
          region: region,
          tilesDownloaded: tilesDownloaded,
          totalTiles: totalTiles,
          bytesDownloaded: bytesDownloaded,
          isComplete: progressPercent >= 100,
        );

        _progressController.add(progress);
        yield progress;

        if (progressPercent >= 100) {
          // Update region status
          region.status = DownloadStatus.downloaded;
          region.downloadProgress = 1.0;
          region.tilesDownloaded = tilesDownloaded;
          region.lastUpdated = DateTime.now();

          // Save to Hive
          await _regionsBox?.put(region.id, region);

          // Update parent group status if applicable
          if (region.parentId != null) {
            await _updateGroupStatus(region.parentId!);
          }

          break;
        }
      }
    } catch (e) {
      // Only set error status if not cancelled
      if (!_cancelRequested) {
        yield RegionDownloadProgress(
          region: region,
          tilesDownloaded: tilesDownloaded,
          totalTiles: totalTiles,
          bytesDownloaded: bytesDownloaded,
          errorMessage: e.toString(),
        );
        region.status = DownloadStatus.error;
        region.errorMessage = e.toString();
      }
    } finally {
      // Check if download was cancelled (stream ended without completion)
      if (_cancelRequested && region.status == DownloadStatus.downloading) {
        region.status = DownloadStatus.notDownloaded;
        region.downloadProgress = 0.0;
        region.tilesDownloaded = 0;
        region.errorMessage = null;
        await _regionsBox?.put(region.id, region);

        // Update parent group status if applicable
        if (region.parentId != null) {
          await _updateGroupStatus(region.parentId!);
        }
      }
      _isDownloading = false;
      _currentDownloadingRegion = null;
    }
  }

  /// Downloads all child islands for an island group.
  ///
  /// Emits progress for each child region and aggregates total progress.
  Future<void> downloadIslandGroup(String groupId) async {
    _ensureInitialized();

    // Reset cancellation flag at the very start to allow new downloads
    _cancelRequested = false;

    final children = await getIslandsForGroup(groupId);

    if (children.isEmpty) {
      throw ArgumentError('No islands found for group: $groupId');
    }

    int totalTiles = children.fold<int>(
      0,
      (sum, r) => sum + r.estimatedTileCount,
    );
    int downloadedTiles = 0;

    final group = getRegionById(groupId);
    if (group != null) {
      group.status = DownloadStatus.downloading;
      await _regionsBox?.put(group.id, group);
    }

    for (int i = 0; i < children.length; i++) {
      // Check if cancellation was requested before starting next child
      if (_cancelRequested) {
        break;
      }

      final child = children[i];

      if (child.status == DownloadStatus.downloaded) {
        downloadedTiles += child.tilesDownloaded;
        continue;
      }

      await for (final progress in downloadRegion(child)) {
        // Emit aggregated progress for the group
        if (group != null) {
          final groupProgress = GroupDownloadProgress(
            region: group,
            tilesDownloaded: downloadedTiles + progress.tilesDownloaded,
            totalTiles: totalTiles,
            children: children,
            currentChild: child,
            currentChildIndex: i,
          );
          _progressController.add(groupProgress);
        }
      }

      // Check if download was cancelled
      if (_cancelRequested) {
        break;
      }

      downloadedTiles += child.tilesDownloaded;
    }

    // Update parent group status (handles both completion and cancellation)
    await _updateGroupStatus(groupId);
  }

  /// Updates the parent group's status based on children.
  Future<void> _updateGroupStatus(String groupId) async {
    final group = getRegionById(groupId);
    if (group == null) return;

    final children = await getIslandsForGroup(groupId);

    final allDownloaded = children.every(
      (c) => c.status == DownloadStatus.downloaded,
    );
    final anyDownloading = children.any(
      (c) => c.status == DownloadStatus.downloading,
    );
    final anyError = children.any((c) => c.status == DownloadStatus.error);

    if (allDownloaded) {
      group.status = DownloadStatus.downloaded;
      group.downloadProgress = 1.0;
      group.lastUpdated = DateTime.now();
    } else if (anyDownloading) {
      group.status = DownloadStatus.downloading;
    } else if (anyError) {
      group.status = DownloadStatus.error;
    } else {
      // Calculate partial progress
      final downloadedCount = children
          .where((c) => c.status == DownloadStatus.downloaded)
          .length;
      group.downloadProgress = downloadedCount / children.length;
      group.status = DownloadStatus.notDownloaded;
    }

    await _regionsBox?.put(group.id, group);
  }

  /// Gets the aggregated download status for an island group.
  Future<DownloadStatus> getGroupDownloadStatus(String groupId) async {
    final children = await getIslandsForGroup(groupId);
    if (children.isEmpty) return DownloadStatus.notDownloaded;

    final allDownloaded = children.every(
      (c) => c.status == DownloadStatus.downloaded,
    );
    final anyDownloading = children.any(
      (c) => c.status == DownloadStatus.downloading,
    );
    final anyDownloaded = children.any(
      (c) => c.status == DownloadStatus.downloaded,
    );
    final anyError = children.any((c) => c.status == DownloadStatus.error);

    if (allDownloaded) return DownloadStatus.downloaded;
    if (anyDownloading) return DownloadStatus.downloading;
    if (anyError) return DownloadStatus.error;
    if (anyDownloaded) return DownloadStatus.paused; // Partial download
    return DownloadStatus.notDownloaded;
  }

  /// Pauses the current download.
  ///
  /// Sets the region status to [DownloadStatus.paused] instead of resetting it.
  Future<void> pauseDownload() async {
    _ensureInitialized();
    if (_isDownloading && _currentDownloadingRegion != null) {
      // For pause, we set status to paused instead of notDownloaded
      _currentDownloadingRegion!.status = DownloadStatus.paused;
      await _regionsBox?.put(
        _currentDownloadingRegion!.id,
        _currentDownloadingRegion!,
      );
      await _store!.download.cancel();
      _isDownloading = false;
      _currentDownloadingRegion = null;
    }
  }

  /// Resumes a paused download.
  ///
  /// Note: FMTC doesn't support true resume, so this restarts the download.
  /// Already downloaded tiles are served from cache.
  Stream<RegionDownloadProgress> resumeDownload(MapRegion region) {
    return downloadRegion(region);
  }

  /// Cancels the current download.
  ///
  /// Sets a cancellation flag and resets the region status to [DownloadStatus.notDownloaded].
  Future<void> cancelDownload() async {
    _ensureInitialized();
    if (_isDownloading) {
      _cancelRequested = true;
      await _store!.download.cancel();
      // Note: The actual status reset happens in downloadRegion's finally block
      // after the stream terminates due to cancellation
    }
  }

  /// Deletes all cached tiles for a region.
  ///
  /// Note: FMTC doesn't support per-region deletion easily,
  /// so this marks the region as not downloaded.
  Future<void> deleteRegion(MapRegion region) async {
    _ensureInitialized();

    // Mark the region as not downloaded
    region.status = DownloadStatus.notDownloaded;
    region.downloadProgress = 0.0;
    region.tilesDownloaded = 0;
    region.actualSizeBytes = null;
    region.lastUpdated = null;
    region.errorMessage = null;

    // Remove from Hive
    await _regionsBox?.delete(region.id);

    // Update parent group status if applicable
    if (region.parentId != null) {
      await _updateGroupStatus(region.parentId!);
    }
  }

  /// Deletes all child islands for an island group.
  Future<void> deleteIslandGroup(String groupId) async {
    final children = await getIslandsForGroup(groupId);

    for (final child in children) {
      await deleteRegion(child);
    }

    // Update group status
    final group = getRegionById(groupId);
    if (group != null) {
      group.status = DownloadStatus.notDownloaded;
      group.downloadProgress = 0.0;
      await _regionsBox?.delete(group.id);
    }
  }

  /// Gets the list of downloaded regions.
  ///
  /// Note: This reads from the stored region metadata.
  Future<List<MapRegion>> getDownloadedRegions() async {
    _ensureInitialized();

    // Filter regions that have been downloaded
    return _allRegions.where((r) => r.status.isAvailableOffline).toList();
  }

  /// Gets storage usage information.
  Future<StorageInfo> getStorageUsage() async {
    _ensureInitialized();

    final storeStats = await _store!.stats.all;
    final cacheSize = storeStats.size.toInt();

    return StorageInfo(
      appStorageBytes: cacheSize,
      mapCacheBytes: cacheSize,
      availableBytes: 1024 * 1024 * 1024 * 10, // 10GB placeholder
      totalBytes: 1024 * 1024 * 1024 * 32, // 32GB placeholder
    );
  }

  /// Clears all cached tiles.
  Future<void> clearAllTiles() async {
    _ensureInitialized();
    await _store!.manage.reset();

    // Reset all regions to not downloaded
    for (final region in _allRegions) {
      region.status = DownloadStatus.notDownloaded;
      region.downloadProgress = 0.0;
      region.tilesDownloaded = 0;
      region.actualSizeBytes = null;
      region.lastUpdated = null;
    }

    // Clear Hive box
    await _regionsBox?.clear();
  }

  /// CartoDB Voyager tile URL - used for both light and dark mode
  /// Voyager has excellent road visibility and supports zoom levels 0-20
  /// For dark mode, we apply a color inversion filter at the widget level
  static const String _voyagerTileUrl =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';

  /// Subdomains for CartoDB tile servers (load balancing)
  static const List<String> _cartoSubdomains = ['a', 'b', 'c', 'd'];

  /// Color inversion matrix for dark mode
  /// This inverts the light Voyager tiles to create a dark appearance with visible roads
  static const ColorFilter darkModeInvertFilter = ColorFilter.matrix(<double>[
    -1,
    0,
    0,
    0,
    255,
    0,
    -1,
    0,
    0,
    255,
    0,
    0,
    -1,
    0,
    255,
    0,
    0,
    0,
    1,
    0,
  ]);

  /// Wraps a widget with the dark mode color inversion filter
  ///
  /// Use this to wrap TileLayer widgets when displaying maps in dark mode.
  /// The filter inverts the light Voyager tiles to create a dark appearance.
  static Widget wrapWithDarkModeFilter(Widget child) {
    return ColorFiltered(colorFilter: darkModeInvertFilter, child: child);
  }

  /// Gets a tile layer that uses the FMTC cache.
  ///
  /// Falls back to network tiles when cache misses occur.
  /// Uses light mode tiles by default.
  TileLayer getCachedTileLayer() {
    return getThemedCachedTileLayer(isDarkMode: false);
  }

  /// Gets a theme-aware tile layer that uses the FMTC cache.
  ///
  /// Uses CartoDB Voyager tiles for both light and dark mode.
  /// For dark mode, the calling widget should wrap this with [wrapWithDarkModeFilter].
  /// Falls back to network tiles when cache misses occur.
  TileLayer getThemedCachedTileLayer({required bool isDarkMode}) {
    _ensureInitialized();

    // Both light and dark mode use Voyager tiles
    // Dark mode applies color inversion at the widget level
    return TileLayer(
      urlTemplate: _voyagerTileUrl,
      subdomains: _cartoSubdomains,
      userAgentPackageName: 'com.ph_fare_calculator',
      maxZoom: 20, // Voyager supports up to zoom 20
      tileProvider: fmtc.FMTCTileProvider(
        stores: {_storeName: fmtc.BrowseStoreStrategy.readUpdateCreate},
      ),
    );
  }

  /// Gets a tile layer without FMTC caching (for fallback scenarios).
  ///
  /// Uses CartoDB Voyager tiles for both light and dark mode.
  /// For dark mode, the calling widget should wrap this with [wrapWithDarkModeFilter].
  static TileLayer getNetworkTileLayer({required bool isDarkMode}) {
    // Both light and dark mode use Voyager tiles
    // Dark mode applies color inversion at the widget level
    return TileLayer(
      urlTemplate: _voyagerTileUrl,
      subdomains: _cartoSubdomains,
      userAgentPackageName: 'com.ph_fare_calculator',
      maxZoom: 20, // Voyager supports up to zoom 20
    );
  }

  /// Checks if a point is within any downloaded region.
  bool isPointCached(LatLng point) {
    for (final region in _allRegions) {
      if (region.status.isAvailableOffline &&
          region.type == RegionType.island) {
        if (point.latitude >= region.southWestLat &&
            point.latitude <= region.northEastLat &&
            point.longitude >= region.southWestLng &&
            point.longitude <= region.northEastLng) {
          return true;
        }
      }
    }
    return false;
  }

  /// Estimates the number of tiles for a region.
  int estimateTileCount(MapRegion region) {
    int count = 0;
    for (int zoom = region.minZoom; zoom <= region.maxZoom; zoom++) {
      final tilesAtZoom = _estimateTilesAtZoom(
        region.southWestLat,
        region.southWestLng,
        region.northEastLat,
        region.northEastLng,
        zoom,
      );
      count += tilesAtZoom;
    }
    return count;
  }

  int _estimateTilesAtZoom(
    double minLat,
    double minLng,
    double maxLat,
    double maxLng,
    int zoom,
  ) {
    final n = 1 << zoom; // 2^zoom

    final minTileX = ((minLng + 180) / 360 * n).floor();
    final maxTileX = ((maxLng + 180) / 360 * n).floor();
    final minTileY =
        ((1 -
                    _log(
                          math.tan(minLat * math.pi / 180) +
                              1 / math.cos(minLat * math.pi / 180),
                        ) /
                        math.pi) /
                2 *
                n)
            .floor();
    final maxTileY =
        ((1 -
                    _log(
                          math.tan(maxLat * math.pi / 180) +
                              1 / math.cos(maxLat * math.pi / 180),
                        ) /
                        math.pi) /
                2 *
                n)
            .floor();

    final width = (maxTileX - minTileX).abs() + 1;
    final height = (maxTileY - minTileY).abs() + 1;

    return width * height;
  }

  double _log(double x) => x > 0 ? math.log(x) / math.log(math.e) : 0;

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'OfflineMapService must be initialized before use. Call initialize() first.',
      );
    }
  }

  /// Disposes of the service and releases resources.
  Future<void> dispose() async {
    await _progressController.close();
  }
}
