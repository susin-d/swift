class DeliveryLocation {
  final double lat;
  final double lng;
  final DateTime? updatedAt;

  const DeliveryLocation({
    required this.lat,
    required this.lng,
    this.updatedAt,
  });

  factory DeliveryLocation.fromJson(Map<String, dynamic> json) {
    final lat = _parseDouble(json['lat']);
    final lng = _parseDouble(json['lng']);
    if (lat == null || lng == null) {
      throw const FormatException('Invalid delivery location');
    }

    return DeliveryLocation(
      lat: lat,
      lng: lng,
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
