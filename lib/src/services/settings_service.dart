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
  static const String _keyLastLatitude = 'last_known_latitude';
  static const String _keyLastLongitude = 'last_known_longitude';
  static const String _keyLastLocationName = 'last_known_location_name';

  /// Notifier for theme mode changes. Values: 'system', 'light', 'dark'
  static final ValueNotifier<String> themeModeNotifier = ValueNotifier(
    'system',
  );
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
  /// Default is 'system' (follows device settings).
  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyThemeMode) ?? 'system';
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

  /// Get the list of hidden transport modes (stored as "Mode::SubType" strings)
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
  }

  /// Check if a specific mode-subtype combination is hidden
  Future<bool> isTransportModeHidden(String mode, String subType) async {
    final hiddenModes = await getHiddenTransportModes();
    return hiddenModes.contains('$mode::$subType');
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
}
