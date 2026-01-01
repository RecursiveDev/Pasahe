import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/discount_type.dart';
import '../models/location.dart';

enum TrafficFactor { low, medium, high }

@singleton
class SettingsService {
  static const String _keyProvincialMode = 'isProvincialModeEnabled';
  static const String _keyTrafficFactor = 'trafficFactor';
  static const String _keyThemeMode = 'themeMode';
  static const String _keyLocale = 'locale';
  static const String _keyUserDiscountType = 'user_discount_type';
  static const String _keyHasSetDiscountType = 'has_set_discount_type';
  static const String _keyHiddenTransportModes = 'hidden_transport_modes';
  static const String _keyHasSetTransportModePreferences =
      'has_set_transport_mode_preferences';
  static const String _keyLastLatitude = 'last_known_latitude';
  static const String _keyLastLongitude = 'last_known_longitude';
  static const String _keyLastLocationName = 'last_known_location_name';
  static const String _keyOfflineModeEnabled = 'offline_mode_enabled';
  static const String _keyAutoCacheEnabled = 'auto_cache_enabled';
  static const String _keyAutoCacheWifiOnly = 'auto_cache_wifi_only';
  static const String _keyOfflineModeMigrated = 'offline_mode_migrated';


  /// Notifier for theme mode changes. Values: 'system', 'light', 'dark'
  /// Default is 'light' for first-time users.
  static final ValueNotifier<String> themeModeNotifier = ValueNotifier('light');
  static final ValueNotifier<Locale> localeNotifier = ValueNotifier(
    const Locale('en'),
  );
  static final ValueNotifier<DiscountType> discountTypeNotifier = ValueNotifier(
    DiscountType.standard,
  );

  Future<bool> getProvincialMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyProvincialMode) ?? false;
  }

  Future<void> setProvincialMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyProvincialMode, value);
  }

  Future<TrafficFactor> getTrafficFactor() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyTrafficFactor);

    if (value == null) {
      return TrafficFactor.medium;
    }

    try {
      return TrafficFactor.values.firstWhere(
        (e) => e.name == value,
        orElse: () => TrafficFactor.medium,
      );
    } catch (_) {
      return TrafficFactor.medium;
    }
  }

  Future<void> setTrafficFactor(TrafficFactor factor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTrafficFactor, factor.name);
  }

  /// Get the theme mode preference. Returns 'system', 'light', or 'dark'.
  /// Default is 'light' for first-time users.
  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyThemeMode) ?? 'light';
    // Validate the value
    if (value != 'system' && value != 'light' && value != 'dark') {
      return 'system';
    }
    if (themeModeNotifier.value != value) {
      themeModeNotifier.value = value;
    }
    return value;
  }

  /// Set the theme mode preference.
  /// @param mode: 'system', 'light', or 'dark'
  Future<void> setThemeMode(String mode) async {
    // Validate the mode
    if (mode != 'system' && mode != 'light' && mode != 'dark') {
      mode = 'system';
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode);
    themeModeNotifier.value = mode;
  }

  Future<Locale> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_keyLocale) ?? 'en';
    final locale = Locale(languageCode);
    if (localeNotifier.value != locale) {
      localeNotifier.value = locale;
    }
    return locale;
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocale, locale.languageCode);
    localeNotifier.value = locale;
  }

  Future<DiscountType> getUserDiscountType() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyUserDiscountType);

    if (value == null) {
      return DiscountType.standard;
    }

    // Migration: Convert old discount types (student, senior, pwd) to new consolidated 'discounted' type
    if (value == 'student' || value == 'senior' || value == 'pwd') {
      // Migrate to new consolidated type
      await setUserDiscountType(DiscountType.discounted);
      return DiscountType.discounted;
    }

    try {
      return DiscountType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => DiscountType.standard,
      );
    } catch (_) {
      return DiscountType.standard;
    }
  }

  Future<void> setUserDiscountType(DiscountType discountType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserDiscountType, discountType.name);
    await prefs.setBool(_keyHasSetDiscountType, true);
    discountTypeNotifier.value = discountType;
  }

  /// Check if the user has ever set their discount type preference
  Future<bool> hasSetDiscountType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasSetDiscountType) ?? false;
  }

  /// Check if the user has ever set their transport mode preferences.
  /// New users (false) should have all modes disabled by default.
  Future<bool> hasSetTransportModePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasSetTransportModePreferences) ?? false;
  }

  /// Get the default enabled transport modes for new users.
  /// Returns mode-subtype keys in format "Mode::SubType".
  /// Default modes: Jeepney (Traditional, Modern), Bus (Traditional, Aircon), Taxi (White Regular).
  /// These keys must match exactly with the sub_type values in fare_formulas.json.
  static Set<String> getDefaultEnabledModes() {
    return {
      'Jeepney::Traditional',
      'Jeepney::Modern (PUJ)',
      'Bus::Traditional',
      'Bus::Aircon',
      'Taxi::White (Regular)',
    };
  }

  /// Get the list of hidden transport modes (stored as "Mode::SubType" strings).
  /// NOTE: For new users who haven't set preferences yet, this returns an empty set.
  /// The caller should use hasSetTransportModePreferences() to check if all modes
  /// should be treated as hidden (disabled) by default.
  Future<Set<String>> getHiddenTransportModes() async {
    final prefs = await SharedPreferences.getInstance();
    final hiddenList = prefs.getStringList(_keyHiddenTransportModes);
    return hiddenList?.toSet() ?? <String>{};
  }

  /// Toggle a transport mode's visibility
  /// @param modeSubType: Format "Mode::SubType" (e.g., "Jeepney::Traditional")
  /// @param isHidden: true to hide, false to show
  Future<void> toggleTransportMode(String modeSubType, bool isHidden) async {
    final prefs = await SharedPreferences.getInstance();
    final hiddenModes = await getHiddenTransportModes();

    if (isHidden) {
      hiddenModes.add(modeSubType);
    } else {
      hiddenModes.remove(modeSubType);
    }

    await prefs.setStringList(_keyHiddenTransportModes, hiddenModes.toList());
    // Mark that the user has now set their transport mode preferences
    await prefs.setBool(_keyHasSetTransportModePreferences, true);
  }

  /// Check if a specific mode-subtype combination is hidden.
  /// Takes into account whether user has set preferences.
  /// For new users who haven't set preferences, only default modes are enabled.
  Future<bool> isTransportModeHidden(String mode, String subType) async {
    final hasSetPrefs = await hasSetTransportModePreferences();
    final modeKey = '$mode::$subType';
    
    // For new users who haven't set any preferences, use default enabled modes
    if (!hasSetPrefs) {
      final defaultModes = getDefaultEnabledModes();
      // If the mode is in the default enabled set, it's NOT hidden
      return !defaultModes.contains(modeKey);
    }
    final hiddenModes = await getHiddenTransportModes();
    return hiddenModes.contains(modeKey);
  }

  /// Get the list of enabled transport modes (opposite of hidden modes)
  /// Returns a Set of "Mode::SubType" strings that are currently enabled
  Future<Set<String>> getEnabledModes() async {
    final hiddenModes = await getHiddenTransportModes();
    // Note: This returns the complement - modes that are NOT in the hidden set
    // The actual enabled modes depend on what formulas exist in the repository
    // This method is mainly useful for checking if a mode is enabled
    return hiddenModes;
  }

  /// Toggle a transport mode's visibility (simplified interface)
  /// @param modeId: Format "Mode::SubType" (e.g., "Jeepney::Traditional")
  Future<void> toggleMode(String modeId) async {
    final hiddenModes = await getHiddenTransportModes();
    final isCurrentlyHidden = hiddenModes.contains(modeId);

    // Toggle the state
    await toggleTransportMode(modeId, !isCurrentlyHidden);
  }

  /// Save the last known location (for persistence between sessions)
  Future<void> saveLastLocation(Location location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyLastLatitude, location.latitude);
    await prefs.setDouble(_keyLastLongitude, location.longitude);
    await prefs.setString(_keyLastLocationName, location.name);
  }

  /// Get the last known location (returns null if not previously saved)
  Future<Location?> getLastLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final latitude = prefs.getDouble(_keyLastLatitude);
    final longitude = prefs.getDouble(_keyLastLongitude);
    final name = prefs.getString(_keyLastLocationName);

    if (latitude == null || longitude == null || name == null) {
      return null;
    }

    return Location(name: name, latitude: latitude, longitude: longitude);
  }

  /// Get the offline mode enabled preference.
  Future<bool> getOfflineModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOfflineModeEnabled) ?? false;
  }

  /// Set the offline mode enabled preference.
  Future<void> setOfflineModeEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOfflineModeEnabled, value);
  }

  /// Get the auto-cache enabled preference.
  Future<bool> getAutoCacheEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoCacheEnabled) ?? true;
  }

  /// Set the auto-cache enabled preference.
  Future<void> setAutoCacheEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoCacheEnabled, value);
  }

  /// Get the auto-cache wifi only preference.
  Future<bool> getAutoCacheWifiOnly() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoCacheWifiOnly) ?? true;
  }

  /// Set the auto-cache wifi only preference.
  Future<void> setAutoCacheWifiOnly(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoCacheWifiOnly, value);
  }

  /// Check if the user has migrated to the offline mode version.
  Future<bool> hasMigratedToOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOfflineModeMigrated) ?? false;
  }

  /// Set the offline mode migration flag.
  Future<void> setMigratedToOfflineMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOfflineModeMigrated, value);
  }
}

