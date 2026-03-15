# user_app

Flutter client for end-user food discovery, ordering, and delivery tracking in the Campus Pulse monorepo.

## Core Features

- Discovery feed with category and mood-driven browse interactions
- Vendor catalog, menu browsing, and cart/checkout flow
- Order timeline and user order history
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

## Monorepo Verification Policy

Changes that affect shared contracts or backend behavior must be validated with corresponding backend and app checks as defined in the root repository docs (`AGENTS.md`, `sprints_master.md`).
