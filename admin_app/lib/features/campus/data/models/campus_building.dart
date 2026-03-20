class CampusBuilding {
  final String id;
  final String name;
  final String? code;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? deliveryNotes;
  final bool isActive;

  const CampusBuilding({
    required this.id,
    required this.name,
    this.code,
    this.address,
    this.latitude,
    this.longitude,
    this.deliveryNotes,
    this.isActive = true,
  });

  factory CampusBuilding.fromJson(Map<String, dynamic> json) {
    return CampusBuilding(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString(),
      address: json['address']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      deliveryNotes: json['delivery_notes']?.toString(),
      isActive: json['is_active'] == true,
    );
  }
}
