class VendorModel {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? category;
  final bool isOpen;
  final double rating;
  final double? latitude;
  final double? longitude;

  VendorModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.category,
    this.isOpen = true,
    this.rating = 0.0,
    this.latitude,
    this.longitude,
  });

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    return VendorModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['image_url'],
      category: json['category'],
      isOpen: json['is_open'] ?? true,
      rating: (json['rating'] ?? 0.0).toDouble(),
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'category': category,
      'is_open': isOpen,
      'rating': rating,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
