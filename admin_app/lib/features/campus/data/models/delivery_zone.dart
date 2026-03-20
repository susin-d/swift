class DeliveryZone {
  final String id;
  final String name;
  final String? buildingId;
  final bool isActive;
  final Map<String, dynamic>? geojson;

  const DeliveryZone({
    required this.id,
    required this.name,
    this.buildingId,
    this.isActive = true,
    this.geojson,
  });

  factory DeliveryZone.fromJson(Map<String, dynamic> json) {
    return DeliveryZone(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      buildingId: json['building_id']?.toString(),
      isActive: json['is_active'] == true,
      geojson: json['geojson'] is Map<String, dynamic> ? json['geojson'] as Map<String, dynamic> : null,
    );
  }
}
