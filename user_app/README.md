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

## Home Experience (Current)

- Mood-to-Meal chips on Home to guide intent-based vendor discovery
- Mood chips now include tooltip guidance to improve first-time discoverability
- Reorder Studio card driven by latest user order for faster repeat entry
- Reorder Studio now includes inline "what is this" guidance for clearer value communication
- ETA confidence band surfaced in top hero area for trust messaging
- First-visit home tips card explains key discovery and reorder interactions
- Category "See All" is actionable and routes to Search for broader exploration
- Floating bottom navigation includes labels (Home, Orders, Cart, Profile) and improved semantics
- Hero section is reduced in visual density and now emphasizes a single primary CTA ("Order Now")
- Home now includes friendly retry cards for category/reorder/featured load failures and an "Explore all food" empty-state CTA
- Home onboarding tips are progressive (next/skip flow) and persisted after completion
- Quick reorder failures now show a clean retry action instead of raw error details
- Motion polish: featured section title transitions smoothly across mood filters and food cards now use subtle press feedback
- Home spacing and floating navigation insets now adapt for compact-width devices to improve small-screen usability
- Responsive width constraints are now applied across user-facing screens for better tablet and large-device readability
- Phase 2 UX polish: app-bar icon actions now include clearer tooltips on key user screens for better accessibility
- Empty/error states now include clearer next-step CTAs on Favorites, Notifications, Order History, and Search
- Support screen now supports direct backend ticket submission (`POST /api/v1/support/tickets`) alongside email, phone, and in-app FAQ actions
- Screen-list cards now include semantic labels (favorites, notifications, orders, search, and menu) for better screen-reader output
- Contrast pass: muted text token strengthened and low-contrast white-on-image labels adjusted on support/menu surfaces
- Menu decision-clarity controls: category chips, availability filter, price sort toggle
- Inline quantity stepper on menu cards for faster add/remove decisions
- Reorder Studio quick-repeat: one-tap repeat order from latest order snapshot

Primary implementation file:

- `lib/screens/home/home_screen.dart`

## Cart Feature Module Structure

The cart flow is organized by feature and layer under `lib/screens/cart/`:

- `cart_screen.dart`: screen coordinator (state wiring, checkout and payment orchestration)
- `models/pending_order.dart`: payment-to-order handoff model
- `utils/cart_eta.dart`: ETA confidence helpers
- `widgets/payment_sheet.dart`: payment method selector sheet
- `widgets/cart_empty_view.dart`: empty basket UI
- `widgets/cart_address_row.dart`: address status and management row
- `widgets/cart_schedule_row.dart`: scheduled time row
- `widgets/cart_food_order_row.dart`: in-summary food item controls
- `widgets/cart_promo_row.dart`: promo input and applied state UI

## Development Commands

Run from `user_app/`:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Payment configuration:


// Supabase configuration is now handled by the backend. No direct keys or dart-define needed in the app.

## Monorepo Verification Policy

Changes that affect shared contracts or backend behavior must be validated with corresponding backend and app checks as defined in the root repository docs (`AGENTS.md`, `sprints_master.md`).
