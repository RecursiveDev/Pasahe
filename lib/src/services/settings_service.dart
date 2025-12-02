import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/discount_type.dart';

enum TrafficFactor { low, medium, high }

@singleton
class SettingsService {
  static const String _keyProvincialMode = 'isProvincialModeEnabled';
  static const String _keyTrafficFactor = 'trafficFactor';
  static const String _keyHighContrastEnabled = 'isHighContrastEnabled';
  static const String _keyLocale = 'locale';
  static const String _keyUserDiscountType = 'user_discount_type';
  static const String _keyHiddenTransportModes = 'hidden_transport_modes';

  static final ValueNotifier<bool> highContrastNotifier = ValueNotifier(false);
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

  Future<bool> getHighContrastEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_keyHighContrastEnabled) ?? false;
    if (highContrastNotifier.value != value) {
      highContrastNotifier.value = value;
    }
    return value;
  }

  Future<void> setHighContrastEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHighContrastEnabled, value);
    highContrastNotifier.value = value;
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
    discountTypeNotifier.value = discountType;
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
}
