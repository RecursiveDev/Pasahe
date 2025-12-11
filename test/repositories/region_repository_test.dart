import 'package:flutter_test/flutter_test.dart';
import 'package:ph_fare_calculator/src/models/map_region.dart';

void main() {
  group('RegionRepository - Model Integration', () {
    // Note: Full repository tests require flutter test with asset loading
    // These tests focus on the model parsing logic used by the repository

    group('JSON parsing', () {
      test('parses island group from JSON correctly', () {
        final json = {
          'id': 'luzon',
          'name': 'Luzon',
          'description':
              'Luzon island group - the largest and most populous island group',
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
        expect(region.isParent, isTrue);
        expect(region.hasParent, isFalse);
      });

      test('parses island with parent from JSON correctly', () {
        final json = {
          'id': 'palawan',
          'name': 'Palawan',
          'description': 'Palawan province - includes Puerto Princesa',
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
        expect(region.isChild, isTrue);
        expect(region.hasParent, isTrue);
      });

      test('handles missing optional fields with defaults', () {
        final json = {
          'id': 'test',
          'name': 'Test Region',
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

    group('filtering by type', () {
      late List<MapRegion> allRegions;

      setUp(() {
        allRegions = [
          MapRegion(
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
            priority: 1,
          ),
          MapRegion(
            id: 'visayas',
            name: 'Visayas',
            description: 'Visayas group',
            southWestLat: 9.0,
            southWestLng: 121.0,
            northEastLat: 13.0,
            northEastLng: 126.2,
            estimatedTileCount: 35000,
            estimatedSizeMB: 350,
            type: RegionType.islandGroup,
            priority: 2,
          ),
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
          MapRegion(
            id: 'cebu',
            name: 'Cebu',
            description: 'Cebu island',
            southWestLat: 9.40,
            southWestLng: 123.20,
            northEastLat: 11.40,
            northEastLng: 124.10,
            estimatedTileCount: 6500,
            estimatedSizeMB: 65,
            type: RegionType.island,
            parentId: 'visayas',
            priority: 3,
          ),
        ];
      });

      test('filters island groups correctly', () {
        final islandGroups =
            allRegions.where((r) => r.type == RegionType.islandGroup).toList();

        expect(islandGroups.length, 2);
        expect(islandGroups.map((r) => r.id), containsAll(['luzon', 'visayas']));
      });

      test('filters islands for parent correctly', () {
        final luzonIslands =
            allRegions.where((r) => r.parentId == 'luzon').toList();

        expect(luzonIslands.length, 2);
        expect(
          luzonIslands.map((r) => r.id),
          containsAll(['luzon_main', 'palawan']),
        );
      });

      test('sorts by priority correctly', () {
        final islandGroups =
            allRegions.where((r) => r.type == RegionType.islandGroup).toList()
              ..sort((a, b) => a.priority.compareTo(b.priority));

        expect(islandGroups[0].id, 'luzon');
        expect(islandGroups[1].id, 'visayas');
      });

      test('finds region by id', () {
        MapRegion? findById(String id) {
          try {
            return allRegions.firstWhere((r) => r.id == id);
          } catch (_) {
            return null;
          }
        }

        final luzon = findById('luzon');
        expect(luzon, isNotNull);
        expect(luzon!.name, 'Luzon');

        final unknown = findById('unknown');
        expect(unknown, isNull);
      });
    });

    group('hierarchical calculations', () {
      late List<MapRegion> regions;

      setUp(() {
        regions = [
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
      });

      test('calculates total size for group', () {
        final luzonIslands =
            regions.where((r) => r.parentId == 'luzon').toList();
        final totalSize =
            luzonIslands.fold<int>(0, (sum, r) => sum + r.estimatedSizeMB);

        expect(totalSize, 680);
      });

      test('calculates total tile count for group', () {
        final luzonIslands =
            regions.where((r) => r.parentId == 'luzon').toList();
        final totalTiles =
            luzonIslands.fold<int>(0, (sum, r) => sum + r.estimatedTileCount);

        expect(totalTiles, 68000);
      });
    });

    group('sample regions.json structure', () {
      test('full JSON array parsing simulation', () {
        final jsonList = [
          {
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
          },
          {
            'id': 'luzon_main',
            'name': 'Luzon Main Island',
            'description': 'Main island of Luzon',
            'type': 'island',
            'parentId': 'luzon',
            'bounds': {
              'southWestLat': 12.50,
              'southWestLng': 119.50,
              'northEastLat': 18.70,
              'northEastLng': 124.50,
            },
            'minZoom': 8,
            'maxZoom': 14,
            'estimatedSizeMB': 450,
            'estimatedTileCount': 45000,
            'priority': 1,
          },
          {
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
          },
        ];

        final regions = jsonList
            .map((json) => MapRegion.fromJson(json as Map<String, dynamic>))
            .toList();

        expect(regions.length, 3);

        // Island groups
        final groups =
            regions.where((r) => r.type == RegionType.islandGroup).toList();
        expect(groups.length, 1);
        expect(groups.first.id, 'luzon');

        // Islands for Luzon
        final luzonIslands =
            regions.where((r) => r.parentId == 'luzon').toList();
        expect(luzonIslands.length, 2);

        // Check hierarchy
        for (final island in luzonIslands) {
          expect(island.isChild, isTrue);
          expect(island.hasParent, isTrue);
        }
      });
    });
  });
}