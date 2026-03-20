class VendorProfile {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final bool isOpen;

  VendorProfile({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.isOpen,
  });

  factory VendorProfile.fromJson(Map<String, dynamic> json) {
    return VendorProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Vendor',
      description: json['description']?.toString(),
      imageUrl: json['image_url']?.toString(),
      isOpen: json['is_open'] == true,
    );
  }
}
