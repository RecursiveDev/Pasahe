/// Enum representing different discount types for transportation fares.
/// Based on Philippine law (RA 11314, RA 9994, RA 7277), eligible users
/// receive a 20% discount on all public transportation fares.
enum DiscountType {
  /// Standard fare - no discount applied
  standard,
  
  /// Student discount - 20% off (RA 11314)
  /// Applies to elementary, secondary, technical-vocational, and undergraduate students
  student,
  
  /// Senior citizen discount - 20% off (RA 9994)
  /// Applies to Filipino citizens aged 60 years or older
  senior,
  
  /// Person with Disability discount - 20% off (RA 7277, as amended)
  /// Requires PWD ID issued by LGU/NCDA
  pwd,
}

/// Extension to provide display-friendly names for DiscountType
extension DiscountTypeExtension on DiscountType {
  /// Returns a user-friendly display name for the discount type
  String get displayName {
    switch (this) {
      case DiscountType.standard:
        return 'Regular';
      case DiscountType.student:
        return 'Student';
      case DiscountType.senior:
        return 'Senior Citizen';
      case DiscountType.pwd:
        return 'PWD';
    }
  }
  
  /// Returns true if this discount type is eligible for the 20% fare discount
  bool get isEligibleForDiscount {
    return this != DiscountType.standard;
  }
  
  /// Returns the discount multiplier (0.80 for 20% discount, 1.0 for no discount)
  double get fareMultiplier {
    return isEligibleForDiscount ? 0.80 : 1.0;
  }
}