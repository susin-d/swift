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
- Remaining modules now open an interactive feature workspace with readiness checklist, quick actions, and operator notes capture.

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
	- Menu item create/edit forms support optional gallery upload with **backend storage** integration
	- Images are uploaded to Supabase Storage via `POST /vendor-ops/menu/upload-image`
	- Backend validates file size (max 5MB) and MIME type (JPEG, PNG, WebP, GIF) before storage
	- Returned HTTPS URLs point to Supabase CDN for efficient caching and delivery
	- Vendor app parses and displays `created_at` and `updated_at` for audit-friendly timelines
	- Category cards now show audit timestamps in headers
	- Menu list rows show image preview, description, and item identifier for quick audit
- Reports:
	- Download center includes CSV metadata and one-tap CSV clipboard export
- UX/A11y hardening:
	- Menu category/item controls now include clearer tooltips and semantic labels for assistive technologies
	- Queue triage rails in dashboard now expose selected-state semantics for screen readers
	- Vendor profile load failures now show actionable retry state instead of raw error text

These flows are covered by provider-level tests in `test/providers/ops_services_test.dart` and widget/copy contracts under `test/widgets/`.

## Development Commands

Run from `vendor_app/`:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Test Documentation

Run from `vendor_app/`:

```bash
flutter analyze
flutter test
```

What this covers:

- Static analysis and lint checks for vendor workflows.
- Provider, widget, and feature-level regression coverage under `test/` for queue, ops, and settings flows.

Passing criteria:

- `flutter analyze` returns no errors.
- `flutter test` completes with all tests passing.

## Monorepo Verification Policy

Changes that affect shared contracts or backend behavior must be validated with corresponding backend and app checks as defined in the repository governance docs.
