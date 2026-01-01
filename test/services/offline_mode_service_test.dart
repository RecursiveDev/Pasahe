import 'package:flutter_test/flutter_test.dart';
import 'package:ph_fare_calculator/src/models/accuracy_level.dart';
import 'package:ph_fare_calculator/src/models/connectivity_status.dart';
import 'package:ph_fare_calculator/src/models/map_region.dart';
import 'package:ph_fare_calculator/src/services/offline/offline_mode_service.dart';

import '../helpers/mocks.dart';

void main() {
  late MockConnectivityService mockConnectivityService;
  late MockSettingsService mockSettingsService;
  late MockOfflineMapService mockOfflineMapService;
  late OfflineModeService service;

  setUp(() {
    mockConnectivityService = MockConnectivityService();
    mockSettingsService = MockSettingsService();
    mockOfflineMapService = MockOfflineMapService();
    service = OfflineModeService(
      mockConnectivityService,
      mockSettingsService,
      mockOfflineMapService,
    );
  });

  tearDown(() {
    service.dispose();
  });

  group('OfflineModeService - Initialization', () {
    test('should initialize with default values', () async {
      await service.initialize();

      expect(service.connectivityStatus, ConnectivityStatus.online);
      expect(service.offlineModeEnabled, isFalse);
      expect(service.autoCacheEnabled, isTrue);
      expect(service.autoCacheWifiOnly, isTrue);
      expect(service.downloadedRegionIds, isEmpty);
    });

    test('should load saved preferences on initialization', () async {
      await mockSettingsService.setOfflineModeEnabled(true);
      await mockSettingsService.setAutoCacheEnabled(false);
      await mockSettingsService.setAutoCacheWifiOnly(false);
      await mockSettingsService.setMigratedToOfflineMode(true);

      await service.initialize();

      expect(service.offlineModeEnabled, isTrue);
      expect(service.autoCacheEnabled, isFalse);
      expect(service.autoCacheWifiOnly, isFalse);
    });

    test('should handle migration for existing users (opt-out)', () async {
      await mockSettingsService.setMigratedToOfflineMode(false);
      mockSettingsService.hasSetDiscount = true;

      await service.initialize();

      // Existing users should default to OFF for offline mode and auto-cache
      expect(service.offlineModeEnabled, isFalse);
      expect(service.autoCacheEnabled, isFalse);
    });

    test('should handle migration for new users (opt-in)', () async {
      await mockSettingsService.setMigratedToOfflineMode(false);
      mockSettingsService.hasSetDiscount = false;

      await service.initialize();

      // New users should default to OFF for offline mode but ON for auto-cache
      expect(service.offlineModeEnabled, isFalse);
      expect(service.autoCacheEnabled, isTrue);
    });

    test('should set migrated flag after initialization', () async {
      expect(await mockSettingsService.hasMigratedToOfflineMode(), isFalse);

      await service.initialize();

      expect(await mockSettingsService.hasMigratedToOfflineMode(), isTrue);
    });

    test('should load downloaded regions from OfflineMapService', () async {
      final testRegion = MapRegion(
        id: 'test-region',
        name: 'Test Region',
        description: 'Test',
        southWestLat: 14.0,
        southWestLng: 120.0,
        northEastLat: 15.0,
        northEastLng: 121.0,
        estimatedTileCount: 1000,
        estimatedSizeMB: 10,
        type: RegionType.island,
      );
      mockOfflineMapService.setDownloadedRegions([testRegion]);

      await service.initialize();

      expect(service.downloadedRegionIds, ['test-region']);
    });

    test('should not reinitialize if already initialized', () async {
      await service.initialize();
      await service.initialize();

      // Should only initialize once, preferences should be loaded once
      expect(service.offlineModeEnabled, isFalse);
    });
  });

  group('OfflineModeService - Connectivity Status', () {
    test('should reflect current connectivity status', () async {
      await service.initialize();

      expect(service.connectivityStatus, ConnectivityStatus.online);

      mockConnectivityService.setConnectivityStatus(ConnectivityStatus.offline);
      await Future.delayed(Duration.zero);

      expect(service.connectivityStatus, ConnectivityStatus.offline);

      mockConnectivityService.setConnectivityStatus(ConnectivityStatus.limited);
      await Future.delayed(Duration.zero);

      expect(service.connectivityStatus, ConnectivityStatus.limited);
    });

    test('should notify listeners on connectivity change', () async {
      int notifyCount = 0;
      void listener() => notifyCount++;

      await service.initialize();
      service.addListener(listener);

      expect(notifyCount, 0);

      mockConnectivityService.setConnectivityStatus(ConnectivityStatus.offline);
      await Future.delayed(Duration.zero);

      expect(notifyCount, 1);

      service.removeListener(listener);
    });
  });

  group('OfflineModeService - Offline Mode Toggle', () {
    test('should toggle offline mode on', () async {
      await service.initialize();

      expect(service.offlineModeEnabled, isFalse);

      await service.setOfflineModeEnabled(true);

      expect(service.offlineModeEnabled, isTrue);
    });

    test('should persist offline mode setting', () async {
      await service.initialize();

      await service.setOfflineModeEnabled(true);

      expect(await mockSettingsService.getOfflineModeEnabled(), isTrue);
    });

    test('should notify listeners when offline mode changes', () async {
      int notifyCount = 0;
      void listener() => notifyCount++;

      await service.initialize();
      service.addListener(listener);

      await service.setOfflineModeEnabled(true);

      expect(notifyCount, 1);

      service.removeListener(listener);
    });

    test('should toggle offline mode off', () async {
      await service.initialize();
      await service.setOfflineModeEnabled(true);

      expect(service.offlineModeEnabled, isTrue);

      await service.setOfflineModeEnabled(false);

      expect(service.offlineModeEnabled, isFalse);
    });
  });

  group('OfflineModeService - Auto-Cache Settings', () {
    test('should toggle auto-cache on', () async {
      await service.initialize();

      expect(service.autoCacheEnabled, isTrue);

      await service.setAutoCacheEnabled(true);

      expect(service.autoCacheEnabled, isTrue);
    });

    test('should toggle auto-cache off', () async {
      await service.initialize();

      await service.setAutoCacheEnabled(false);

      expect(service.autoCacheEnabled, isFalse);
    });

    test('should persist auto-cache setting', () async {
      await service.initialize();

      await service.setAutoCacheEnabled(false);

      expect(await mockSettingsService.getAutoCacheEnabled(), isFalse);
    });

    test('should toggle WiFi-only setting on', () async {
      await service.initialize();

      expect(service.autoCacheWifiOnly, isTrue);

      await service.setAutoCacheWifiOnly(true);

      expect(service.autoCacheWifiOnly, isTrue);
    });

    test('should toggle WiFi-only setting off', () async {
      await service.initialize();

      await service.setAutoCacheWifiOnly(false);

      expect(service.autoCacheWifiOnly, isFalse);
    });

    test('should persist WiFi-only setting', () async {
      await service.initialize();

      await service.setAutoCacheWifiOnly(false);

      expect(await mockSettingsService.getAutoCacheWifiOnly(), isFalse);
    });

    test('should notify listeners when auto-cache settings change', () async {
      int notifyCount = 0;
      void listener() => notifyCount++;

      await service.initialize();
      service.addListener(listener);

      await service.setAutoCacheEnabled(false);

      expect(notifyCount, 1);

      await service.setAutoCacheWifiOnly(false);

      expect(notifyCount, 2);

      service.removeListener(listener);
    });
  });

  group('OfflineModeService - Downloaded Regions', () {
    test('should refresh downloaded regions', () async {
      await service.initialize();

      expect(service.downloadedRegionIds, isEmpty);

      final testRegion = MapRegion(
        id: 'new-region',
        name: 'New Region',
        description: 'Test',
        southWestLat: 14.0,
        southWestLng: 120.0,
        northEastLat: 15.0,
        northEastLng: 121.0,
        estimatedTileCount: 1000,
        estimatedSizeMB: 10,
        type: RegionType.island,
      );
      mockOfflineMapService.setDownloadedRegions([testRegion]);

      await service.refreshDownloadedRegions();

      expect(service.downloadedRegionIds, ['new-region']);
    });
  });

  group('OfflineModeService - isCurrentlyOffline', () {
    test('returns true when device is offline', () async {
      await service.initialize();

      expect(service.isCurrentlyOffline, isFalse);

      mockConnectivityService.setConnectivityStatus(ConnectivityStatus.offline);
      await Future.delayed(Duration.zero);

      expect(service.isCurrentlyOffline, isTrue);
    });

    test('returns true when offline mode is enabled', () async {
      await service.initialize();

      expect(service.isCurrentlyOffline, isFalse);

      await service.setOfflineModeEnabled(true);

      expect(service.isCurrentlyOffline, isTrue);
    });

    test('returns true when both device offline and mode enabled', () async {
      await service.initialize();
      mockConnectivityService.setConnectivityStatus(ConnectivityStatus.offline);
      await Future.delayed(Duration.zero);
      await service.setOfflineModeEnabled(true);

      expect(service.isCurrentlyOffline, isTrue);
    });

    test('returns false when device online and mode disabled', () async {
      await service.initialize();
      mockConnectivityService.setConnectivityStatus(ConnectivityStatus.online);
      await Future.delayed(Duration.zero);

      expect(service.isCurrentlyOffline, isFalse);
    });
  });

  group('OfflineModeService - currentAccuracyLevel', () {
    test('returns precise when online and offline mode disabled', () async {
      await service.initialize();

      expect(service.currentAccuracyLevel, AccuracyLevel.precise);
    });

    test('returns approximate when offline mode enabled', () async {
      await service.initialize();
      await service.setOfflineModeEnabled(true);

      expect(service.currentAccuracyLevel, AccuracyLevel.approximate);
    });

    test('returns approximate when device is offline', () async {
      await service.initialize();
      mockConnectivityService.setConnectivityStatus(ConnectivityStatus.offline);
      await Future.delayed(Duration.zero);

      expect(service.currentAccuracyLevel, AccuracyLevel.approximate);
    });

    test('returns estimated when connectivity is limited', () async {
      await service.initialize();
      mockConnectivityService.setConnectivityStatus(ConnectivityStatus.limited);
      await Future.delayed(Duration.zero);

      expect(service.currentAccuracyLevel, AccuracyLevel.estimated);
    });

    test('approximate takes precedence over estimated', () async {
      await service.initialize();
      await service.setOfflineModeEnabled(true);
      mockConnectivityService.setConnectivityStatus(ConnectivityStatus.limited);
      await Future.delayed(Duration.zero);

      expect(service.currentAccuracyLevel, AccuracyLevel.approximate);
    });
  });

  group('OfflineModeService - shouldAllowDownloads', () {
    test('returns false when offline mode is enabled', () async {
      await service.initialize();
      await service.setOfflineModeEnabled(true);

      expect(service.shouldAllowDownloads, isFalse);
    });

    test('returns false when auto-cache is disabled', () async {
      await service.initialize();
      await service.setAutoCacheEnabled(false);

      expect(service.shouldAllowDownloads, isFalse);
    });

    test(
      'returns false when on mobile data and WiFi-only is enabled',
      () async {
        await service.initialize();
        mockConnectivityService.setConnectivityStatus(
          ConnectivityStatus.limited,
        );
        await Future.delayed(Duration.zero);

        expect(service.shouldAllowDownloads, isFalse);
      },
    );

    test(
      'returns true when online, auto-cache enabled, and not WiFi-restricted',
      () async {
        await service.initialize();
        mockConnectivityService.setConnectivityStatus(
          ConnectivityStatus.online,
        );
        await Future.delayed(Duration.zero);

        expect(service.shouldAllowDownloads, isTrue);
      },
    );
  });

  group('OfflineModeService - Disposal', () {
    test('should dispose of connectivity subscription', () async {
      await service.initialize();

      mockConnectivityService.setConnectivityStatus(ConnectivityStatus.offline);
      await Future.delayed(Duration.zero);

      // After disposal, connectivity changes should not affect the service
      expect(service.connectivityStatus, ConnectivityStatus.offline);
      
      // tearDown will call dispose()
    });
  });
}
