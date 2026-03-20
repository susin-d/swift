class CampusBuilding {
  final String id;
  final String name;
  final String? code;

  const CampusBuilding({
    required this.id,
    required this.name,
    this.code,
  });

  factory CampusBuilding.fromJson(Map<String, dynamic> json) {
    return CampusBuilding(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString(),
    );
  }
}
