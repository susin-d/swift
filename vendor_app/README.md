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

## Sprint 6 Productivity Baseline (Current)

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
