class SearchVendor {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;

  const SearchVendor({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
  });

  factory SearchVendor.fromJson(Map<String, dynamic> json) {
    return SearchVendor(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Vendor',
      description: json['description']?.toString(),
      imageUrl: json['image_url']?.toString(),
    );
  }
}

class SearchResult {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final SearchVendor? vendor;

  const SearchResult({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.vendor,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    final vendorJson = json['vendor'];
    return SearchResult(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      imageUrl: json['image_url']?.toString(),
      vendor: vendorJson is Map ? SearchVendor.fromJson(vendorJson.cast<String, dynamic>()) : null,
    );
  }
}
