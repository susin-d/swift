# Swift Platform Documentation (Complete Snapshot)

Last updated: 2026-04-05

## 1) Scope
This document is the consolidated reference for:
- `backend/`
- `user_app/`
- `vendor_app/`
- `admin_app/`
- Supabase migrations and operational rollout notes

It captures completed work, API surface, app behavior, testing expectations, deployment notes, and pending items.

## 2) Architecture
- Backend: Fastify + TypeScript (`backend/`)
- Data/Auth: Supabase PostgreSQL + Supabase Auth
- Client apps:
  - User: Flutter (`user_app/`)
  - Vendor: Flutter (`vendor_app/`)
  - Admin: Flutter (`admin_app/`)

## 3) Feature Delivery Status

### 3.1 Reliability and Core Ops
- Completed: Chat/support moved from ephemeral memory to DB-backed persistence.
- Completed: Admin support inbox routes and admin UI triage flow.
- Completed: Admin promo endpoints return persisted promo entities instead of stub responses.

### 3.2 User Trust and Checkout
- Completed: Wallet APIs (balance, topup, transactions).
- Completed: User profile wallet balance visibility.
- Completed: Checkout recovery options for payment failure (retry/fallback in user cart flow).
- Completed: Support “My Tickets” timeline in user app.

### 3.3 Growth and Retention
- Completed: Referrals (generate, lookup, redeem).
- Completed: Loyalty (tier read + points mutation).
- Completed: Spending analytics (summary + vendor analytics).
- Completed: Vendor watch/unwatch endpoints.
- Completed: Subscription create/list foundation plus lifecycle endpoints (renew/cancel/entitlements).

### 3.4 Advanced Backlog APIs
- Completed: Group-order create/split plus lifecycle endpoints (join/leave/get/close).
- Completed: Refund request and user refund listing.
- Completed: Admin refund listing/status update endpoints.

### 3.5 Account Deletion
- Completed: Deferred account deletion request/status/cancel API flow.
- Completed: Admin due-deletion processing and reminder listing endpoints.

## 4) Backend API Surface (New/Finalized)

### 4.1 Chat and Support
- `POST /api/v1/chat/rooms`
- `GET /api/v1/chat/rooms/:id/messages`
- `POST /api/v1/chat/rooms/:id/messages`
- `POST /api/v1/support/tickets`
- `GET /api/v1/support/tickets`
- `GET /api/v1/support/tickets/me`
- `PATCH /api/v1/support/tickets/:id`
- `GET /api/v1/support/tickets/:id/timeline`
- `GET /api/v1/admin/support/tickets`
- `GET /api/v1/admin/support/summary`
- `PATCH /api/v1/admin/support/tickets/:id`

### 4.2 Promos (Admin)
- `GET /api/v1/admin/promos`
- `POST /api/v1/admin/promos`
- `PATCH /api/v1/admin/promos/:id`

### 4.3 Wallet
- `GET /api/v1/wallet/balance`
- `PATCH /api/v1/wallet/topup`
- `GET /api/v1/wallet/transactions`

### 4.4 Account Deletion
- `DELETE /api/v1/users/me`
- `GET /api/v1/users/me/deletion`
- `PATCH /api/v1/users/me/deletion/cancel`
- `POST /api/v1/admin/users/deletions/process-due`
- `GET /api/v1/admin/users/deletions/reminders`

### 4.5 Growth, Retention, Advanced Flows
- `GET /api/v1/analytics/spending`
- `GET /api/v1/analytics/vendors`
- `POST /api/v1/referrals/generate`
- `GET /api/v1/referrals/code/:code`
- `POST /api/v1/referrals/redeem`
- `GET /api/v1/loyalty/tier`
- `POST /api/v1/loyalty/points`
- `GET /api/v1/subscriptions`
- `POST /api/v1/subscriptions/create`
- `PATCH /api/v1/subscriptions/:id/renew`
- `PATCH /api/v1/subscriptions/:id/cancel`
- `GET /api/v1/subscriptions/entitlements`
- `POST /api/v1/vendors/:id/watch`
- `DELETE /api/v1/vendors/:id/watch`
- `POST /api/v1/orders/group`
- `GET /api/v1/orders/:id/group`
- `POST /api/v1/orders/:id/group/join`
- `POST /api/v1/orders/:id/group/leave`
- `POST /api/v1/orders/:id/group/close`
- `PATCH /api/v1/orders/:id/split`
- `POST /api/v1/orders/:id/refund`
- `GET /api/v1/refunds/me`
- `GET /api/v1/refunds/admin`
- `PATCH /api/v1/refunds/:id/status`

## 5) Data and Migration Notes
Migrations:
- `supabase/migrations/20260405_phase1_phase2_reliability.sql`
- `supabase/migrations/20260405_phase3_phase4_backlog.sql`

Added/updated persistence includes:
- Chat/support durability tables and indexes.
- Wallet transaction ledger and idempotency key index.
- User deletion request lifecycle store.
- Referral, loyalty, subscriptions, vendor watch, group order, refund tables.
- Support ticket event timeline table.

## 6) App-Level Changes

### 6.1 User App
- Support screen:
  - Ticket submit + “My Tickets” timeline + close ticket.
- Cart screen:
  - Payment failure recovery actions.
- Profile:
  - Wallet balance shown.
  - Growth Hub entry and view.
- Growth Hub:
  - Spending summary, referrals, loyalty, subscriptions, entitlements, refunds, deletion controls.

### 6.2 Admin App
- Support Inbox screen:
  - Ticket list triage actions.
  - Filter controls (status/priority).
  - Summary metrics card.
- Navigation/router updated to expose support inbox.

### 6.3 Vendor App
- No major new feature module in this recovery; verified for contract/regression impact.

## 7) UI/UX Updates
- Support timeline bottom sheet made responsive to viewport height instead of fixed-height list.
- Admin support filter controls converted to form-style dropdowns with bounded widths for better small-screen behavior.
- General focus: reduce overflow risk, improve readability, preserve mobile/desktop compatibility.

## 8) Testing and Verification

Required commands:
```powershell
cd C:\project\swift\backend
npm test

cd C:\project\swift\user_app
flutter analyze
flutter test

cd C:\project\swift\vendor_app
flutter analyze
flutter test

cd C:\project\swift\admin_app
flutter analyze
flutter test
```

Current implementation status:
- Backend test suite: green after stabilizing network-dependent contract test behavior.
- Vendor tests: green in recent run.
- User/Admin suites received follow-up fixes for latest UI changes; re-run full final gate on your environment before merge.

## 9) Rollout and Rollback

### Rollout
1. Apply migrations in order:
   - `20260405_phase1_phase2_reliability.sql`
   - `20260405_phase3_phase4_backlog.sql`
2. Deploy backend.
3. Deploy app updates (user/admin/vendor) aligned with new contracts.
4. Run verification suite.

### Rollback
1. Roll back backend deployment.
2. Revert app deployments that depend on new routes.
3. For DB rollback, disable consumers first; then apply table/index rollback scripts per environment policy.

## 10) Remaining Gaps / Follow-Up
- Final full re-run of all Flutter tests/analyzers after latest single-shot UI and growth-flow changes.
- Optional hardening:
  - richer support SLA metrics
  - wallet reconciliation callbacks from payment provider webhooks
  - expanded analytics cards in user app
  - deeper admin refund workflow reporting

## 11) Canonical File Map
- Backend:
  - `backend/src/controllers/chatController.ts`
  - `backend/src/controllers/walletController.ts`
  - `backend/src/controllers/userAccountController.ts`
  - `backend/src/controllers/growthController.ts`
  - `backend/src/routes/chat.ts`
  - `backend/src/routes/wallet.ts`
  - `backend/src/routes/users.ts`
  - `backend/src/routes/growth.ts`
  - `backend/src/modules/admin/admin.routes.ts`
- User app:
  - `user_app/lib/screens/support/support_screen.dart`
  - `user_app/lib/screens/cart/cart_screen.dart`
  - `user_app/lib/screens/profile/profile_screen.dart`
  - `user_app/lib/screens/profile/growth_hub_screen.dart`
  - `user_app/lib/services/support_service.dart`
  - `user_app/lib/services/growth_service.dart`
- Admin app:
  - `admin_app/lib/features/support/presentation/screens/support_inbox_screen.dart`
- DB migrations:
  - `supabase/migrations/20260405_phase1_phase2_reliability.sql`
  - `supabase/migrations/20260405_phase3_phase4_backlog.sql`
