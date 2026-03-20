# user_app

Flutter client for end-user food discovery, ordering, and delivery tracking in the Campus Pulse monorepo.

## Core Features

- Discovery feed with category and mood-driven browse interactions
- Search for dishes and vendors
- Vendor catalog, menu browsing, and cart/checkout flow
- Address book and delivery selection
- Payment selection (pay now or pay on pickup)
- Promo code validation and scheduled delivery time selection
- Order timeline, cancellation, and user order history
- Favorites and notifications feed
- Reviews and ratings
- Live courier tracking map with delivery location polling
- Shared contracts feed support (registry, changelog, flags)

## Sprint 5 Home Experience (Current)

- Mood-to-Meal chips on Home to guide intent-based vendor discovery
- Reorder Studio card driven by latest user order for faster repeat entry
- ETA confidence band surfaced in top hero area for trust messaging
- Menu decision-clarity controls: category chips, availability filter, price sort toggle
- Inline quantity stepper on menu cards for faster add/remove decisions
- Reorder Studio quick-repeat: one-tap repeat order from latest order snapshot

Primary implementation file:

- `lib/screens/home/home_screen.dart`

## Development Commands

Run from `user_app/`:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Payment configuration:
- Razorpay key can be injected at build time: `--dart-define=RAZORPAY_KEY_ID=your_key_here`

## Monorepo Verification Policy

Changes that affect shared contracts or backend behavior must be validated with corresponding backend and app checks as defined in the root repository docs (`AGENTS.md`, `sprints_master.md`).
