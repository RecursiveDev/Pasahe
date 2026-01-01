import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';
import 'package:ph_fare_calculator/src/presentation/screens/map_picker_screen.dart';
import 'package:ph_fare_calculator/src/services/connectivity/connectivity_service.dart';
import 'package:ph_fare_calculator/src/services/geocoding/geocoding_service.dart';
import 'package:ph_fare_calculator/src/services/offline/offline_map_service.dart';
import 'package:ph_fare_calculator/src/services/offline/offline_mode_service.dart';

import '../helpers/mocks.dart';

class TestOfflineModeService extends MockOfflineModeService {
  bool _isOffline = false;

  @override
  bool get isCurrentlyOffline => _isOffline;

  void setOffline(bool value) {
    _isOffline = value;
    notifyListeners();
  }
}

class TestOfflineMapService extends MockOfflineMapService {
  bool _isCached = true;

  @override
  bool isPointCached(LatLng point) => _isCached;

  void setCached(bool value) {
    _isCached = value;
  }
}

void main() {
  late MockGeocodingService mockGeocodingService;
  late TestOfflineModeService testOfflineModeService;
  late TestOfflineMapService testOfflineMapService;
  late MockConnectivityService mockConnectivityService;

  setUp(() async {
    await GetIt.instance.reset();
    mockGeocodingService = MockGeocodingService();
    testOfflineModeService = TestOfflineModeService();
    testOfflineMapService = TestOfflineMapService();
    mockConnectivityService = MockConnectivityService();

    GetIt.instance.registerSingleton<GeocodingService>(mockGeocodingService);
    GetIt.instance.registerSingleton<OfflineModeService>(
      testOfflineModeService,
    );
    GetIt.instance.registerSingleton<OfflineMapService>(testOfflineMapService);
    GetIt.instance.registerSingleton<ConnectivityService>(
      mockConnectivityService,
    );
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets('MapPickerScreen shows search bar when online', (
    WidgetTester tester,
  ) async {
    testOfflineModeService.setOffline(false);

    await tester.pumpWidget(const MaterialApp(home: MapPickerScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Search location...'), findsOneWidget);
    expect(
      find.text('Offline Mode: Drag map to select coordinates'),
      findsNothing,
    );
  });

  testWidgets(
    'MapPickerScreen hides search bar and shows help text when offline',
    (WidgetTester tester) async {
      testOfflineModeService.setOffline(true);

      await tester.pumpWidget(const MaterialApp(home: MapPickerScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(
        find.text('Offline Mode: Drag map to select coordinates'),
        findsOneWidget,
      );
      expect(find.text('Selected Coordinates'), findsOneWidget);
    },
  );

  testWidgets('MapPickerScreen shows warning when offline and map not cached', (
    WidgetTester tester,
  ) async {
    testOfflineModeService.setOffline(true);
    testOfflineMapService.setCached(false);

    await tester.pumpWidget(const MaterialApp(home: MapPickerScreen()));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Map not available offline here. Please move to a cached region.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('MapPickerScreen shows coordinates in bottom card when offline', (
    WidgetTester tester,
  ) async {
    testOfflineModeService.setOffline(true);
    // Mock geocoding failure to force coordinate display
    mockGeocodingService.shouldFail = true;

    final initialLocation = LatLng(14.5995, 120.9842);

    await tester.pumpWidget(
      MaterialApp(home: MapPickerScreen(initialLocation: initialLocation)),
    );
    await tester.pumpAndSettle();

    // The coordinate text should be visible
    expect(find.text('14.599500, 120.984200'), findsOneWidget);
    expect(find.text('Selected Coordinates'), findsOneWidget);
  });
}
