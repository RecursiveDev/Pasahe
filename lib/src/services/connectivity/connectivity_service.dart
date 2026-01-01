import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

import '../../models/connectivity_status.dart';

/// Service for monitoring network connectivity status.
///
/// Uses the `connectivity_plus` package to detect network state changes
/// and provides a stream-based API for reactive connectivity updates.
///
/// Example usage:
/// ```dart
/// final service = getIt<ConnectivityService>();
///
/// // Listen to connectivity changes
/// service.connectivityStream.listen((status) {
///   if (status.isOffline) {
///     showOfflineBanner();
///   }
/// });
///
/// // Check current status
/// final status = await service.currentStatus;
/// ```
@lazySingleton
class ConnectivityService {
  /// The underlying connectivity plugin instance.
  final Connectivity _connectivity;

  /// Stream controller for broadcasting connectivity status changes.
  final StreamController<ConnectivityStatus> _statusController =
      StreamController<ConnectivityStatus>.broadcast();

  /// Subscription to the connectivity plugin's stream.
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// The last known connectivity status.
  ConnectivityStatus _lastStatus = ConnectivityStatus.offline;

  /// Whether the current connection is WiFi.
  bool _isWifi = false;

  /// Whether the service has been initialized.

  bool _isInitialized = false;

  /// Creates a new [ConnectivityService] instance for production use.
  @factoryMethod
  ConnectivityService() : _connectivity = Connectivity();

  /// Creates a new [ConnectivityService] instance for testing.
  ///
  /// The [connectivity] parameter allows injecting a mock for testing.
  ConnectivityService.withConnectivity(Connectivity connectivity)
    : _connectivity = connectivity;

  /// Stream of connectivity status changes.
  ///
  /// Emits a new [ConnectivityStatus] whenever the network state changes.
  /// The stream is broadcast, allowing multiple listeners.
  Stream<ConnectivityStatus> get connectivityStream => _statusController.stream;

  /// Gets the current connectivity status.
  ///
  /// This performs a fresh check of the network state rather than
  /// returning a cached value.
  Future<ConnectivityStatus> get currentStatus async {
    final results = await _connectivity.checkConnectivity();
    return _mapConnectivityResults(results);
  }

  /// Returns the last known connectivity status without performing a new check.
  ConnectivityStatus get lastKnownStatus => _lastStatus;

  /// Returns true if the device is currently connected via WiFi.
  bool get isWifi => _isWifi;

  /// Initializes the connectivity service and starts listening for changes.

  ///
  /// This should be called once during app startup. Subsequent calls are no-ops.
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Get initial status
    final results = await _connectivity.checkConnectivity();
    _lastStatus = _mapConnectivityResults(results);
    _isWifi = results.contains(ConnectivityResult.wifi);
    _statusController.add(_lastStatus);

    // Listen for changes

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
      onError: _handleConnectivityError,
    );

    _isInitialized = true;
  }

  /// Handles connectivity change events from the plugin.
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final newStatus = _mapConnectivityResults(results);
    _isWifi = results.contains(ConnectivityResult.wifi);

    // Only emit if status actually changed

    if (newStatus != _lastStatus) {
      _lastStatus = newStatus;
      _statusController.add(newStatus);
    }
  }

  /// Handles errors from the connectivity stream.
  void _handleConnectivityError(Object error) {
    // On error, assume offline to be safe
    if (_lastStatus != ConnectivityStatus.offline) {
      _lastStatus = ConnectivityStatus.offline;
      _statusController.add(_lastStatus);
    }
  }

  /// Maps connectivity plugin results to our [ConnectivityStatus] enum.
  ConnectivityStatus _mapConnectivityResults(List<ConnectivityResult> results) {
    // No connectivity results means offline
    if (results.isEmpty) {
      return ConnectivityStatus.offline;
    }

    // Check if any result indicates connectivity
    final hasConnectivity = results.any(
      (result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn,
    );

    if (!hasConnectivity) {
      // Check for bluetooth or other limited connectivity
      final hasLimitedConnectivity = results.any(
        (result) =>
            result == ConnectivityResult.bluetooth ||
            result == ConnectivityResult.other,
      );

      if (hasLimitedConnectivity) {
        return ConnectivityStatus.limited;
      }

      return ConnectivityStatus.offline;
    }

    return ConnectivityStatus.online;
  }

  /// Checks if a specific URL is reachable.
  ///
  /// This performs an HTTP HEAD request to the given [url] and returns `true`
  /// if the request succeeds within the specified [timeout].
  ///
  /// Useful for checking if specific services (like OSRM) are available
  /// even when the device reports as online.
  ///
  /// Example:
  /// ```dart
  /// final canRoute = await service.isServiceReachable(
  ///   'https://router.project-osrm.org',
  /// );
  /// ```
  Future<bool> isServiceReachable(
    String url, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final uri = Uri.parse(url);
      final response = await http.head(uri).timeout(timeout);
      return response.statusCode >= 200 && response.statusCode < 400;
    } catch (_) {
      return false;
    }
  }

  /// Checks if the device has actual internet access.
  ///
  /// This performs a quick check to known reliable endpoints to verify
  /// that the device can actually reach the internet, not just that it
  /// has a network connection.
  ///
  /// Returns [ConnectivityStatus.online] if internet is reachable,
  /// [ConnectivityStatus.limited] if connected but internet is unreachable,
  /// or [ConnectivityStatus.offline] if no connection exists.
  Future<ConnectivityStatus> checkActualConnectivity() async {
    final basicStatus = await currentStatus;

    if (basicStatus == ConnectivityStatus.offline) {
      return ConnectivityStatus.offline;
    }

    // List of reliable endpoints to check.
    // We check multiple endpoints to avoid false negatives due to blocked domains
    // (e.g., google.com in China) or temporary outages.
    const endpoints = [
      'https://1.1.1.1', // Cloudflare (IP based, usually accessible)
      'https://www.microsoft.com', // Global availability
      'https://www.github.com', // Fallback
    ];

    // Try each endpoint until one succeeds
    for (final endpoint in endpoints) {
      final hasInternet = await isServiceReachable(
        endpoint,
        timeout: const Duration(seconds: 3),
      );

      if (hasInternet) {
        return ConnectivityStatus.online;
      }
    }

    return ConnectivityStatus.limited;
  }

  /// Disposes of the service and releases resources.
  ///
  /// Should be called when the service is no longer needed.
  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _statusController.close();
    _isInitialized = false;
  }
}
