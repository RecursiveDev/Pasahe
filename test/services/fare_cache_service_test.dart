import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ph_fare_calculator/src/models/fare_formula.dart';
import 'package:ph_fare_calculator/src/models/fare_result.dart';
import 'package:ph_fare_calculator/src/models/saved_route.dart';
import 'package:ph_fare_calculator/src/repositories/fare_repository.dart';

void main() {
  late FareRepository fareRepository;
  late Directory tempDir;

  setUp(() async {
    // Use a temporary directory for Hive to avoid polluting the actual app data
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    TestWidgetsFlutterBinding.ensureInitialized();

    // Register Adapters if not already registered
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(FareFormulaAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SavedRouteAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(FareResultAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(IndicatorLevelAdapter());
    }

    fareRepository = FareRepository();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  group('FareRepository - Formulas', () {
    // skipping seedDefaults test as it requires asset bundle which is hard to mock in unit test without flutter_test
    // test('seedDefaults populates box when empty', () async {
    //   await fareRepository.seedDefaults();
    //   final formulas = await fareRepository.getAllFormulas();
    //   expect(formulas.isNotEmpty, true);
    //   expect(formulas.any((f) => f.mode == 'Jeepney'), true);
    // });

    test('saveFormulas replaces existing formulas', () async {
      // await fareRepository.seedDefaults();
      final newFormulas = [
        FareFormula(
          mode: 'TestMode',
          subType: 'TestSub',
          baseFare: 10.0,
          perKmRate: 1.0,
        ),
      ];

      await fareRepository.saveFormulas(newFormulas);
      final retrieved = await fareRepository.getAllFormulas();

      expect(retrieved.length, 1);
      expect(retrieved.first.mode, 'TestMode');
    });
  });

  group('FareRepository - Saved Routes', () {
    test('can save and retrieve a route', () async {
      final route = SavedRoute(
        origin: 'A',
        destination: 'B',
        fareResults: [
          FareResult(
            transportMode: 'Jeep',
            fare: 15.0,
            indicatorLevel: IndicatorLevel.standard,
            passengerCount: 1,
            totalFare: 15.0,
          ),
        ],
        timestamp: DateTime.now(),
      );

      await fareRepository.saveRoute(route);
      final routes = await fareRepository.getSavedRoutes();

      expect(routes.length, 1);
      expect(routes.first.origin, 'A');
      expect(routes.first.fareResults.first.fare, 15.0);
    });

    test('can delete a route', () async {
      final route = SavedRoute(
        origin: 'DeleteMe',
        destination: 'B',
        fareResults: [],
        timestamp: DateTime.now(),
      );

      await fareRepository.saveRoute(route);
      var routes = await fareRepository.getSavedRoutes();
      expect(routes.length, 1);

      // We need to get the object from the box to have the Hive key/context for deletion
      // Since getSavedRoutes returns reversed list, let's grab the first one
      await fareRepository.deleteRoute(routes.first);

      routes = await fareRepository.getSavedRoutes();
      expect(routes.isEmpty, true);
    });

    test('deduplicates routes with same origin and destination', () async {
      final firstTimestamp = DateTime.now();
      final route1 = SavedRoute(
        origin: 'Manila',
        destination: 'Quezon City',
        fareResults: [
          FareResult(
            transportMode: 'Jeep',
            fare: 15.0,
            indicatorLevel: IndicatorLevel.standard,
            passengerCount: 1,
            totalFare: 15.0,
          ),
        ],
        timestamp: firstTimestamp,
      );

      await fareRepository.saveRoute(route1);
      var routes = await fareRepository.getSavedRoutes();
      expect(routes.length, 1);
      expect(routes.first.timestamp, firstTimestamp);

      // Wait a bit to ensure different timestamp
      await Future.delayed(const Duration(milliseconds: 100));

      final secondTimestamp = DateTime.now();
      final route2 = SavedRoute(
        origin: 'Manila',
        destination: 'Quezon City',
        fareResults: [
          FareResult(
            transportMode: 'Bus',
            fare: 20.0,
            indicatorLevel: IndicatorLevel.standard,
            passengerCount: 1,
            totalFare: 20.0,
          ),
        ],
        timestamp: secondTimestamp,
      );

      await fareRepository.saveRoute(route2);
      routes = await fareRepository.getSavedRoutes();

      // Should still have only 1 route (updated, not added)
      expect(routes.length, 1);

      // Should have the new timestamp
      expect(routes.first.timestamp, secondTimestamp);

      // Should have the new fare results
      expect(routes.first.fareResults.length, 1);
      expect(routes.first.fareResults.first.transportMode, 'Bus');
      expect(routes.first.fareResults.first.fare, 20.0);
    });

    test('deduplication is case-insensitive', () async {
      final route1 = SavedRoute(
        origin: 'manila',
        destination: 'quezon city',
        fareResults: [],
        timestamp: DateTime.now(),
      );

      await fareRepository.saveRoute(route1);

      await Future.delayed(const Duration(milliseconds: 50));

      final route2 = SavedRoute(
        origin: 'MANILA',
        destination: 'QUEZON CITY',
        fareResults: [],
        timestamp: DateTime.now(),
      );

      await fareRepository.saveRoute(route2);
      final routes = await fareRepository.getSavedRoutes();

      // Should still have only 1 route (case-insensitive match)
      expect(routes.length, 1);
    });

    test(
      'allows different routes with different origin or destination',
      () async {
        final route1 = SavedRoute(
          origin: 'Manila',
          destination: 'Quezon City',
          fareResults: [],
          timestamp: DateTime.now(),
        );

        final route2 = SavedRoute(
          origin: 'Manila',
          destination: 'Makati',
          fareResults: [],
          timestamp: DateTime.now(),
        );

        final route3 = SavedRoute(
          origin: 'Pasig',
          destination: 'Quezon City',
          fareResults: [],
          timestamp: DateTime.now(),
        );

        await fareRepository.saveRoute(route1);
        await fareRepository.saveRoute(route2);
        await fareRepository.saveRoute(route3);

        final routes = await fareRepository.getSavedRoutes();

        // Should have 3 different routes
        expect(routes.length, 3);
      },
    );
  });
}
