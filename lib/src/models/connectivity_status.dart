/// Represents the current network connectivity status of the device.
///
/// Used by [ConnectivityService] to communicate network state changes.
enum ConnectivityStatus {
  /// Device has a working internet connection.
  online,

  /// Device has no internet connection.
  offline,

  /// Device has a network connection but services may be unreachable.
  /// This can occur when connected to a network without internet access
  /// or when specific services are blocked.
  limited,
}

/// Extension methods for [ConnectivityStatus] to provide convenience helpers.
extension ConnectivityStatusX on ConnectivityStatus {
  /// Returns `true` if the device has any form of connectivity.
  ///
  /// This includes [ConnectivityStatus.online] and [ConnectivityStatus.limited].
  bool get isConnected => this != ConnectivityStatus.offline;

  /// Returns `true` if the device is fully online with working internet.
  bool get isOnline => this == ConnectivityStatus.online;

  /// Returns `true` if the device has no network connection.
  bool get isOffline => this == ConnectivityStatus.offline;

  /// Returns `true` if the device has limited connectivity.
  bool get isLimited => this == ConnectivityStatus.limited;

  /// Returns a human-readable description of the connectivity status.
  String get description {
    switch (this) {
      case ConnectivityStatus.online:
        return 'Online';
      case ConnectivityStatus.offline:
        return 'Offline';
      case ConnectivityStatus.limited:
        return 'Limited connectivity';
    }
  }
}
