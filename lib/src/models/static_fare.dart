class StaticFare {
  final String origin;
  final String destination;
  final double price;
  final String? operator;

  StaticFare({
    required this.origin,
    required this.destination,
    required this.price,
    this.operator,
  });

  factory StaticFare.fromJson(Map<String, dynamic> json) {
    return StaticFare(
      origin: json['origin'] as String,
      destination: json['destination'] as String,
      price: (json['price'] as num).toDouble(),
      operator: json['operator'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'origin': origin,
      'destination': destination,
      'price': price,
      if (operator != null) 'operator': operator,
    };
  }
}