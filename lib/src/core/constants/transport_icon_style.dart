/// Defines the available icon style variants for transport mode icons.
///
/// Each style provides a different visual appearance while maintaining
/// semantic consistency across the application.
enum TransportIconStyle {
  /// Filled style - solid shapes with no negative space.
  ///
  /// Typically used for primary actions or highly emphasized elements
  /// to provide strong visual weight.
  filled,

  /// Rounded style - softer, friendlier appearance with rounded corners.
  ///
  /// This is the default style used throughout the application to create
  /// a modern and approachable feel.
  rounded,

  /// Outlined style - line-based icons with negative space.
  ///
  /// Useful for secondary actions or in dense UIs where a lighter
  /// visual weight is preferred to avoid overwhelming the user.
  outlined,

  /// Sharp style - angular, geometric appearance with square corners.
  ///
  /// Can be used when a more technical, industrial, or precise
  /// aesthetic is desired.
  sharp;

  /// Gets the suffix used in Material Icon names for this style.
  ///
  /// Returns an empty string for [filled], and '_rounded', '_outlined',
  /// or '_sharp' for the respective styles.
  String get suffix {
    return switch (this) {
      TransportIconStyle.filled => '',
      TransportIconStyle.rounded => '_rounded',
      TransportIconStyle.outlined => '_outlined',
      TransportIconStyle.sharp => '_sharp',
    };
  }

  /// Gets the human-readable display name for this style.
  String get displayName {
    return switch (this) {
      TransportIconStyle.filled => 'Filled',
      TransportIconStyle.rounded => 'Rounded',
      TransportIconStyle.outlined => 'Outlined',
      TransportIconStyle.sharp => 'Sharp',
    };
  }

  /// Gets the string representation of this style.
  ///
  /// Returns the lowercase name of the style (e.g., 'rounded').
  @override
  String toString() => name;
}
