# Features and Gaps (Live App Audit)
Date: 2026-03-19

## User App (user_app)
Innovative features (implemented)
- Mood-to-Meal intent chips on Home
- Reorder Studio card for one-tap repeat
- ETA confidence band on the Home hero
- Inline quantity stepper on menu cards
- Live courier tracking map with delivery polling

Core implemented features
- Vendor discovery feed and category browse
- Global search for dishes and vendors
- Vendor catalog, menu browsing, and cart flow
- Address book with default selection
- Payment selection (Razorpay or pay on pickup)
- Order timeline, cancellation, and history
- Favorites and notifications feed
- Promo code validation and scheduled delivery selection
- Reviews and ratings
- Profile editing and session handling
- Support screen (static actions)

Missing or not yet implemented
- In-app chat with support or courier
- Referral rewards and loyalty lifecycle
- Wallet top-up or credit management UI

## Vendor App (vendor_app)
Implemented features
- Live active-order dashboard and status updates
- Queue triage rails, sort controls, and pacing hints
- Menu category and item management (CRUD)
- Live courier location sharing for tracking
- Vendor profile management and open/close status
- Notifications inbox with device token registration

Missing or not yet implemented
- Sales analytics and payout summaries
- Staff accounts and role management
- Inventory or stock-level tracking

## Admin App (admin_app)
Implemented features
- Admin auth, session posture, and routed shell
- Dashboard summary and chart visibility
- Vendor approval and vendor management
- Orders table with cancellation reason capture
- User management and role updates
- Finance summary, payout list, and CSV export
- Settings management and audit log viewer
- Campus buildings and delivery zone management

Missing or not yet implemented
- Admin role hierarchy management (beyond role updates)
- Audit export or long-term archival tools
- Alerting for SLA breaches or fraud thresholds

## Backend API (backend)
Implemented features
- Auth, RBAC, and session enforcement
- Orders, menus, vendors, addresses, payments, reviews
- Delivery location update and retrieval
- Geofence validation for class handoff updates
- Promotions and scheduling endpoints
- Admin governance endpoints (dashboard, finance, audit, settings)
- Contract registry, changelog, and flags

Missing or not yet implemented
- Refunds and chargeback workflows
- Courier/driver management endpoints
- Webhook integrations for external systems

## Cross-App Gaps
- Dedicated courier/driver application
- Promotions and loyalty lifecycle (tiers, referrals)
