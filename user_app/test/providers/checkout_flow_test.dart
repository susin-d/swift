import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/models/menu_model.dart';
import 'package:mobile_app/providers/cart_provider.dart';

MenuItemModel _makeItem({
  required String id,
  required String name,
  required double price,
}) => MenuItemModel(id: id, menuId: 'menu-1', name: name, price: price);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CheckoutFlow — cart to order transition', () {
    test('calculates correct totals from cart items', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Add samosa (30) x 2 + lassi (50) x 1
      container
          .read(cartProvider.notifier)
          .addItem(_makeItem(id: 'i1', name: 'Samosa', price: 30));
      container
          .read(cartProvider.notifier)
          .addItem(_makeItem(id: 'i1', name: 'Samosa', price: 30));
      container
          .read(cartProvider.notifier)
          .addItem(_makeItem(id: 'i2', name: 'Lassi', price: 50));

      final cart = container.read(cartProvider);
      expect(cart['i1']!.quantity, equals(2));
      expect(cart['i2']!.quantity, equals(1));

      final notifier = container.read(cartProvider.notifier);
      expect(notifier.totalAmount, equals(110.0)); // (30*2) + 50
      expect(notifier.itemCount, equals(3));
    });

    test('clears cart after successful checkout', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(cartProvider.notifier)
          .addItem(_makeItem(id: 'i1', name: 'Samosa', price: 30));
      container
          .read(cartProvider.notifier)
          .addItem(_makeItem(id: 'i2', name: 'Lassi', price: 50));

      var cart = container.read(cartProvider);
      expect(cart.length, equals(2));

      container.read(cartProvider.notifier).clearCart();
      cart = container.read(cartProvider);
      expect(cart.isEmpty, isTrue);
    });

    test('maintains cart state across quantity updates', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(cartProvider.notifier);
      final item = _makeItem(id: 'i1', name: 'Samosa', price: 30);

      notifier.addItem(item);
      notifier.addItem(item);
      notifier.addItem(item);

      var cart = container.read(cartProvider);
      expect(cart['i1']!.quantity, equals(3));
      expect(notifier.totalAmount, equals(90.0));

      notifier.removeItem(item);
      cart = container.read(cartProvider);
      expect(cart['i1']!.quantity, equals(2));
      expect(notifier.totalAmount, equals(60.0));
    });

    test('prevents negative quantities and empty cart artifacts', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(cartProvider.notifier);
      final item = _makeItem(id: 'i1', name: 'Samosa', price: 30);

      notifier.addItem(item);
      notifier.removeItem(item);
      notifier.removeItem(item); // Double remove on non-existent

      final cart = container.read(cartProvider);
      expect(cart.isEmpty, isTrue);
      expect(notifier.itemCount, equals(0));
      expect(notifier.totalAmount, equals(0.0));
    });
  });

  group('CheckoutFlow — price validation', () {
    test('handles decimal price precision correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(cartProvider.notifier);
      notifier.addItem(_makeItem(id: 'i1', name: 'Item', price: 99.99));
      notifier.addItem(_makeItem(id: 'i2', name: 'Item2', price: 49.50));

      final total = notifier.totalAmount;
      expect(total, closeTo(149.49, 0.01));
    });

    test('supports high-value orders', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(cartProvider.notifier);
      notifier.addItem(_makeItem(id: 'i1', name: 'Premium', price: 5000.0));

      expect(notifier.totalAmount, equals(5000.0));
    });
  });
}
