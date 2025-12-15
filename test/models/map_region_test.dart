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

  group('RegionType', () {
    test('isParent returns true for islandGroup', () {
      expect(RegionType.islandGroup.isParent, isTrue);
      expect(RegionType.islandGroup.isChild, isFalse);
    });

    test('isChild returns true for island', () {
      expect(RegionType.island.isChild, isTrue);
      expect(RegionType.island.isParent, isFalse);
    });

    test('label returns correct string for each type', () {
      expect(RegionType.islandGroup.label, 'Island Group');
      expect(RegionType.island.label, 'Island');
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

    test('default type is island', () {
      expect(region.type, RegionType.island);
    });

    test('default priority is 100', () {
      expect(region.priority, 100);
    });

    test('default parentId is null', () {
      expect(region.parentId, isNull);
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

    test('isParent returns true for islandGroup type', () {
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
      );
      expect(group.isParent, isTrue);
      expect(group.isChild, isFalse);
    });

    test('isChild returns true for island type with parent', () {
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
      expect(island.isParent, isFalse);
      expect(island.hasParent, isTrue);
    });

    test('hasParent returns false when parentId is null', () {
      expect(region.hasParent, isFalse);
    });

    test('copyWith creates a new instance with updated values', () {
      final updated = region.copyWith(
        name: 'Updated Name',
        status: DownloadStatus.downloaded,
        downloadProgress: 1.0,
        type: RegionType.islandGroup,
        parentId: 'luzon',
        priority: 5,
      );

      expect(updated.id, region.id);
      expect(updated.name, 'Updated Name');
      expect(updated.status, DownloadStatus.downloaded);
      expect(updated.downloadProgress, 1.0);
      expect(updated.description, region.description);
      expect(updated.type, RegionType.islandGroup);
      expect(updated.parentId, 'luzon');
      expect(updated.priority, 5);
    });

    test('toString returns expected format with type', () {
      expect(
        region.toString(),
        'MapRegion(id: test_region, name: Test Region, type: Island, status: Not downloaded)',
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

  group('MapRegion.fromJson', () {
    test('parses island_group type correctly', () {
      final json = {
        'id': 'luzon',
        'name': 'Luzon',
        'description': 'Luzon island group',
        'type': 'island_group',
        'parentId': null,
        'bounds': {
          'southWestLat': 8.30,
          'southWestLng': 116.90,
          'northEastLat': 21.20,
          'northEastLng': 124.60,
        },
        'minZoom': 8,
        'maxZoom': 14,
        'estimatedSizeMB': 800,
        'estimatedTileCount': 80000,
        'priority': 1,
      };

      final region = MapRegion.fromJson(json);

      expect(region.id, 'luzon');
      expect(region.name, 'Luzon');
      expect(region.type, RegionType.islandGroup);
      expect(region.parentId, isNull);
      expect(region.priority, 1);
      expect(region.southWestLat, 8.30);
      expect(region.southWestLng, 116.90);
      expect(region.northEastLat, 21.20);
      expect(region.northEastLng, 124.60);
    });

    test('parses island type with parent correctly', () {
      final json = {
        'id': 'palawan',
        'name': 'Palawan',
        'description': 'Palawan province',
        'type': 'island',
        'parentId': 'luzon',
        'bounds': {
          'southWestLat': 8.30,
          'southWestLng': 116.90,
          'northEastLat': 12.50,
          'northEastLng': 120.40,
        },
        'minZoom': 8,
        'maxZoom': 14,
        'estimatedSizeMB': 150,
        'estimatedTileCount': 15000,
        'priority': 3,
      };

      final region = MapRegion.fromJson(json);

      expect(region.id, 'palawan');
      expect(region.name, 'Palawan');
      expect(region.type, RegionType.island);
      expect(region.parentId, 'luzon');
      expect(region.priority, 3);
    });

    test('uses default values for optional fields', () {
      final json = {
        'id': 'test',
        'name': 'Test',
        'bounds': {
          'southWestLat': 10.0,
          'southWestLng': 120.0,
          'northEastLat': 11.0,
          'northEastLng': 121.0,
        },
      };

      final region = MapRegion.fromJson(json);

      expect(region.description, '');
      expect(region.type, RegionType.island);
      expect(region.parentId, isNull);
      expect(region.priority, 100);
      expect(region.minZoom, 8);
      expect(region.maxZoom, 14);
      expect(region.estimatedSizeMB, 0);
      expect(region.estimatedTileCount, 0);
    });
  });

  group('MapRegion.toJson', () {
    test('serializes island_group correctly', () {
      final region = MapRegion(
        id: 'luzon',
        name: 'Luzon',
        description: 'Luzon island group',
        southWestLat: 8.30,
        southWestLng: 116.90,
        northEastLat: 21.20,
        northEastLng: 124.60,
        minZoom: 8,
        maxZoom: 14,
        estimatedTileCount: 80000,
        estimatedSizeMB: 800,
        type: RegionType.islandGroup,
        priority: 1,
      );

      final json = region.toJson();

      expect(json['id'], 'luzon');
      expect(json['name'], 'Luzon');
      expect(json['type'], 'island_group');
      expect(json['parentId'], isNull);
      expect(json['priority'], 1);
      expect(json['bounds']['southWestLat'], 8.30);
    });

    test('serializes island with parent correctly', () {
      final region = MapRegion(
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
      );

      final json = region.toJson();

      expect(json['id'], 'palawan');
      expect(json['type'], 'island');
      expect(json['parentId'], 'luzon');
      expect(json['priority'], 3);
    });

    test('roundtrip fromJson/toJson preserves data', () {
      final originalJson = {
        'id': 'test',
        'name': 'Test Region',
        'description': 'Test description',
        'type': 'island',
        'parentId': 'parent_id',
        'bounds': {
          'southWestLat': 10.0,
          'southWestLng': 120.0,
          'northEastLat': 11.0,
          'northEastLng': 121.0,
        },
        'minZoom': 8,
        'maxZoom': 14,
        'estimatedSizeMB': 100,
        'estimatedTileCount': 10000,
        'priority': 5,
      };

      final region = MapRegion.fromJson(originalJson);
      final resultJson = region.toJson();

      expect(resultJson['id'], originalJson['id']);
      expect(resultJson['name'], originalJson['name']);
      expect(resultJson['type'], originalJson['type']);
      expect(resultJson['parentId'], originalJson['parentId']);
      expect(resultJson['priority'], originalJson['priority']);
    });
  });

  group('PredefinedRegions', () {
    test('luzon has correct id and type', () {
      expect(PredefinedRegions.luzon.id, 'luzon');
      expect(PredefinedRegions.luzon.type, RegionType.islandGroup);
    });

    test('luzon has correct name', () {
      expect(PredefinedRegions.luzon.name, 'Luzon');
    });

    test('visayas has correct id and type', () {
      expect(PredefinedRegions.visayas.id, 'visayas');
      expect(PredefinedRegions.visayas.type, RegionType.islandGroup);
    });

    test('mindanao has correct id and type', () {
      expect(PredefinedRegions.mindanao.id, 'mindanao');
      expect(PredefinedRegions.mindanao.type, RegionType.islandGroup);
    });

    test('all returns list with 3 regions', () {
      expect(PredefinedRegions.all.length, 3);
    });

    test('getById returns correct region', () {
      final region = PredefinedRegions.getById('luzon');
      expect(region, isNotNull);
      expect(region!.name, 'Luzon');
    });

    test('getById returns null for unknown id', () {
      final region = PredefinedRegions.getById('unknown_region');
      expect(region, isNull);
    });

    test('all regions have priority set', () {
      expect(PredefinedRegions.luzon.priority, 1);
      expect(PredefinedRegions.visayas.priority, 2);
      expect(PredefinedRegions.mindanao.priority, 3);
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

  group('GroupDownloadProgress', () {
    late MapRegion group;
    late MapRegion child1;
    late MapRegion child2;

    setUp(() {
      group = MapRegion(
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
      );

      child1 = MapRegion(
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

      child2 = MapRegion(
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
    });

    test('progressMessage shows current child', () {
      final progress = GroupDownloadProgress(
        region: group,
        tilesDownloaded: 5000,
        totalTiles: 23000,
        children: [child1, child2],
        currentChild: child1,
        currentChildIndex: 0,
      );

      expect(progress.progressMessage, 'Downloading Palawan (1/2)');
    });

    test('progressMessage shows region name when no current child', () {
      final progress = GroupDownloadProgress(
        region: group,
        tilesDownloaded: 0,
        totalTiles: 23000,
        children: [child1, child2],
      );

      expect(progress.progressMessage, 'Downloading Luzon');
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
