class MenuItem {
  final String id;
  final String menuId;
  final String name;
  final String? description;
  final double price;
  final bool isAvailable;
  final String? imageUrl;

  MenuItem({
    required this.id,
    required this.menuId,
    required this.name,
    this.description,
    required this.price,
    required this.isAvailable,
    this.imageUrl,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id']?.toString() ?? '',
      menuId: json['menu_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      isAvailable: json['is_available'] == true,
      imageUrl: json['image_url']?.toString(),
    );
  }
}

class MenuCategory {
  final String id;
  final String name;
  final int? sortOrder;
  final List<MenuItem> items;

  MenuCategory({
    required this.id,
    required this.name,
    this.sortOrder,
    required this.items,
  });

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['menu_items'] as List?) ?? const [];
    return MenuCategory(
      id: json['id']?.toString() ?? '',
      name: json['category_name']?.toString() ?? 'Category',
      sortOrder: (json['sort_order'] as num?)?.toInt(),
      items: itemsJson
          .map((item) => MenuItem.fromJson((item as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

class MenuSnapshot {
  final List<MenuCategory> categories;

  MenuSnapshot({required this.categories});

  factory MenuSnapshot.fromVendorOps(Map<String, dynamic> json) {
    final categoriesJson = (json['categories'] as List?) ?? const [];
    return MenuSnapshot(
      categories: categoriesJson
          .map((cat) => MenuCategory.fromJson((cat as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}
