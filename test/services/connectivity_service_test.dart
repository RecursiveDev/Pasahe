import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ph_fare_calculator/src/models/connectivity_status.dart';
import 'package:ph_fare_calculator/src/services/connectivity/connectivity_service.dart';

/// Mock implementation of [Connectivity] for testing.
class MockConnectivity implements Connectivity {
  final StreamController<List<ConnectivityResult>> _controller =
      StreamController<List<ConnectivityResult>>.broadcast();

  List<ConnectivityResult> _currentResults = [ConnectivityResult.wifi];

  void setConnectivityResults(List<ConnectivityResult> results) {
    _currentResults = results;
    _controller.add(results);
  }

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    return _currentResults;
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _controller.stream;

  void dispose() {
    _controller.close();
  }
}

void main() {
  group('ConnectivityStatus', () {
    test('isConnected returns true for online and limited', () {
      expect(ConnectivityStatus.online.isConnected, isTrue);
      expect(ConnectivityStatus.limited.isConnected, isTrue);
      expect(ConnectivityStatus.offline.isConnected, isFalse);
    });

    test('isOnline returns true only for online', () {
      expect(ConnectivityStatus.online.isOnline, isTrue);
      expect(ConnectivityStatus.limited.isOnline, isFalse);
      expect(ConnectivityStatus.offline.isOnline, isFalse);
    });

    test('isOffline returns true only for offline', () {
      expect(ConnectivityStatus.online.isOffline, isFalse);
      expect(ConnectivityStatus.limited.isOffline, isFalse);
      expect(ConnectivityStatus.offline.isOffline, isTrue);
    });

    test('isLimited returns true only for limited', () {
      expect(ConnectivityStatus.online.isLimited, isFalse);
      expect(ConnectivityStatus.limited.isLimited, isTrue);
      expect(ConnectivityStatus.offline.isLimited, isFalse);
    });

    test('description returns human-readable strings', () {
      expect(ConnectivityStatus.online.description, 'Online');
      expect(ConnectivityStatus.offline.description, 'Offline');
      expect(ConnectivityStatus.limited.description, 'Limited connectivity');
    });
  });

  group('ConnectivityService', () {
    late MockConnectivity mockConnectivity;
    late ConnectivityService service;

    setUp(() {
      mockConnectivity = MockConnectivity();
      service = ConnectivityService.withConnectivity(mockConnectivity);
    });

    tearDown(() async {
      await service.dispose();
      mockConnectivity.dispose();
    });

    group('currentStatus', () {
      test('returns online when wifi is available', () async {
        mockConnectivity.setConnectivityResults([ConnectivityResult.wifi]);
        final status = await service.currentStatus;
        expect(status, ConnectivityStatus.online);
      });

      test('returns online when mobile is available', () async {
        mockConnectivity.setConnectivityResults([ConnectivityResult.mobile]);
        final status = await service.currentStatus;
        expect(status, ConnectivityStatus.online);
      });

      test('returns online when ethernet is available', () async {
        mockConnectivity.setConnectivityResults([ConnectivityResult.ethernet]);
        final status = await service.currentStatus;
        expect(status, ConnectivityStatus.online);
      });

      test('returns online when vpn is available', () async {
        mockConnectivity.setConnectivityResults([ConnectivityResult.vpn]);
        final status = await service.currentStatus;
        expect(status, ConnectivityStatus.online);
      });

      test('returns offline when no connectivity', () async {
        mockConnectivity.setConnectivityResults([ConnectivityResult.none]);
        final status = await service.currentStatus;
        expect(status, ConnectivityStatus.offline);
      });

      test('returns offline when results are empty', () async {
        mockConnectivity.setConnectivityResults([]);
        final status = await service.currentStatus;
        expect(status, ConnectivityStatus.offline);
      });

      test('returns limited when only bluetooth is available', () async {
        mockConnectivity.setConnectivityResults([ConnectivityResult.bluetooth]);
        final status = await service.currentStatus;
        expect(status, ConnectivityStatus.limited);
      });

      test('returns limited when only other is available', () async {
        mockConnectivity.setConnectivityResults([ConnectivityResult.other]);
        final status = await service.currentStatus;
        expect(status, ConnectivityStatus.limited);
      });

      test('returns online when wifi and mobile are both available', () async {
        mockConnectivity.setConnectivityResults([
          ConnectivityResult.wifi,
          ConnectivityResult.mobile,
        ]);
        final status = await service.currentStatus;
        expect(status, ConnectivityStatus.online);
      });
    });

    group('initialize', () {
      test('emits initial status on initialization', () async {
        mockConnectivity.setConnectivityResults([ConnectivityResult.wifi]);

        final statuses = <ConnectivityStatus>[];
        final subscription = service.connectivityStream.listen(statuses.add);

        await service.initialize();

        // Wait for stream to emit
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(statuses, contains(ConnectivityStatus.online));

        await subscription.cancel();
      });

      test('subsequent initialize calls are no-ops', () async {
        mockConnectivity.setConnectivityResults([ConnectivityResult.wifi]);

        final statuses = <ConnectivityStatus>[];
        final subscription = service.connectivityStream.listen(statuses.add);

        await service.initialize();
        await service.initialize();
        await service.initialize();

        // Wait for stream to emit
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Should only have one emission (from first initialize)
        expect(statuses.length, 1);

        await subscription.cancel();
      });
    });

    group('connectivityStream', () {
      test('emits status changes', () async {
        final statuses = <ConnectivityStatus>[];
        final subscription = service.connectivityStream.listen(statuses.add);

        await service.initialize();

        // Wait for initial emission
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Simulate going offline
        mockConnectivity.setConnectivityResults([ConnectivityResult.none]);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Simulate coming back online
        mockConnectivity.setConnectivityResults([ConnectivityResult.wifi]);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(statuses, contains(ConnectivityStatus.online));
        expect(statuses, contains(ConnectivityStatus.offline));

        await subscription.cancel();
      });

      test('does not emit duplicate statuses', () async {
        mockConnectivity.setConnectivityResults([ConnectivityResult.wifi]);

        final statuses = <ConnectivityStatus>[];
        final subscription = service.connectivityStream.listen(statuses.add);

        await service.initialize();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Emit same status multiple times (wifi, then mobile - both online)
        mockConnectivity.setConnectivityResults([ConnectivityResult.wifi]);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        mockConnectivity.setConnectivityResults([ConnectivityResult.mobile]);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Should only have one emission since status stays "online"
        expect(statuses.length, 1);
        expect(statuses.first, ConnectivityStatus.online);

        await subscription.cancel();
      });
    });

    group('lastKnownStatus', () {
      test('returns initial offline status before initialization', () {
        expect(service.lastKnownStatus, ConnectivityStatus.offline);
      });

      test('returns cached status after initialization', () async {
        mockConnectivity.setConnectivityResults([ConnectivityResult.wifi]);

        await service.initialize();

        expect(service.lastKnownStatus, ConnectivityStatus.online);
      });

      test('updates after connectivity changes', () async {
        mockConnectivity.setConnectivityResults([ConnectivityResult.wifi]);

        await service.initialize();
        expect(service.lastKnownStatus, ConnectivityStatus.online);

        mockConnectivity.setConnectivityResults([ConnectivityResult.none]);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(service.lastKnownStatus, ConnectivityStatus.offline);
      });
    });

    group('isServiceReachable', () {
      test('returns false for invalid URLs', () async {
        final result = await service.isServiceReachable('not-a-valid-url');
        expect(result, isFalse);
      });

      test('returns false when connection times out', () async {
        // This should timeout quickly since it's a non-routable IP
        final result = await service.isServiceReachable(
          'http://10.255.255.1',
          timeout: const Duration(milliseconds: 100),
        );
        expect(result, isFalse);
      });
    });

    group('dispose', () {
      test('stops listening to connectivity changes after dispose', () async {
        mockConnectivity.setConnectivityResults([ConnectivityResult.wifi]);

        await service.initialize();
        await service.dispose();

        // Stream should be closed - trying to get first element throws StateError
        expect(
          () => service.connectivityStream.first,
          throwsA(isA<StateError>()),
        );
      });
    });
  });
}
