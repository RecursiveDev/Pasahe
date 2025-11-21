import 'dart:developer';

import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;

  RemoteConfigService(this._remoteConfig);

  Future<void> initialize() async {
    await _remoteConfig.setDefaults(const {
      "fare_formulas": "{}",
      "train_matrix": "{}",
      "ferry_matrix": "{}",
    });
    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      log('Failed to fetch remote config: $e. Using default values.');
    }
  }
}