import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:ph_fare_calculator/src/models/fare_formula.dart';
import 'package:ph_fare_calculator/src/models/fare_result.dart';
import 'package:ph_fare_calculator/src/models/saved_route.dart';
import 'package:ph_fare_calculator/src/presentation/screens/offline_menu_screen.dart';
import 'package:ph_fare_calculator/src/presentation/screens/reference_screen.dart';
import 'package:ph_fare_calculator/src/presentation/screens/saved_routes_screen.dart';
import 'package:ph_fare_calculator/src/repositories/fare_repository.dart';

import '../helpers/mocks.dart';

void main() {
  late MockFareRepository mockFareRepository;
  late Directory tempDir;

  setUp(() async {
    await GetIt.instance.reset();
    mockFareRepository = MockFareRepository();
    GetIt.instance.registerSingleton<FareRepository>(mockFareRepository);

    // Setup Hive for real service usage in navigation destinations
    tempDir = await Directory.systemTemp.createTemp('hive_test_offline_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(FareFormulaAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SavedRouteAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(FareResultAdapter());
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(IndicatorLevelAdapter());
    }
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  group('OfflineMenuScreen', () {
    testWidgets('Renders menu options', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: OfflineMenuScreen()));

      expect(find.text('Offline Reference'), findsOneWidget);
      expect(find.text('Saved Routes'), findsOneWidget);
      expect(find.text('Static Cheat Sheets'), findsOneWidget);
    });

    testWidgets('Navigates to SavedRoutesScreen', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: OfflineMenuScreen()));

      await tester.tap(find.text('Saved Routes'));

      // Pump enough time for navigation and build, but avoid pumpAndSettle indefinite wait
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(SavedRoutesScreen), findsOneWidget);
    });

    testWidgets('Navigates to ReferenceScreen', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: OfflineMenuScreen()));

      await tester.tap(find.text('Static Cheat Sheets'));
      await tester.pumpAndSettle();

      expect(find.byType(ReferenceScreen), findsOneWidget);
    });
  });

  group('SavedRoutesScreen', () {
    testWidgets('Renders saved routes list', (WidgetTester tester) async {
      final route = SavedRoute(
        origin: 'Test Origin',
        destination: 'Test Dest',
        fareResults: [
          FareResult(
            transportMode: 'Jeep',
            fare: 10.0,
            indicatorLevel: IndicatorLevel.standard,
            passengerCount: 1,
            totalFare: 10.0,
          ),
        ],
        timestamp: DateTime.now(),
      );
      mockFareRepository.savedRoutesToReturn = [route];

      // Note: When testing SavedRoutesScreen directly, we can inject the mock
      await tester.pumpWidget(
        MaterialApp(
          home: SavedRoutesScreen(fareRepository: mockFareRepository),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Origin to Test Dest'), findsOneWidget);
    });

    testWidgets('Shows empty message when no routes', (
      WidgetTester tester,
    ) async {
      mockFareRepository.savedRoutesToReturn = [];

      await tester.pumpWidget(
        MaterialApp(
          home: SavedRoutesScreen(fareRepository: mockFareRepository),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No saved routes yet.'), findsOneWidget);
    });
  });

  group('ReferenceScreen', () {
    testWidgets('Renders static data', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ReferenceScreen()));
      // Use pump with durations instead of pumpAndSettle to avoid timeout
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Phase 5 refactored the Reference Screen - check for main title
      expect(find.text('Fare Reference Guide'), findsOneWidget);
      // The ReferenceScreen should render without errors
      expect(find.byType(ReferenceScreen), findsOneWidget);
    });
  });
}
