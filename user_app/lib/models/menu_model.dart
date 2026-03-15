class MenuItemModel {
  final String id;
  final String menuId;
  final String? vendorId;
  final String name;
  final String? description;
  final double price;
  final bool isAvailable;
  final String? imageUrl;
  final String? category;

  MenuItemModel({
    required this.id,
    required this.menuId,
    this.vendorId,
    required this.name,
    this.description,
    required this.price,
    this.isAvailable = true,
    this.imageUrl,
    this.category,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'],
      menuId: json['menu_id'],
      vendorId: json['vendor_id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] ?? 0.0).toDouble(),
      isAvailable: json['is_available'] ?? true,
      imageUrl: json['image_url'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'menu_id': menuId,
      'vendor_id': vendorId,
      'name': name,
      'description': description,
      'price': price,
      'is_available': isAvailable,
      'image_url': imageUrl,
      'category': category,
    };
  }
}
