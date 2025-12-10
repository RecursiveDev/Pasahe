import 'package:flutter_test/flutter_test.dart';
import 'package:ph_fare_calculator/src/models/map_region.dart';

void main() {
  group('DownloadStatus', () {
    test('isAvailableOffline returns true for downloaded status', () {
      expect(DownloadStatus.downloaded.isAvailableOffline, isTrue);
    });

    test('isAvailableOffline returns true for updateAvailable status', () {
      expect(DownloadStatus.updateAvailable.isAvailableOffline, isTrue);
    });

    test('isAvailableOffline returns false for notDownloaded status', () {
      expect(DownloadStatus.notDownloaded.isAvailableOffline, isFalse);
    });

    test('isAvailableOffline returns false for downloading status', () {
      expect(DownloadStatus.downloading.isAvailableOffline, isFalse);
    });

    test('isInProgress returns true for downloading status', () {
      expect(DownloadStatus.downloading.isInProgress, isTrue);
    });

    test('isInProgress returns true for paused status', () {
      expect(DownloadStatus.paused.isInProgress, isTrue);
    });

    test('isInProgress returns false for downloaded status', () {
      expect(DownloadStatus.downloaded.isInProgress, isFalse);
    });

    test('label returns correct string for each status', () {
      expect(DownloadStatus.notDownloaded.label, 'Not downloaded');
      expect(DownloadStatus.downloading.label, 'Downloading');
      expect(DownloadStatus.downloaded.label, 'Downloaded');
      expect(DownloadStatus.updateAvailable.label, 'Update available');
      expect(DownloadStatus.paused.label, 'Paused');
      expect(DownloadStatus.error.label, 'Error');
    });
  });

  group('MapRegion', () {
    late MapRegion region;

    setUp(() {
      region = MapRegion(
        id: 'test_region',
        name: 'Test Region',
        description: 'A test region for unit testing',
        southWestLat: 14.35,
        southWestLng: 120.90,
        northEastLat: 14.80,
        northEastLng: 121.15,
        minZoom: 10,
        maxZoom: 16,
        estimatedTileCount: 15000,
        estimatedSizeMB: 150,
      );
    });

    test('creates region with correct values', () {
      expect(region.id, 'test_region');
      expect(region.name, 'Test Region');
      expect(region.description, 'A test region for unit testing');
      expect(region.southWestLat, 14.35);
      expect(region.southWestLng, 120.90);
      expect(region.northEastLat, 14.80);
      expect(region.northEastLng, 121.15);
      expect(region.minZoom, 10);
      expect(region.maxZoom, 16);
      expect(region.estimatedTileCount, 15000);
      expect(region.estimatedSizeMB, 150);
    });

    test('default status is notDownloaded', () {
      expect(region.status, DownloadStatus.notDownloaded);
    });

    test('default downloadProgress is 0.0', () {
      expect(region.downloadProgress, 0.0);
    });

    test('default tilesDownloaded is 0', () {
      expect(region.tilesDownloaded, 0);
    });

    test('southWest returns correct LatLng', () {
      final sw = region.southWest;
      expect(sw.latitude, 14.35);
      expect(sw.longitude, 120.90);
    });

    test('northEast returns correct LatLng', () {
      final ne = region.northEast;
      expect(ne.latitude, 14.80);
      expect(ne.longitude, 121.15);
    });

    test('center returns correct LatLng', () {
      final center = region.center;
      expect(center.latitude, closeTo(14.575, 0.001));
      expect(center.longitude, closeTo(121.025, 0.001));
    });

    test('copyWith creates a new instance with updated values', () {
      final updated = region.copyWith(
        name: 'Updated Name',
        status: DownloadStatus.downloaded,
        downloadProgress: 1.0,
      );

      expect(updated.id, region.id);
      expect(updated.name, 'Updated Name');
      expect(updated.status, DownloadStatus.downloaded);
      expect(updated.downloadProgress, 1.0);
      expect(updated.description, region.description);
    });

    test('toString returns expected format', () {
      expect(
        region.toString(),
        'MapRegion(id: test_region, name: Test Region, status: Not downloaded)',
      );
    });

    test('status can be updated', () {
      region.status = DownloadStatus.downloading;
      expect(region.status, DownloadStatus.downloading);
    });

    test('downloadProgress can be updated', () {
      region.downloadProgress = 0.5;
      expect(region.downloadProgress, 0.5);
    });

    test('tilesDownloaded can be updated', () {
      region.tilesDownloaded = 5000;
      expect(region.tilesDownloaded, 5000);
    });

    test('lastUpdated can be updated', () {
      final now = DateTime.now();
      region.lastUpdated = now;
      expect(region.lastUpdated, now);
    });

    test('errorMessage can be updated', () {
      region.errorMessage = 'Test error';
      expect(region.errorMessage, 'Test error');
    });
  });

  group('PredefinedRegions', () {
    test('metroManila has correct id', () {
      expect(PredefinedRegions.metroManila.id, 'metro_manila');
    });

    test('metroManila has correct name', () {
      expect(PredefinedRegions.metroManila.name, 'Metro Manila');
    });

    test('cebuMetro has correct id', () {
      expect(PredefinedRegions.cebuMetro.id, 'cebu_metro');
    });

    test('davaoCity has correct id', () {
      expect(PredefinedRegions.davaoCity.id, 'davao_city');
    });

    test('all returns list with 3 regions', () {
      expect(PredefinedRegions.all.length, 3);
    });

    test('getById returns correct region', () {
      final region = PredefinedRegions.getById('metro_manila');
      expect(region, isNotNull);
      expect(region!.name, 'Metro Manila');
    });

    test('getById returns null for unknown id', () {
      final region = PredefinedRegions.getById('unknown_region');
      expect(region, isNull);
    });
  });

  group('RegionDownloadProgress', () {
    late MapRegion region;
    late RegionDownloadProgress progress;

    setUp(() {
      region = MapRegion(
        id: 'test',
        name: 'Test',
        description: 'Test',
        southWestLat: 14.0,
        southWestLng: 120.0,
        northEastLat: 15.0,
        northEastLng: 121.0,
        estimatedTileCount: 1000,
        estimatedSizeMB: 10,
      );

      progress = RegionDownloadProgress(
        region: region,
        tilesDownloaded: 500,
        totalTiles: 1000,
        bytesDownloaded: 5000000,
      );
    });

    test('progress returns correct fraction', () {
      expect(progress.progress, 0.5);
    });

    test('percentage returns correct value', () {
      expect(progress.percentage, 50);
    });

    test('hasError returns false when no error', () {
      expect(progress.hasError, isFalse);
    });

    test('hasError returns true when error message present', () {
      final errorProgress = RegionDownloadProgress(
        region: region,
        tilesDownloaded: 0,
        totalTiles: 1000,
        errorMessage: 'Test error',
      );
      expect(errorProgress.hasError, isTrue);
    });

    test('progress returns 0 when totalTiles is 0', () {
      final zeroProgress = RegionDownloadProgress(
        region: region,
        tilesDownloaded: 0,
        totalTiles: 0,
      );
      expect(zeroProgress.progress, 0.0);
    });

    test('isComplete returns false when not complete', () {
      expect(progress.isComplete, isFalse);
    });

    test('isComplete returns true when complete', () {
      final completeProgress = RegionDownloadProgress(
        region: region,
        tilesDownloaded: 1000,
        totalTiles: 1000,
        isComplete: true,
      );
      expect(completeProgress.isComplete, isTrue);
    });
  });

  group('StorageInfo', () {
    late StorageInfo storageInfo;

    setUp(() {
      storageInfo = StorageInfo(
        appStorageBytes: 104857600, // 100 MB
        mapCacheBytes: 52428800, // 50 MB
        availableBytes: 5368709120, // 5 GB
        totalBytes: 34359738368, // 32 GB
      );
    });

    test('mapCacheMB returns correct value', () {
      expect(storageInfo.mapCacheMB, closeTo(50.0, 0.1));
    });

    test('appStorageMB returns correct value', () {
      expect(storageInfo.appStorageMB, closeTo(100.0, 0.1));
    });

    test('availableGB returns correct value', () {
      expect(storageInfo.availableGB, closeTo(5.0, 0.1));
    });

    test('usedPercentage returns correct value', () {
      final usedBytes = 34359738368 - 5368709120; // total - available
      final expectedPercentage = usedBytes / 34359738368;
      expect(storageInfo.usedPercentage, closeTo(expectedPercentage, 0.01));
    });

    test('mapCacheFormatted returns MB format for large sizes', () {
      expect(storageInfo.mapCacheFormatted, '50.0 MB');
    });

    test('mapCacheFormatted returns KB format for small sizes', () {
      final smallStorage = StorageInfo(
        appStorageBytes: 1024,
        mapCacheBytes: 512000, // ~500 KB
        availableBytes: 1000000000,
        totalBytes: 2000000000,
      );
      expect(smallStorage.mapCacheFormatted, '500.0 KB');
    });

    test('availableFormatted returns correct format', () {
      expect(storageInfo.availableFormatted, '5.0 GB');
    });

    test('usedPercentage returns 0 when totalBytes is 0', () {
      final zeroStorage = StorageInfo(
        appStorageBytes: 0,
        mapCacheBytes: 0,
        availableBytes: 0,
        totalBytes: 0,
      );
      expect(zeroStorage.usedPercentage, 0.0);
    });
  });
}
