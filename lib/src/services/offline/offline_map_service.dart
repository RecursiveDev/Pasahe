import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart' as fmtc;
import 'package:injectable/injectable.dart';
import 'package:latlong2/latlong.dart';

import '../../models/connectivity_status.dart';
import '../../models/map_region.dart';
import '../connectivity/connectivity_service.dart';

/// Service for managing offline map tiles using flutter_map_tile_caching (FMTC).
///
/// Provides functionality to download, delete, and manage map regions for
/// offline use. Supports pause/resume of downloads and progress tracking.
@lazySingleton
class OfflineMapService {
  final ConnectivityService _connectivityService;

  /// Stream controller for download progress updates.
  final StreamController<RegionDownloadProgress> _progressController =
      StreamController<RegionDownloadProgress>.broadcast();

  /// Whether a download is currently in progress.
  bool _isDownloading = false;

  /// Whether the service has been initialized.
  bool _isInitialized = false;

  /// The FMTC store for tile caching.
  fmtc.FMTCStore? _store;

  /// Store name for the tile cache.
  static const String _storeName = 'ph_fare_calculator_tiles';

  /// Creates a new [OfflineMapService] instance.
  @factoryMethod
  OfflineMapService(this._connectivityService);

  /// Stream of download progress updates.
  Stream<RegionDownloadProgress> get progressStream =>
      _progressController.stream;

  /// Whether a download is currently in progress.
  bool get isDownloading => _isDownloading;

  /// Initializes the FMTC backend and store.
  ///
  /// Must be called before using any other methods.
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize FMTC backend
    await fmtc.FMTCObjectBoxBackend().initialise();

    // Get or create the store
    _store = fmtc.FMTCStore(_storeName);

    // Ensure the store exists with default settings
    await _store!.manage.create();

    _isInitialized = true;
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
          break;
        }
      }
    } catch (e) {
      yield RegionDownloadProgress(
        region: region,
        tilesDownloaded: tilesDownloaded,
        totalTiles: totalTiles,
        bytesDownloaded: bytesDownloaded,
        errorMessage: e.toString(),
      );
      region.status = DownloadStatus.error;
      region.errorMessage = e.toString();
    } finally {
      _isDownloading = false;
    }
  }

  /// Pauses the current download.
  Future<void> pauseDownload() async {
    _ensureInitialized();
    if (_isDownloading) {
      await _store!.download.cancel();
      _isDownloading = false;
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
  Future<void> cancelDownload() async {
    _ensureInitialized();
    if (_isDownloading) {
      await _store!.download.cancel();
      _isDownloading = false;
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
  }

  /// Gets the list of downloaded regions.
  ///
  /// Note: This reads from the stored region metadata.
  Future<List<MapRegion>> getDownloadedRegions() async {
    _ensureInitialized();

    // Filter predefined regions that have been downloaded
    return PredefinedRegions.all
        .where((r) => r.status.isAvailableOffline)
        .toList();
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
    for (final region in PredefinedRegions.all) {
      region.status = DownloadStatus.notDownloaded;
      region.downloadProgress = 0.0;
      region.tilesDownloaded = 0;
      region.actualSizeBytes = null;
      region.lastUpdated = null;
    }
  }

  /// Gets a tile layer that uses the FMTC cache.
  ///
  /// Falls back to network tiles when cache misses occur.
  TileLayer getCachedTileLayer() {
    _ensureInitialized();

    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.ph_fare_calculator',
      tileProvider: fmtc.FMTCTileProvider(
        stores: {_storeName: fmtc.BrowseStoreStrategy.readUpdateCreate},
      ),
    );
  }

  /// Checks if a point is within any downloaded region.
  bool isPointCached(LatLng point) {
    for (final region in PredefinedRegions.all) {
      if (region.status.isAvailableOffline) {
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
