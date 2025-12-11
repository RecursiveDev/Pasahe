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

    group('Hierarchical region display logic', () {
      test('island group contains multiple islands', () {
        final group = MapRegion(
          id: 'luzon',
          name: 'Luzon',
          description: 'Luzon island group',
          southWestLat: 7.5,
          southWestLng: 116.9,
          northEastLat: 21.2,
          northEastLng: 124.6,
          estimatedTileCount: 80000,
          estimatedSizeMB: 800,
          type: RegionType.islandGroup,
          priority: 1,
        );

        final islands = [
          MapRegion(
            id: 'luzon_main',
            name: 'Luzon Main Island',
            description: 'Main island',
            southWestLat: 12.5,
            southWestLng: 119.5,
            northEastLat: 18.7,
            northEastLng: 124.5,
            estimatedTileCount: 45000,
            estimatedSizeMB: 450,
            type: RegionType.island,
            parentId: 'luzon',
            priority: 1,
          ),
          MapRegion(
            id: 'palawan',
            name: 'Palawan',
            description: 'Palawan province',
            southWestLat: 8.30,
            southWestLng: 116.90,
            northEastLat: 12.50,
            northEastLng: 120.40,
            estimatedTileCount: 15000,
            estimatedSizeMB: 150,
            type: RegionType.island,
            parentId: 'luzon',
            priority: 3,
          ),
        ];

        expect(group.isParent, isTrue);
        expect(islands.every((i) => i.parentId == group.id), isTrue);
        expect(islands.every((i) => i.isChild), isTrue);
      });

      test('calculates total size for island group', () {
        final islands = [
          MapRegion(
            id: 'luzon_main',
            name: 'Luzon Main Island',
            description: 'Main island',
            southWestLat: 12.5,
            southWestLng: 119.5,
            northEastLat: 18.7,
            northEastLng: 124.5,
            estimatedTileCount: 45000,
            estimatedSizeMB: 450,
            type: RegionType.island,
            parentId: 'luzon',
          ),
          MapRegion(
            id: 'palawan',
            name: 'Palawan',
            description: 'Palawan province',
            southWestLat: 8.30,
            southWestLng: 116.90,
            northEastLat: 12.50,
            northEastLng: 120.40,
            estimatedTileCount: 15000,
            estimatedSizeMB: 150,
            type: RegionType.island,
            parentId: 'luzon',
          ),
          MapRegion(
            id: 'mindoro',
            name: 'Mindoro',
            description: 'Mindoro island',
            southWestLat: 12.10,
            southWestLng: 120.20,
            northEastLat: 13.60,
            northEastLng: 121.60,
            estimatedTileCount: 8000,
            estimatedSizeMB: 80,
            type: RegionType.island,
            parentId: 'luzon',
          ),
        ];

        final totalSize = islands.fold<int>(0, (sum, i) => sum + i.estimatedSizeMB);
        expect(totalSize, 680);
      });

      test('counts downloaded islands in group', () {
        final islands = [
          MapRegion(
            id: 'luzon_main',
            name: 'Luzon Main Island',
            description: 'Main island',
            southWestLat: 12.5,
            southWestLng: 119.5,
            northEastLat: 18.7,
            northEastLng: 124.5,
            estimatedTileCount: 45000,
            estimatedSizeMB: 450,
            type: RegionType.island,
            parentId: 'luzon',
            status: DownloadStatus.downloaded,
          ),
          MapRegion(
            id: 'palawan',
            name: 'Palawan',
            description: 'Palawan province',
            southWestLat: 8.30,
            southWestLng: 116.90,
            northEastLat: 12.50,
            northEastLng: 120.40,
            estimatedTileCount: 15000,
            estimatedSizeMB: 150,
            type: RegionType.island,
            parentId: 'luzon',
            status: DownloadStatus.notDownloaded,
          ),
          MapRegion(
            id: 'mindoro',
            name: 'Mindoro',
            description: 'Mindoro island',
            southWestLat: 12.10,
            southWestLng: 120.20,
            northEastLat: 13.60,
            northEastLng: 121.60,
            estimatedTileCount: 8000,
            estimatedSizeMB: 80,
            type: RegionType.island,
            parentId: 'luzon',
            status: DownloadStatus.downloaded,
          ),
        ];

        final downloadedCount = islands.where((i) => i.status.isAvailableOffline).length;
        expect(downloadedCount, 2);

        final allDownloaded = islands.every((i) => i.status.isAvailableOffline);
        expect(allDownloaded, isFalse);

        final partiallyDownloaded = downloadedCount > 0 && !allDownloaded;
        expect(partiallyDownloaded, isTrue);
      });

      test('determines group status from children', () {
        // All downloaded
        final allDownloadedIslands = [
          MapRegion(
            id: 'island1',
            name: 'Island 1',
            description: '',
            southWestLat: 10.0,
            southWestLng: 120.0,
            northEastLat: 11.0,
            northEastLng: 121.0,
            estimatedTileCount: 1000,
            estimatedSizeMB: 10,
            type: RegionType.island,
            parentId: 'group',
            status: DownloadStatus.downloaded,
          ),
          MapRegion(
            id: 'island2',
            name: 'Island 2',
            description: '',
            southWestLat: 11.0,
            southWestLng: 121.0,
            northEastLat: 12.0,
            northEastLng: 122.0,
            estimatedTileCount: 1000,
            estimatedSizeMB: 10,
            type: RegionType.island,
            parentId: 'group',
            status: DownloadStatus.downloaded,
          ),
        ];

        expect(
          allDownloadedIslands.every((i) => i.status == DownloadStatus.downloaded),
          isTrue,
        );

        // Any downloading
        final mixedIslands = [
          MapRegion(
            id: 'island1',
            name: 'Island 1',
            description: '',
            southWestLat: 10.0,
            southWestLng: 120.0,
            northEastLat: 11.0,
            northEastLng: 121.0,
            estimatedTileCount: 1000,
            estimatedSizeMB: 10,
            type: RegionType.island,
            parentId: 'group',
            status: DownloadStatus.downloaded,
          ),
          MapRegion(
            id: 'island2',
            name: 'Island 2',
            description: '',
            southWestLat: 11.0,
            southWestLng: 121.0,
            northEastLat: 12.0,
            northEastLng: 122.0,
            estimatedTileCount: 1000,
            estimatedSizeMB: 10,
            type: RegionType.island,
            parentId: 'group',
            status: DownloadStatus.downloading,
          ),
        ];

        expect(
          mixedIslands.any((i) => i.status == DownloadStatus.downloading),
          isTrue,
        );
      });

      test('sorts islands by priority', () {
        final islands = [
          MapRegion(
            id: 'island3',
            name: 'Third Island',
            description: '',
            southWestLat: 10.0,
            southWestLng: 120.0,
            northEastLat: 11.0,
            northEastLng: 121.0,
            estimatedTileCount: 1000,
            estimatedSizeMB: 10,
            type: RegionType.island,
            parentId: 'group',
            priority: 3,
          ),
          MapRegion(
            id: 'island1',
            name: 'First Island',
            description: '',
            southWestLat: 11.0,
            southWestLng: 121.0,
            northEastLat: 12.0,
            northEastLng: 122.0,
            estimatedTileCount: 1000,
            estimatedSizeMB: 10,
            type: RegionType.island,
            parentId: 'group',
            priority: 1,
          ),
          MapRegion(
            id: 'island2',
            name: 'Second Island',
            description: '',
            southWestLat: 12.0,
            southWestLng: 122.0,
            northEastLat: 13.0,
            northEastLng: 123.0,
            estimatedTileCount: 1000,
            estimatedSizeMB: 10,
            type: RegionType.island,
            parentId: 'group',
            priority: 2,
          ),
        ];

        islands.sort((a, b) => a.priority.compareTo(b.priority));

        expect(islands[0].id, 'island1');
        expect(islands[1].id, 'island2');
        expect(islands[2].id, 'island3');
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
        final region = PredefinedRegions.luzon;
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

    group('Island group action button states', () {
      test('download all button shown for group with no downloads', () {
        final islands = [
          MapRegion(
            id: 'island1',
            name: 'Island 1',
            description: '',
            southWestLat: 10.0,
            southWestLng: 120.0,
            northEastLat: 11.0,
            northEastLng: 121.0,
            estimatedTileCount: 1000,
            estimatedSizeMB: 10,
            type: RegionType.island,
            parentId: 'group',
            status: DownloadStatus.notDownloaded,
          ),
          MapRegion(
            id: 'island2',
            name: 'Island 2',
            description: '',
            southWestLat: 11.0,
            southWestLng: 121.0,
            northEastLat: 12.0,
            northEastLng: 122.0,
            estimatedTileCount: 1000,
            estimatedSizeMB: 10,
            type: RegionType.island,
            parentId: 'group',
            status: DownloadStatus.notDownloaded,
          ),
        ];

        final downloadedCount = islands.where((i) => i.status.isAvailableOffline).length;
        final allDownloaded = downloadedCount == islands.length;
        final partiallyDownloaded = downloadedCount > 0 && !allDownloaded;

        expect(allDownloaded, isFalse);
        expect(partiallyDownloaded, isFalse);
        // "Download" button should be shown
      });

      test('complete button shown for partially downloaded group', () {
        final islands = [
          MapRegion(
            id: 'island1',
            name: 'Island 1',
            description: '',
            southWestLat: 10.0,
            southWestLng: 120.0,
            northEastLat: 11.0,
            northEastLng: 121.0,
            estimatedTileCount: 1000,
            estimatedSizeMB: 10,
            type: RegionType.island,
            parentId: 'group',
            status: DownloadStatus.downloaded,
          ),
          MapRegion(
            id: 'island2',
            name: 'Island 2',
            description: '',
            southWestLat: 11.0,
            southWestLng: 121.0,
            northEastLat: 12.0,
            northEastLng: 122.0,
            estimatedTileCount: 1000,
            estimatedSizeMB: 10,
            type: RegionType.island,
            parentId: 'group',
            status: DownloadStatus.notDownloaded,
          ),
        ];

        final downloadedCount = islands.where((i) => i.status.isAvailableOffline).length;
        final allDownloaded = downloadedCount == islands.length;
        final partiallyDownloaded = downloadedCount > 0 && !allDownloaded;

        expect(allDownloaded, isFalse);
        expect(partiallyDownloaded, isTrue);
        // "Complete" button should be shown
      });

      test('delete all button shown for fully downloaded group', () {
        final islands = [
          MapRegion(
            id: 'island1',
            name: 'Island 1',
            description: '',
            southWestLat: 10.0,
            southWestLng: 120.0,
            northEastLat: 11.0,
            northEastLng: 121.0,
            estimatedTileCount: 1000,
            estimatedSizeMB: 10,
            type: RegionType.island,
            parentId: 'group',
            status: DownloadStatus.downloaded,
          ),
          MapRegion(
            id: 'island2',
            name: 'Island 2',
            description: '',
            southWestLat: 11.0,
            southWestLng: 121.0,
            northEastLat: 12.0,
            northEastLng: 122.0,
            estimatedTileCount: 1000,
            estimatedSizeMB: 10,
            type: RegionType.island,
            parentId: 'group',
            status: DownloadStatus.downloaded,
          ),
        ];

        final downloadedCount = islands.where((i) => i.status.isAvailableOffline).length;
        final allDownloaded = downloadedCount == islands.length;

        expect(allDownloaded, isTrue);
        // Menu with "Delete All" should be shown
      });
    });
  });
}