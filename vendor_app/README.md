# vendor_app

Flutter client for vendor operations in the Campus Pulse monorepo.

## Core Features

- Vendor authentication and session handling
- Live active-order dashboard and status updates
- Live courier location sharing for delivery tracking
- Menu category + item management (CRUD)
- Vendor profile and open/close status management
- Notifications inbox with device token registration
- Scheduled order visibility in the queue
- Productivity-focused queue interactions

## Productivity Baseline (Current)

- Rush Mode toggle for high-throughput queue handling
- Prep-time suggestion chips for faster pacing decisions
- Swipe-to-progress order status action on queue cards
- One-swipe 86 hold action for rapid exception handling
- Queue triage rails with live counts and fast status filters
- Sort controls for ready-first, newest, and high-value queue review
- Prep-time assist and SLA pacing summary for at-risk order prioritization
- Protected 86 workflow with confirmation, undo recovery, and swipe-action locking

Primary implementation file:

- `lib/features/dashboard/dashboard_screen.dart`

## Sidebar Navigation Coverage

The vendor sidebar now includes complete grouped navigation for:

- Core Navigation
- Menu & Inventory
- Finance & Payments
- Analytics
- Operations
- Growth & Marketing
- Store Management
- Staff & Access Control
- Notifications
- Reports
- Preferences
- Support & Legal
- Account

Current implementation behavior:

- Existing shipped modules open their concrete screens (dashboard, menu, profile, notifications, legal/privacy).
- Dedicated section screens are now available for finance, analytics, staff/access control, reports, and preferences.
- Dedicated item-level sub-routes are now available for those sections (for example finance earnings, payouts, transactions, tax reports).
- Finance, analytics, staff, reports, and preferences sub-routes are wired to dedicated Riverpod providers backed by vendor-ops API endpoints.
- Remaining not-yet-built modules still route to a dedicated placeholder page so every listed sidebar item is discoverable and clickable.

## Production Readiness Updates

The following vendor operations are now wired to backend write endpoints with in-app success/error handling:

- Preferences persistence:
	- Language selection save
	- Theme settings save (dark mode and high contrast)
	- App settings save (compact cards, silent alerts, notifications, auto-print)
- Staff operations:
	- Invite staff by email and role
	- Create, edit, and delete staff members
	- Add and update role definitions with permissions
- Menu data completeness:
	- Vendor menu snapshots now map all menu category and menu item columns from DB-backed payloads
	- Menu item create/edit forms support optional gallery upload and persist generated image URLs (`image_url`)
	- Image URL validation accepts only `https://` and `data:image/...;base64,...` values
	- Menu payload models expose `created_at` and `updated_at` for audit-friendly timelines
	- Menu list rows now show image preview, description, and item identifier for quick audit
- Reports:
	- Download center includes CSV metadata and one-tap CSV clipboard export

These flows are covered by provider-level tests in `test/providers/ops_services_test.dart`.

## Development Commands

Run from `vendor_app/`:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Monorepo Verification Policy

Changes that affect shared contracts or backend behavior must be validated with corresponding backend and app checks as defined in the repository governance docs.
