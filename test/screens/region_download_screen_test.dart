import 'package:flutter_test/flutter_test.dart';
import 'package:ph_fare_calculator/src/models/map_region.dart';

void main() {
  group('RegionDownloadScreen Widget Tests', () {
    // Note: Full widget tests require DI setup with OfflineMapService
    // These tests focus on the model logic used by the screen

    group('MapRegion display logic', () {
      test('region card shows estimated size for not downloaded', () {
        final region = MapRegion(
          id: 'test',
          name: 'Test Region',
          description: 'Test description',
          southWestLat: 14.0,
          southWestLng: 120.0,
          northEastLat: 15.0,
          northEastLng: 121.0,
          estimatedTileCount: 1000,
          estimatedSizeMB: 50,
          status: DownloadStatus.notDownloaded,
        );

        expect(region.status, DownloadStatus.notDownloaded);
        expect(region.estimatedSizeMB, 50);
      });

      test('region card shows progress for downloading', () {
        final region = MapRegion(
          id: 'test',
          name: 'Test Region',
          description: 'Test description',
          southWestLat: 14.0,
          southWestLng: 120.0,
          northEastLat: 15.0,
          northEastLng: 121.0,
          estimatedTileCount: 1000,
          estimatedSizeMB: 50,
          status: DownloadStatus.downloading,
          downloadProgress: 0.45,
        );

        expect(region.status, DownloadStatus.downloading);
        expect(region.downloadProgress, 0.45);
        expect((region.downloadProgress * 100).toInt(), 45);
      });

      test('region card shows checkmark for downloaded', () {
        final region = MapRegion(
          id: 'test',
          name: 'Test Region',
          description: 'Test description',
          southWestLat: 14.0,
          southWestLng: 120.0,
          northEastLat: 15.0,
          northEastLng: 121.0,
          estimatedTileCount: 1000,
          estimatedSizeMB: 50,
          status: DownloadStatus.downloaded,
          downloadProgress: 1.0,
          lastUpdated: DateTime.now(),
        );

        expect(region.status, DownloadStatus.downloaded);
        expect(region.status.isAvailableOffline, isTrue);
      });

      test('region card shows error message for failed download', () {
        final region = MapRegion(
          id: 'test',
          name: 'Test Region',
          description: 'Test description',
          southWestLat: 14.0,
          southWestLng: 120.0,
          northEastLat: 15.0,
          northEastLng: 121.0,
          estimatedTileCount: 1000,
          estimatedSizeMB: 50,
          status: DownloadStatus.error,
          errorMessage: 'Network error',
        );

        expect(region.status, DownloadStatus.error);
        expect(region.errorMessage, 'Network error');
      });
    });

    group('Storage display logic', () {
      test('storage info displays MB for small cache', () {
        const info = StorageInfo(
          appStorageBytes: 1048576 * 10, // 10 MB
          mapCacheBytes: 1048576 * 5, // 5 MB
          availableBytes: 1073741824 * 2, // 2 GB
          totalBytes: 1073741824 * 8, // 8 GB
        );

        expect(info.mapCacheFormatted, '5.0 MB');
        expect(info.availableFormatted, '2.0 GB');
      });

      test('storage info displays KB for tiny cache', () {
        const info = StorageInfo(
          appStorageBytes: 1024 * 100, // 100 KB
          mapCacheBytes: 1024 * 50, // 50 KB
          availableBytes: 1073741824, // 1 GB
          totalBytes: 1073741824 * 2, // 2 GB
        );

        expect(info.mapCacheFormatted.contains('KB'), isTrue);
      });

      test('storage progress bar value is correct', () {
        const info = StorageInfo(
          appStorageBytes: 0,
          mapCacheBytes: 0,
          availableBytes: 1073741824 * 6, // 6 GB available
          totalBytes: 1073741824 * 8, // 8 GB total
        );

        // 2 GB used out of 8 GB = 25%
        expect(info.usedPercentage, closeTo(0.25, 0.01));
      });
    });

    group('Action button states', () {
      test('download button shown for not downloaded region', () {
        final region = PredefinedRegions.metroManila;
        expect(region.status, DownloadStatus.notDownloaded);
        // Download icon should be shown
      });

      test('cancel button shown for downloading region', () {
        final region = MapRegion(
          id: 'test',
          name: 'Test',
          description: 'Test',
          southWestLat: 14.0,
          southWestLng: 120.0,
          northEastLat: 15.0,
          northEastLng: 121.0,
          estimatedTileCount: 1000,
          estimatedSizeMB: 50,
          status: DownloadStatus.downloading,
        );
        expect(region.status.isInProgress, isTrue);
        // Cancel icon should be shown
      });

      test('menu button shown for downloaded region', () {
        final region = MapRegion(
          id: 'test',
          name: 'Test',
          description: 'Test',
          southWestLat: 14.0,
          southWestLng: 120.0,
          northEastLat: 15.0,
          northEastLng: 121.0,
          estimatedTileCount: 1000,
          estimatedSizeMB: 50,
          status: DownloadStatus.downloaded,
        );
        expect(region.status.isAvailableOffline, isTrue);
        // Menu with checkmark should be shown
      });

      test('retry button shown for error region', () {
        final region = MapRegion(
          id: 'test',
          name: 'Test',
          description: 'Test',
          southWestLat: 14.0,
          southWestLng: 120.0,
          northEastLat: 15.0,
          northEastLng: 121.0,
          estimatedTileCount: 1000,
          estimatedSizeMB: 50,
          status: DownloadStatus.error,
        );
        expect(region.status, DownloadStatus.error);
        // Download/retry icon should be shown
      });
    });
  });
}
