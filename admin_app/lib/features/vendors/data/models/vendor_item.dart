class VendorItem {
  const VendorItem({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.isOpen,
    required this.createdAt,
    required this.ownerName,
    required this.ownerEmail,
  });

  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final bool isOpen;
  final DateTime? createdAt;
  final String ownerName;
  final String ownerEmail;

  factory VendorItem.fromJson(Map<String, dynamic> json) {
    final owner = (json['owner'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

    return VendorItem(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? 'Unnamed vendor',
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      isOpen: (json['is_open'] as bool?) ?? false,
      createdAt: DateTime.tryParse((json['created_at'] as String?) ?? ''),
      ownerName: (owner['name'] as String?) ?? 'Unknown',
      ownerEmail: (owner['email'] as String?) ?? 'N/A',
    );
  }
}
