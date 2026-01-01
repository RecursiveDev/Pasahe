import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../models/accuracy_level.dart';
import '../../models/connectivity_status.dart';
import '../connectivity/connectivity_service.dart';
import '../settings_service.dart';
import 'offline_map_service.dart';

/// Service for managing the global offline mode state.
///
/// Provides centralized access to connectivity status, user preferences,
/// and cache state. Implements the ChangeNotifier pattern for reactive UI updates.
@lazySingleton
class OfflineModeService extends ChangeNotifier {
  final ConnectivityService _connectivityService;
  final SettingsService _settingsService;
  final OfflineMapService _offlineMapService;

  ConnectivityStatus _connectivityStatus = ConnectivityStatus.offline;
  bool _offlineModeEnabled = false;
  bool _autoCacheEnabled = true;
  bool _autoCacheWifiOnly = true;
  List<String> _downloadedRegionIds = [];
  final bool _isAutoCaching = false;
  bool _isInitialized = false;

  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;

  OfflineModeService(
    this._connectivityService,
    this._settingsService,
    this._offlineMapService,
  );

  /// Current connectivity status.
  ConnectivityStatus get connectivityStatus => _connectivityStatus;

  /// Whether offline mode is enabled by user preference.
  bool get offlineModeEnabled => _offlineModeEnabled;

  /// Whether auto-caching is enabled.
  bool get autoCacheEnabled => _autoCacheEnabled;

  /// Whether auto-caching is restricted to WiFi only.
  bool get autoCacheWifiOnly => _autoCacheWifiOnly;

  /// IDs of downloaded regions available offline.
  List<String> get downloadedRegionIds =>
      List.unmodifiable(_downloadedRegionIds);

  /// Whether auto-caching is currently in progress.
  bool get isAutoCaching => _isAutoCaching;

  /// Whether the app is currently operating in offline mode.
  ///
  /// Returns true if either the device is offline or the user has forced offline mode.
  bool get isCurrentlyOffline =>
      _connectivityStatus == ConnectivityStatus.offline || _offlineModeEnabled;

  /// Returns the appropriate accuracy level based on current state.
  AccuracyLevel get currentAccuracyLevel {
    if (_offlineModeEnabled || _connectivityStatus.isOffline) {
      return AccuracyLevel.approximate;
    }
    if (_connectivityStatus.isLimited) {
      return AccuracyLevel.estimated;
    }
    return AccuracyLevel.precise;
  }

  /// Initializes the offline mode service.
  ///
  /// Loads saved preferences and starts listening for connectivity changes.
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Load preferences
    _offlineModeEnabled = await _settingsService.getOfflineModeEnabled();
    _autoCacheEnabled = await _settingsService.getAutoCacheEnabled();
    _autoCacheWifiOnly = await _settingsService.getAutoCacheWifiOnly();

    // Check for migration (opt-out for existing users)
    final hasMigrated = await _settingsService.hasMigratedToOfflineMode();
    if (!hasMigrated) {
      // Check if user already exists by checking if they've set a discount type
      final hasSetDiscount = await _settingsService.hasSetDiscountType();
      if (hasSetDiscount) {
        // Existing user: Default to OFF for both
        _offlineModeEnabled = false;
        _autoCacheEnabled = false;
      } else {
        // New user: Default to ON for auto-cache
        _offlineModeEnabled = false;
        _autoCacheEnabled = true;
      }

      await _settingsService.setOfflineModeEnabled(_offlineModeEnabled);
      await _settingsService.setAutoCacheEnabled(_autoCacheEnabled);
      await _settingsService.setMigratedToOfflineMode(true);
    }

    // Get initial connectivity status
    _connectivityStatus = _connectivityService.lastKnownStatus;

    // Ensure OfflineMapService is initialized before getting regions
    await _offlineMapService.initialize();
    final downloadedRegions = await _offlineMapService.getDownloadedRegions();
    _downloadedRegionIds = downloadedRegions.map((r) => r.id).toList();

    // Listen to connectivity changes
    _connectivitySubscription = _connectivityService.connectivityStream.listen(
      _handleConnectivityChange,
    );

    _isInitialized = true;
    notifyListeners();
  }

  /// Handles connectivity status changes.
  void _handleConnectivityChange(ConnectivityStatus status) {
    _connectivityStatus = status;
    notifyListeners();
  }

  /// Toggles offline mode on/off.
  Future<void> setOfflineModeEnabled(bool enabled) async {
    _offlineModeEnabled = enabled;
    await _settingsService.setOfflineModeEnabled(enabled);
    notifyListeners();
  }

  /// Toggles auto-caching on/off.
  Future<void> setAutoCacheEnabled(bool enabled) async {
    _autoCacheEnabled = enabled;
    await _settingsService.setAutoCacheEnabled(enabled);
    notifyListeners();
  }

  /// Toggles auto-caching WiFi only on/off.
  Future<void> setAutoCacheWifiOnly(bool wifiOnly) async {
    _autoCacheWifiOnly = wifiOnly;
    await _settingsService.setAutoCacheWifiOnly(wifiOnly);
    notifyListeners();
  }

  /// Refreshes the list of downloaded regions.
  Future<void> refreshDownloadedRegions() async {
    final downloadedRegions = await _offlineMapService.getDownloadedRegions();
    _downloadedRegionIds = downloadedRegions.map((r) => r.id).toList();
    notifyListeners();
  }

  /// Whether map downloads/caching should be allowed currently.
  bool get shouldAllowDownloads {
    if (_offlineModeEnabled) return false;
    if (!_autoCacheEnabled) return false;
    if (_autoCacheWifiOnly && !_connectivityService.isWifi) return false;
    return _connectivityStatus.isOnline;
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
