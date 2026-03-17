import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/providers/cart_provider.dart';
import 'package:mobile_app/models/menu_model.dart';

MenuItemModel _makeItem({required String id, required String name, required double price}) =>
    MenuItemModel(id: id, menuId: 'menu-1', name: name, price: price);

void main() {
  group('CartNotifier — addItem', () {
    test('adds a new item to empty cart', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final item = _makeItem(id: 'i1', name: 'Samosa', price: 30);
      container.read(cartProvider.notifier).addItem(item);

      final cart = container.read(cartProvider);
      expect(cart.length, equals(1));
      expect(cart['i1']!.quantity, equals(1));
      expect(cart['i1']!.item.name, equals('Samosa'));
    });

    test('increments quantity when same item added again', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final item = _makeItem(id: 'i1', name: 'Samosa', price: 30);
      container.read(cartProvider.notifier).addItem(item);
      container.read(cartProvider.notifier).addItem(item);

      expect(container.read(cartProvider)['i1']!.quantity, equals(2));
    });

    test('adds multiple distinct items as separate entries', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(cartProvider.notifier).addItem(_makeItem(id: 'i1', name: 'Samosa', price: 30));
      container.read(cartProvider.notifier).addItem(_makeItem(id: 'i2', name: 'Lassi', price: 50));

      final cart = container.read(cartProvider);
      expect(cart.length, equals(2));
      expect(cart.containsKey('i1'), isTrue);
      expect(cart.containsKey('i2'), isTrue);
    });
  });

  group('CartNotifier — removeItem', () {
    test('decrements quantity when quantity > 1', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final item = _makeItem(id: 'i1', name: 'Samosa', price: 30);
      container.read(cartProvider.notifier).addItem(item);
      container.read(cartProvider.notifier).addItem(item);
      container.read(cartProvider.notifier).removeItem(item);

      expect(container.read(cartProvider)['i1']!.quantity, equals(1));
    });

    test('removes item entirely when quantity reaches 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final item = _makeItem(id: 'i1', name: 'Samosa', price: 30);
      container.read(cartProvider.notifier).addItem(item);
      container.read(cartProvider.notifier).removeItem(item);

      expect(container.read(cartProvider).containsKey('i1'), isFalse);
    });

    test('remove on absent item leaves cart unchanged', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(cartProvider.notifier).addItem(_makeItem(id: 'i1', name: 'Samosa', price: 30));
      container.read(cartProvider.notifier).removeItem(_makeItem(id: 'missing', name: 'Ghost', price: 0));

      expect(container.read(cartProvider).length, equals(1));
    });
  });

  group('CartNotifier — clearCart', () {
    test('resets cart to empty map', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(cartProvider.notifier).addItem(_makeItem(id: 'i1', name: 'Samosa', price: 30));
      container.read(cartProvider.notifier).addItem(_makeItem(id: 'i2', name: 'Lassi', price: 50));
      container.read(cartProvider.notifier).clearCart();

      expect(container.read(cartProvider), isEmpty);
    });
  });

  group('CartNotifier — totalAmount', () {
    test('returns 0 for empty cart', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(cartProvider.notifier).totalAmount, equals(0.0));
    });

    test('sums price * quantity for single item', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(cartProvider.notifier).addItem(_makeItem(id: 'i1', name: 'Samosa', price: 30));
      container.read(cartProvider.notifier).addItem(_makeItem(id: 'i1', name: 'Samosa', price: 30));

      expect(container.read(cartProvider.notifier).totalAmount, equals(60.0));
    });

    test('sums across multiple distinct items', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(cartProvider.notifier).addItem(_makeItem(id: 'i1', name: 'Samosa', price: 30));
      container.read(cartProvider.notifier).addItem(_makeItem(id: 'i2', name: 'Lassi', price: 50));

      expect(container.read(cartProvider.notifier).totalAmount, equals(80.0));
    });
  });

  group('CartNotifier — itemCount', () {
    test('returns 0 for empty cart', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(cartProvider.notifier).itemCount, equals(0));
    });

    test('returns total quantity across all items', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final item1 = _makeItem(id: 'i1', name: 'Samosa', price: 30);
      final item2 = _makeItem(id: 'i2', name: 'Lassi', price: 50);

      container.read(cartProvider.notifier).addItem(item1);
      container.read(cartProvider.notifier).addItem(item1);
      container.read(cartProvider.notifier).addItem(item2);

      expect(container.read(cartProvider.notifier).itemCount, equals(3));
    });
  });
}
