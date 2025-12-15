import 'package:flutter_test/flutter_test.dart';
import 'package:ph_fare_calculator/src/models/map_region.dart';

void main() {
  group('OfflineMapService - PredefinedRegions', () {
    test('Luzon region has valid bounds', () {
      final region = PredefinedRegions.luzon;

      // Check that bounds are valid
      expect(region.southWestLat, lessThan(region.northEastLat));
      expect(region.southWestLng, lessThan(region.northEastLng));

      // Check reasonable bounds for Luzon (Updated for full coverage including Palawan and Batanes)
      expect(region.southWestLat, greaterThan(7.0));
      expect(region.northEastLat, lessThan(22.0));
    });

    test('Visayas region has valid bounds', () {
      final region = PredefinedRegions.visayas;

      expect(region.southWestLat, lessThan(region.northEastLat));
      expect(region.southWestLng, lessThan(region.northEastLng));

      // Check reasonable bounds for Visayas
      expect(region.southWestLat, greaterThanOrEqualTo(9.0));
      expect(region.northEastLat, lessThanOrEqualTo(13.0));
    });

    test('Mindanao region has valid bounds', () {
      final region = PredefinedRegions.mindanao;

      expect(region.southWestLat, lessThan(region.northEastLat));
      expect(region.southWestLng, lessThan(region.northEastLng));

      // Check reasonable bounds for Mindanao (Updated for Tawi-Tawi)
      expect(region.southWestLat, greaterThanOrEqualTo(4.0));
      expect(region.northEastLat, lessThan(11.0));
    });

    test('All predefined regions are island groups', () {
      for (final region in PredefinedRegions.all) {
        expect(region.type, RegionType.islandGroup);
      }
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

    test('All regions have priority set', () {
      expect(PredefinedRegions.luzon.priority, 1);
      expect(PredefinedRegions.visayas.priority, 2);
      expect(PredefinedRegions.mindanao.priority, 3);
    });
  });

  group('RegionDownloadProgress', () {
    test('progress calculation is correct', () {
      final region = PredefinedRegions.luzon;
      final progress = RegionDownloadProgress(
        region: region,
        tilesDownloaded: 25000,
        totalTiles: 50000,
      );

      expect(progress.progress, 0.5);
      expect(progress.percentage, 50);
    });

    test('complete progress shows 100%', () {
      final region = PredefinedRegions.luzon;
      final progress = RegionDownloadProgress(
        region: region,
        tilesDownloaded: 50000,
        totalTiles: 50000,
        isComplete: true,
      );

      expect(progress.progress, 1.0);
      expect(progress.percentage, 100);
      expect(progress.isComplete, isTrue);
    });

    test('error handling works correctly', () {
      final region = PredefinedRegions.luzon;
      final progress = RegionDownloadProgress(
        region: region,
        tilesDownloaded: 10000,
        totalTiles: 50000,
        errorMessage: 'Network error',
      );

      expect(progress.hasError, isTrue);
      expect(progress.errorMessage, 'Network error');
    });
  });

  group('GroupDownloadProgress', () {
    test('tracks multiple children', () {
      final group = MapRegion(
        id: 'luzon',
        name: 'Luzon',
        description: 'Luzon group',
        southWestLat: 7.5,
        southWestLng: 116.9,
        northEastLat: 21.2,
        northEastLng: 124.6,
        estimatedTileCount: 80000,
        estimatedSizeMB: 800,
        type: RegionType.islandGroup,
      );

      final child1 = MapRegion(
        id: 'palawan',
        name: 'Palawan',
        description: 'Palawan',
        southWestLat: 8.0,
        southWestLng: 117.0,
        northEastLat: 12.0,
        northEastLng: 120.0,
        estimatedTileCount: 15000,
        estimatedSizeMB: 150,
        type: RegionType.island,
        parentId: 'luzon',
      );

      final child2 = MapRegion(
        id: 'mindoro',
        name: 'Mindoro',
        description: 'Mindoro',
        southWestLat: 12.0,
        southWestLng: 120.0,
        northEastLat: 13.0,
        northEastLng: 121.0,
        estimatedTileCount: 8000,
        estimatedSizeMB: 80,
        type: RegionType.island,
        parentId: 'luzon',
      );

      final progress = GroupDownloadProgress(
        region: group,
        tilesDownloaded: 15000,
        totalTiles: 23000,
        children: [child1, child2],
        currentChild: child2,
        currentChildIndex: 1,
      );

      expect(progress.children.length, 2);
      expect(progress.currentChild?.id, 'mindoro');
      expect(progress.currentChildIndex, 1);
      expect(progress.progressMessage, 'Downloading Mindoro (2/2)');
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

  group('MapRegion hierarchical relationships', () {
    test('island group has no parent', () {
      final group = MapRegion(
        id: 'luzon',
        name: 'Luzon',
        description: 'Luzon group',
        southWestLat: 7.5,
        southWestLng: 116.9,
        northEastLat: 21.2,
        northEastLng: 124.6,
        estimatedTileCount: 80000,
        estimatedSizeMB: 800,
        type: RegionType.islandGroup,
      );

      expect(group.isParent, isTrue);
      expect(group.hasParent, isFalse);
      expect(group.parentId, isNull);
    });

    test('island has parent reference', () {
      final island = MapRegion(
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
      );

      expect(island.isChild, isTrue);
      expect(island.hasParent, isTrue);
      expect(island.parentId, 'luzon');
    });

    test('island group contains multiple islands conceptually', () {
      final islands = [
        MapRegion(
          id: 'palawan',
          name: 'Palawan',
          description: 'Palawan',
          southWestLat: 8.0,
          southWestLng: 117.0,
          northEastLat: 12.0,
          northEastLng: 120.0,
          estimatedTileCount: 15000,
          estimatedSizeMB: 150,
          type: RegionType.island,
          parentId: 'luzon',
          priority: 1,
        ),
        MapRegion(
          id: 'mindoro',
          name: 'Mindoro',
          description: 'Mindoro',
          southWestLat: 12.0,
          southWestLng: 120.0,
          northEastLat: 13.0,
          northEastLng: 121.0,
          estimatedTileCount: 8000,
          estimatedSizeMB: 80,
          type: RegionType.island,
          parentId: 'luzon',
          priority: 2,
        ),
      ];

      // Filter by parentId
      final luzonIslands = islands.where((i) => i.parentId == 'luzon').toList();
      expect(luzonIslands.length, 2);

      // Sort by priority
      luzonIslands.sort((a, b) => a.priority.compareTo(b.priority));
      expect(luzonIslands.first.id, 'palawan');
      expect(luzonIslands.last.id, 'mindoro');
    });
  });
}
