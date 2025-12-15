import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mockito/mockito.dart';
import 'package:ph_fare_calculator/src/services/connectivity/connectivity_service.dart';
import 'package:ph_fare_calculator/src/models/connectivity_status.dart';

// Mock class for Connectivity
class MockConnectivity extends Mock implements Connectivity {
  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      Stream.fromIterable([
        [ConnectivityResult.none], // Initial state
        [ConnectivityResult.wifi], // Change to connected
      ]);

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    return [ConnectivityResult.none]; // Initial state
  }
}

void main() {
  test(
    'ConnectivityService should correctly persist initial state and update on change',
    () async {
      // 1. Setup
      final mockConnectivity = MockConnectivity();
      final service = ConnectivityService.withConnectivity(mockConnectivity);

      // 2. Initialize
      // This mimics the app startup where initialization should happen
      await service.initialize();

      // 3. Verify Initial State
      // Without the fix (permission/initialization), it might default to offline or fail to update
      // But since this is a unit test, we can only verify logic, not permissions.
      // However, we can verify that IF properly initialized, it handles state correctly.

      // Check initial status
      expect(service.lastKnownStatus.isOffline, true);

      // 4. Verify Stream Updates
      // Listen to the stream and expect a change to online
      expectLater(
        service.connectivityStream,
        emitsInOrder([
          // Initial state from initialize()
          isA<ConnectivityStatus>().having(
            (s) => s.isOffline,
            'isOffline',
            true,
          ),
          // Update from stream
          isA<ConnectivityStatus>().having((s) => s.isOnline, 'isOnline', true),
        ]),
      );
    },
  );
}
