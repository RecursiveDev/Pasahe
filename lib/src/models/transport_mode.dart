enum TransportMode {
  jeepney,
  bus,
  taxi,
  train,
  ferry,
  tricycle,
  uvExpress;

  String get displayName {
    switch (this) {
      case TransportMode.jeepney:
        return 'Jeepney';
      case TransportMode.bus:
        return 'Bus';
      case TransportMode.taxi:
        return 'Taxi';
      case TransportMode.train:
        return 'Train';
      case TransportMode.ferry:
        return 'Ferry';
      case TransportMode.tricycle:
        return 'Tricycle';
      case TransportMode.uvExpress:
        return 'UV Express';
    }
  }

  static TransportMode fromString(String mode) {
    return TransportMode.values.firstWhere(
      (e) => e.displayName.toLowerCase() == mode.toLowerCase(),
      orElse: () => TransportMode.jeepney, // Default fallback
    );
  }
}