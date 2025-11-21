import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TrafficFactor { low, medium, high }

class SettingsService {
  static const String _keyProvincialMode = 'isProvincialModeEnabled';
  static const String _keyTrafficFactor = 'trafficFactor';
  static const String _keyHighContrastEnabled = 'isHighContrastEnabled';

  static final ValueNotifier<bool> highContrastNotifier = ValueNotifier(false);

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
}