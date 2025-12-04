enum TransportMode {
  jeepney,
  bus,
  taxi,
  train,
  ferry,
  tricycle,
  uvExpress,
  van,
  motorcycle,
  edsaCarousel,
  pedicab,
  kuliglig;

  /// Get the category for grouping transport modes
  String get category {
    switch (this) {
      case TransportMode.jeepney:
      case TransportMode.bus:
      case TransportMode.taxi:
      case TransportMode.tricycle:
      case TransportMode.uvExpress:
      case TransportMode.van:
      case TransportMode.motorcycle:
      case TransportMode.edsaCarousel:
      case TransportMode.pedicab:
      case TransportMode.kuliglig:
        return 'road';
      case TransportMode.train:
        return 'rail';
      case TransportMode.ferry:
        return 'water';
    }
  }

  /// Get the default visibility state for this transport mode
  bool get isVisible => true;

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
      case TransportMode.van:
        return 'Van';
      case TransportMode.motorcycle:
        return 'Motorcycle';
      case TransportMode.edsaCarousel:
        return 'EDSA Carousel';
      case TransportMode.pedicab:
        return 'Pedicab';
      case TransportMode.kuliglig:
        return 'Kuliglig';
    }
  }

  /// Get a tourist-friendly description of the transport mode
  String get description {
    switch (this) {
      case TransportMode.jeepney:
        return 'Iconic colorful open-air vehicle, the most popular form of public transport in the Philippines. Great for short to medium distances.';
      case TransportMode.bus:
        return 'Large public buses for longer routes. Choose between traditional (non-aircon), aircon, or premium/deluxe options.';
      case TransportMode.taxi:
        return 'Metered taxis available throughout Metro Manila. White taxis for general use, yellow for airport service. Also includes app-based rides.';
      case TransportMode.train:
        return 'Metro Manila\'s rapid transit system including LRT (Light Rail Transit), MRT (Metro Rail Transit), and PNR (Philippine National Railways).';
      case TransportMode.ferry:
        return 'Water transport connecting islands and coastal areas. Essential for inter-island travel in the Philippines.';
      case TransportMode.tricycle:
        return 'Motorcycle with sidecar, perfect for short distances and narrow streets. Fares are often negotiable.';
      case TransportMode.uvExpress:
        return 'Modern air-conditioned vans operating on fixed routes. Faster than jeepneys with comfortable seating.';
      case TransportMode.van:
        return 'Air-conditioned vans for point-to-point routes. Includes UV Express and FX/AUV services with comfortable seating.';
      case TransportMode.motorcycle:
        return 'Motorcycle-based transport including habal-habal (traditional) and app-based services like Angkas. Common in provinces and for quick trips.';
      case TransportMode.edsaCarousel:
        return 'Free government-subsidized Bus Rapid Transit (BRT) service running along EDSA, Metro Manila\'s main highway.';
      case TransportMode.pedicab:
        return 'Non-motorized bicycle with sidecar. Common in residential areas for very short trips. Environmentally friendly option.';
      case TransportMode.kuliglig:
        return 'Improvised motorized transport common in rural and agricultural areas. Features a motorized engine with attached sidecar.';
    }
  }

  static TransportMode fromString(String mode) {
    // Handle "Mode (SubType)" format by extracting just the mode part
    // Example: "Jeepney (Traditional)" -> "Jeepney"
    final modeName = mode.contains('(')
        ? mode.substring(0, mode.indexOf('(')).trim()
        : mode.trim();

    return TransportMode.values.firstWhere(
      (e) => e.displayName.toLowerCase() == modeName.toLowerCase(),
      orElse: () => TransportMode.jeepney, // Default fallback
    );
  }
}
