import 'package:flutter_test/flutter_test.dart';
import 'package:ph_fare_calculator/src/models/map_region.dart';

void main() {
  group('OfflineMapService - PredefinedRegions', () {
    test('Metro Manila region has valid bounds', () {
      final region = PredefinedRegions.metroManila;

      // Check that bounds are valid
      expect(region.southWestLat, lessThan(region.northEastLat));
      expect(region.southWestLng, lessThan(region.northEastLng));

      // Check reasonable bounds for Metro Manila
      expect(region.southWestLat, greaterThan(14.0));
      expect(region.northEastLat, lessThan(15.0));
      expect(region.southWestLng, greaterThan(120.0));
      expect(region.northEastLng, lessThan(122.0));
    });

    test('Cebu Metro region has valid bounds', () {
      final region = PredefinedRegions.cebuMetro;

      expect(region.southWestLat, lessThan(region.northEastLat));
      expect(region.southWestLng, lessThan(region.northEastLng));

      // Check reasonable bounds for Cebu
      expect(region.southWestLat, greaterThan(10.0));
      expect(region.northEastLat, lessThan(11.0));
    });

    test('Davao City region has valid bounds', () {
      final region = PredefinedRegions.davaoCity;

      expect(region.southWestLat, lessThan(region.northEastLat));
      expect(region.southWestLng, lessThan(region.northEastLng));

      // Check reasonable bounds for Davao
      expect(region.southWestLat, greaterThan(6.0));
      expect(region.northEastLat, lessThan(8.0));
    });

    test('All regions have reasonable zoom levels', () {
      for (final region in PredefinedRegions.all) {
        expect(region.minZoom, greaterThanOrEqualTo(5));
        expect(region.maxZoom, lessThanOrEqualTo(18));
        expect(region.minZoom, lessThan(region.maxZoom));
      }
    });

    test('All regions have positive tile counts', () {
      for (final region in PredefinedRegions.all) {
        expect(region.estimatedTileCount, greaterThan(0));
      }
    });

    test('All regions have positive size estimates', () {
      for (final region in PredefinedRegions.all) {
        expect(region.estimatedSizeMB, greaterThan(0));
      }
    });
  });

  group('RegionDownloadProgress', () {
    test('progress calculation is correct', () {
      final region = PredefinedRegions.metroManila;
      final progress = RegionDownloadProgress(
        region: region,
        tilesDownloaded: 7500,
        totalTiles: 15000,
      );

      expect(progress.progress, 0.5);
      expect(progress.percentage, 50);
    });

    test('complete progress shows 100%', () {
      final region = PredefinedRegions.metroManila;
      final progress = RegionDownloadProgress(
        region: region,
        tilesDownloaded: 15000,
        totalTiles: 15000,
        isComplete: true,
      );

      expect(progress.progress, 1.0);
      expect(progress.percentage, 100);
      expect(progress.isComplete, isTrue);
    });

    test('error handling works correctly', () {
      final region = PredefinedRegions.metroManila;
      final progress = RegionDownloadProgress(
        region: region,
        tilesDownloaded: 5000,
        totalTiles: 15000,
        errorMessage: 'Network error',
      );

      expect(progress.hasError, isTrue);
      expect(progress.errorMessage, 'Network error');
    });
  });

  group('StorageInfo', () {
    test('calculates MB correctly', () {
      const info = StorageInfo(
        appStorageBytes: 1048576 * 100, // 100 MB
        mapCacheBytes: 1048576 * 50, // 50 MB
        availableBytes: 1073741824 * 5, // 5 GB
        totalBytes: 1073741824 * 32, // 32 GB
      );

      expect(info.appStorageMB, closeTo(100, 0.1));
      expect(info.mapCacheMB, closeTo(50, 0.1));
    });

    test('calculates GB correctly', () {
      const info = StorageInfo(
        appStorageBytes: 0,
        mapCacheBytes: 0,
        availableBytes: 1073741824 * 10, // 10 GB
        totalBytes: 1073741824 * 32, // 32 GB
      );

      expect(info.availableGB, closeTo(10, 0.1));
    });

    test('formats cache size correctly', () {
      const smallInfo = StorageInfo(
        appStorageBytes: 0,
        mapCacheBytes: 512000, // ~500 KB
        availableBytes: 1073741824,
        totalBytes: 1073741824 * 2,
      );

      expect(smallInfo.mapCacheFormatted.contains('KB'), isTrue);

      const largeInfo = StorageInfo(
        appStorageBytes: 0,
        mapCacheBytes: 52428800, // 50 MB
        availableBytes: 1073741824,
        totalBytes: 1073741824 * 2,
      );

      expect(largeInfo.mapCacheFormatted.contains('MB'), isTrue);
    });
  });
}
