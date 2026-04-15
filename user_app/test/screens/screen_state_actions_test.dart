import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/constants/app_colors.dart';
import 'package:mobile_app/screens/favorites/favorites_screen.dart';
import 'package:mobile_app/screens/notifications/notifications_screen.dart';
import 'package:mobile_app/screens/orders/order_history_screen.dart';
import 'package:mobile_app/screens/search/search_screen.dart';
import 'package:mobile_app/screens/menu/menu_screen.dart';

void main() {
  group('Screen state action labels stay actionable', () {
    test('favorites states expose clear next actions', () {
      expect(favoritesEmptyActionLabel, 'Browse vendors');
      expect(favoritesErrorActionLabel, 'Retry');
    });

    test('notification states expose clear next actions', () {
      expect(notificationsEmptyActionLabel, 'Explore menu');
      expect(notificationsErrorActionLabel, 'Retry');
    });

    test('order history states expose clear next actions', () {
      expect(orderHistoryEmptyActionLabel, 'Start ordering');
      expect(orderHistoryErrorActionLabel, 'Retry');
    });

    test('search states expose clear next actions', () {
      expect(searchErrorActionLabel, 'Try again');
      expect(searchNoMatchesActionLabel, 'Clear query');
    });

    test('list cards expose semantic prefixes for screen readers', () {
      expect(favoritesCardSemanticPrefix, 'Favorite vendor');
      expect(notificationsCardSemanticPrefix, 'Notification');
      expect(orderHistoryCardSemanticPrefix, 'Order card');
      expect(searchResultSemanticPrefix, 'Search result');
      expect(menuItemCardSemanticPrefix, 'Menu item');
    });

    test('muted text token remains readable on white backgrounds', () {
      expect(AppColors.textMuted.toARGB32(), 0xFF708090);
    });
  });
}
