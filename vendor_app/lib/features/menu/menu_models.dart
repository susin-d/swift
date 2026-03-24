class MenuItem {
  final String id;
  final String menuId;
  final String name;
  final String? description;
  final double price;
  final bool isAvailable;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? categoryName;
  final String? categoryId;
  final int? categorySortOrder;
  final String? vendorId;

  MenuItem({
    required this.id,
    required this.menuId,
    required this.name,
    this.description,
    required this.price,
    required this.isAvailable,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
    this.categoryName,
    this.categoryId,
    this.categorySortOrder,
    this.vendorId,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    final availability = json['is_available'];
    final rawImageUrl = json['image_url']?.toString();
    return MenuItem(
      id: json['id']?.toString() ?? '',
      menuId: json['menu_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      isAvailable: availability == true || availability == 1 || availability?.toString().toLowerCase() == 'true',
      imageUrl: (rawImageUrl == null || rawImageUrl.trim().isEmpty) ? null : rawImageUrl,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
      categoryName: json['category']?.toString() ?? json['category_name']?.toString(),
      categoryId: json['category_id']?.toString(),
      categorySortOrder: (json['category_sort_order'] as num?)?.toInt(),
      vendorId: json['vendor_id']?.toString(),
    );
  }
}

class MenuCategory {
  final String id;
  final String vendorId;
  final String name;
  final int? sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<MenuItem> items;

  MenuCategory({
    required this.id,
    required this.vendorId,
    required this.name,
    this.sortOrder,
    this.createdAt,
    this.updatedAt,
    required this.items,
  });

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['menu_items'] as List?) ?? const [];
    return MenuCategory(
      id: json['id']?.toString() ?? '',
      vendorId: json['vendor_id']?.toString() ?? '',
      name: json['category_name']?.toString() ?? 'Category',
      sortOrder: (json['sort_order'] as num?)?.toInt(),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
        updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
      items: itemsJson
          .map((item) => MenuItem.fromJson((item as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

class MenuSnapshot {
  final List<MenuCategory> categories;
  final List<MenuItem> items;

  MenuSnapshot({required this.categories, required this.items});

  factory MenuSnapshot.fromVendorOps(Map<String, dynamic> json) {
    final categoriesJson = (json['categories'] as List?) ?? const [];
    final itemsJson = (json['items'] as List?) ?? const [];
    return MenuSnapshot(
      categories: categoriesJson
          .map((cat) => MenuCategory.fromJson((cat as Map).cast<String, dynamic>()))
          .toList(),
      items: itemsJson
          .map((item) => MenuItem.fromJson((item as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}
