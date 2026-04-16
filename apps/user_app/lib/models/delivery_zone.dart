class DeliveryZone {
  final String id;
  final String name;
  final String? buildingId;
  final bool isActive;

  const DeliveryZone({
    required this.id,
    required this.name,
    this.buildingId,
    this.isActive = true,
  });

  factory DeliveryZone.fromJson(Map<String, dynamic> json) {
    return DeliveryZone(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      buildingId: json['building_id']?.toString(),
      isActive: json['is_active'] == true,
    );
  }
}
