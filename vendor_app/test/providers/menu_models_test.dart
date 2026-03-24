import 'package:flutter_test/flutter_test.dart';
import 'package:vendor_app/features/menu/menu_models.dart';

void main() {
  group('MenuSnapshot.fromVendorOps', () {
    test('maps category and item schema columns including image metadata', () {
      final snapshot = MenuSnapshot.fromVendorOps({
        'categories': [
          {
            'id': 'cat-1',
            'vendor_id': 'vendor-1',
            'category_name': 'Burgers',
            'sort_order': 2,
            'created_at': '2026-03-24T10:00:00.000Z',
            'updated_at': '2026-03-24T10:30:00.000Z',
            'menu_items': [
              {
                'id': 'item-1',
                'menu_id': 'cat-1',
                'name': 'Cheese Burger',
                'description': 'Double patty with cheese',
                'price': 149.0,
                'is_available': true,
                'image_url': 'https://cdn.example.com/items/item-1.png',
                'created_at': '2026-03-24T10:00:00.000Z',
                'updated_at': '2026-03-24T10:30:00.000Z',
              }
            ],
          }
        ],
        'items': [
          {
            'id': 'item-1',
            'menu_id': 'cat-1',
            'name': 'Cheese Burger',
            'description': 'Double patty with cheese',
            'price': 149.0,
            'is_available': true,
            'image_url': 'https://cdn.example.com/items/item-1.png',
            'category': 'Burgers',
            'category_name': 'Burgers',
            'category_id': 'cat-1',
            'category_sort_order': 2,
            'vendor_id': 'vendor-1',
            'created_at': '2026-03-24T10:00:00.000Z',
            'updated_at': '2026-03-24T10:30:00.000Z',
          }
        ],
      });

      expect(snapshot.categories, hasLength(1));
      expect(snapshot.items, hasLength(1));

      final category = snapshot.categories.first;
      final item = category.items.first;
      final flatItem = snapshot.items.first;

      expect(category.id, 'cat-1');
      expect(category.vendorId, 'vendor-1');
      expect(category.name, 'Burgers');
      expect(category.sortOrder, 2);
      expect(category.createdAt?.toIso8601String(), '2026-03-24T10:00:00.000Z');
      expect(category.updatedAt?.toIso8601String(), '2026-03-24T10:30:00.000Z');

      expect(item.id, 'item-1');
      expect(item.menuId, 'cat-1');
      expect(item.name, 'Cheese Burger');
      expect(item.description, 'Double patty with cheese');
      expect(item.price, 149.0);
      expect(item.isAvailable, true);
      expect(item.imageUrl, 'https://cdn.example.com/items/item-1.png');
      expect(item.createdAt?.toIso8601String(), '2026-03-24T10:00:00.000Z');
      expect(item.updatedAt?.toIso8601String(), '2026-03-24T10:30:00.000Z');

      expect(flatItem.categoryName, 'Burgers');
      expect(flatItem.categoryId, 'cat-1');
      expect(flatItem.categorySortOrder, 2);
      expect(flatItem.vendorId, 'vendor-1');
    });
  });
}
