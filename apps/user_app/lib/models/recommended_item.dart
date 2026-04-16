class RecommendedVendor {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final bool isOpen;

  const RecommendedVendor({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.isOpen = true,
  });

  factory RecommendedVendor.fromJson(Map<String, dynamic> json) {
    return RecommendedVendor(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Campus Vendor',
      description: json['description']?.toString(),
      imageUrl: json['image_url']?.toString(),
      isOpen: json['is_open'] == true,
    );
  }
}

class RecommendedItem {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final String? category;
  final double score;
  final RecommendedVendor? vendor;

  const RecommendedItem({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.category,
    required this.score,
    this.vendor,
  });

  factory RecommendedItem.fromJson(Map<String, dynamic> json) {
    final vendorJson = json['vendor'];
    final recommendationJson = json['recommendation'];
    final signalsJson = recommendationJson is Map ? recommendationJson : const <String, dynamic>{};

    return RecommendedItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      imageUrl: json['image_url']?.toString(),
      category: json['category']?.toString(),
      score: (signalsJson['score'] as num?)?.toDouble() ?? 0,
      vendor: vendorJson is Map<String, dynamic>
          ? RecommendedVendor.fromJson(vendorJson)
          : vendorJson is Map
              ? RecommendedVendor.fromJson(vendorJson.cast<String, dynamic>())
              : null,
    );
  }
}
