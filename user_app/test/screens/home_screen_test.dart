import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/screens/home/home_screen.dart';

void main() {
  group('Home screen UX copy contract', () {
    test('bottom nav labels are present and ordered for clarity', () {
      expect(homeBottomNavLabels, const ['Home', 'Orders', 'Cart', 'Profile']);
    });

    test('hero has one clear primary CTA label', () {
      expect(homeHeroPrimaryCtaLabel, 'Order Now');
      expect(homeMicroAnimationDuration, const Duration(milliseconds: 180));
    });

    test('error states use actionable and friendly copy', () {
      expect(homeCategoriesErrorText, 'Unable to load categories right now.');
      expect(homeReorderErrorText, 'Reorder Studio is unavailable right now.');
      expect(homeFeaturedErrorText, 'Featured items could not be loaded.');
      expect(homeReorderFailureText, 'Quick reorder failed. Please try again.');
    });

    test('onboarding tips are progressive and task-focused', () {
      expect(
        homeTipPrimaryText,
        'Tip: mood chips filter discovery, and Reorder Studio repeats your latest order quickly.',
      );
      expect(
        homeTipSecondaryText,
        'Use Home, Orders, Cart, and Profile tabs below to move through your order flow faster.',
      );
    });

    test('mood descriptions are explicit for onboarding discoverability', () {
      expect(moodDescriptionForLabel('All'), 'Browse every available item');
      expect(moodDescriptionForLabel('Comfort'), 'Hearty and filling meals');
      expect(moodDescriptionForLabel('Quick'), 'Fast bites and snacks');
      expect(moodDescriptionForLabel('Sweet'), 'Desserts and bakery picks');
      expect(moodDescriptionForLabel('Light'), 'Fresh and lighter options');
    });
  });
}
