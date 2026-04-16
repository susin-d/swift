import 'package:flutter_test/flutter_test.dart';
import 'package:vendor_app/features/menu/menu_management_screen.dart';
import 'package:vendor_app/features/profile/vendor_profile_screen.dart';

void main() {
  group('Production readiness copy contracts', () {
    test('menu semantics prefixes remain stable', () {
      expect(menuCategoryCardSemanticPrefix, 'Menu category');
      expect(menuItemCardSemanticPrefix, 'Menu item');
    });

    test('profile error state messaging remains actionable', () {
      expect(vendorProfileErrorTitle, 'Unable to load vendor profile');
      expect(vendorProfileErrorActionLabel, 'Retry');
    });
  });
}
