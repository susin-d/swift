# Admin Dashboard — Sprint Plan

## Stack (admin_app)
Matches the rest of the monorepo:
- Flutter Web (MaterialApp → GoRouter shell)
- Riverpod for state
- Dio for HTTP
- flutter_secure_storage for JWT
- shimmer for loading skeletons
- intl for currency/date formatting

---

## Sprint 1 — Auth Integration + GoRouter Shell
**Goal:** Replace the stub login with a real session, guard every route, and wire the sidebar nav.

### Tasks
- [ ] Add packages: `flutter_riverpod`, `go_router`, `dio`, `flutter_secure_storage`, `intl` to pubspec.yaml
- [ ] `core/network/api_client.dart` — Dio instance with base URL + auth header interceptor
- [ ] `core/network/api_exception.dart` — typed error wrapper
- [ ] `features/auth/data/models/admin_session.dart` — `AdminSession` (token, userId, email, role)
- [ ] `features/auth/data/services/auth_service.dart` — `POST /api/v1/auth/login`, stores JWT
- [ ] `features/auth/presentation/providers/auth_provider.dart` — `authStateProvider` (AsyncNotifier)
- [ ] `core/config/app_router.dart` — GoRouter with shell route, auth redirect guard
- [ ] Wire `LoginScreen` submit to `authStateProvider.login()`
- [ ] Add logout action to sidebar user popup
- [ ] Smoke test: login form posts to mock service, guard redirects unauthenticated

### Acceptance
- Real `POST /api/v1/auth/login` call with role check (reject non-admin)
- JWT stored in secure storage, restored on cold start
- All sidebar routes navigate correctly
- Unauthenticated deep-link → `/login`
- `flutter analyze` clean, `flutter test` green

---

## Sprint 2 — Live Dashboard Data
**Goal:** Replace every hardcoded stat with real backend data.

### Tasks
- [ ] `features/dashboard/data/models/dashboard_summary.dart` — typed DTO from `/api/v1/admin/dashboard/summary`
- [ ] `features/dashboard/data/models/chart_data.dart` — DTO from `/api/v1/admin/charts`
- [ ] `features/dashboard/data/services/dashboard_service.dart` — two Dio calls
- [ ] `features/dashboard/presentation/providers/dashboard_provider.dart` — AsyncNotifier
- [ ] Wire `_StatCard` values from provider (show shimmer while loading)
- [ ] Wire `_HeroBanner` critical-queue counter from pending vendor + delayed order counts
- [ ] Wire `_OperationsPanel` from live delayed-order feed
- [ ] Wire `_WatchlistPanel` from pending vendor list
- [ ] Add `_ErrorView` + retry button
- [ ] Add `ShimmerCard` skeleton for stat cards and panels

### Acceptance
- Dashboard shows real numbers from backend
- Shimmer appears while fetching, error state on failure
- Pull-to-refresh on dashboard body

---

## Sprint 3 — Vendors Screen
**Goal:** List all vendors; surface pending approvals with one-tap approve/reject.

### Tasks
- [ ] `features/vendors/data/models/admin_vendor_dto.dart`
- [ ] `features/vendors/data/services/vendors_service.dart` — list + approve + reject
- [ ] `features/vendors/presentation/providers/vendors_provider.dart`
- [ ] `features/vendors/presentation/screens/vendors_list_screen.dart`
  - Pending approvals section at top (highlighted amber)
  - Full vendor table below
  - Status chip (approved / pending / rejected)
  - Approve / Reject inline buttons with `ConfirmDialog`
- [ ] `features/vendors/presentation/screens/vendor_detail_screen.dart` — slide-in panel
  - Vendor name, owner email, cuisine, menu item count, order count, join date
- [ ] Add Vendors route to GoRouter shell
- [ ] Unit test: approve button calls service, list refreshes

### Acceptance
- Pending vendors shown at top in amber highlight
- Approve/Reject requires confirmation
- Detail panel opens without full navigation
- Table paginates (20 per page)

---

## Sprint 4 — Orders Screen
**Goal:** Live order table with filtering and a detail drawer.

### Tasks
- [ ] `features/orders/data/models/admin_order_dto.dart`
- [ ] `features/orders/data/services/orders_service.dart` — list + cancel
- [ ] `features/orders/presentation/providers/orders_provider.dart`
- [ ] `features/orders/presentation/screens/orders_list_screen.dart`
  - Filter chips: All / Pending / Preparing / Ready / Completed / Cancelled
  - Status colour-coded chips per row
  - Delayed badge (red) if order age > SLA threshold
- [ ] `features/orders/presentation/widgets/order_detail_drawer.dart`
  - Item list, totals, status timeline, vendor + user info
  - Cancel action with confirm dialog
- [ ] Add Orders route to GoRouter shell

### Acceptance
- Filter chips update list in-place without full reload
- Delayed orders surface with red badge automatically
- Detail drawer opens inline (no full-screen nav)
- Cancel requires confirmation and refreshes list

---

## Sprint 5 — Users Screen
**Goal:** Full user management with role assignment and block/unblock.

### Tasks
- [ ] `features/users/data/models/admin_user_dto.dart`
- [ ] `features/users/data/services/users_service.dart` — list + block + role update
- [ ] `features/users/presentation/providers/users_provider.dart`
- [ ] `features/users/presentation/screens/users_list_screen.dart`
  - Search bar (client-side filter on name/email)
  - Role chip (user / vendor / admin)
  - Block / Unblock toggle with red confirm dialog
  - Role dropdown with confirm dialog
- [ ] `features/users/presentation/screens/user_detail_screen.dart`
  - Email, join date, order count, current role, block status

### Acceptance
- Role change posts to `PATCH /api/v1/admin/users/role`
- Block/unblock is reversible with one more tap
- All destructive actions guarded by `ConfirmDialog`

---

## Sprint 6 — Finance Screen
**Goal:** Revenue summary + 7-day chart + payout list.

### Tasks
- [ ] `features/finance/data/models/revenue_summary_dto.dart`
- [ ] `features/finance/data/models/payout_dto.dart`
- [ ] `features/finance/data/services/finance_service.dart`
- [ ] `features/finance/presentation/providers/finance_provider.dart`
- [ ] `features/finance/presentation/screens/finance_screen.dart`
  - Summary cards: today / this week / this month revenue
  - Line chart: 7-day orders + revenue (using `fl_chart` or custom painter)
  - Payout table per vendor with status chip
  - Export CSV button (placeholder, logs to console until endpoint exists)
- [ ] Date range picker for custom revenue window

### Acceptance
- Chart data from `/api/v1/admin/charts`
- Payout table shows per-vendor totals
- Export button present (non-blocking placeholder)

---

## Sprint 7 — Settings + Audit Log
**Goal:** Platform-level config and a read-only audit trail.

### Tasks
- [ ] `features/settings/presentation/screens/settings_screen.dart`
  - Commission rate field (read if no settings endpoint yet)
  - Delivery fee display
  - Admin user list with inline role management
- [ ] `features/audit/presentation/screens/audit_logs_screen.dart`
  - Timestamped log of admin actions (approve, reject, block, role change)
  - Filter by admin user or action type
- [ ] Backend: `GET /api/v1/admin/audit` endpoint (log table or in-memory for now)
- [ ] Backend: `POST /api/v1/admin/settings` endpoint (guards super_admin only)

### Acceptance
- Audit log shows at minimum the actions performed in Sprints 3–5
- Settings visible to all admins, editable only by super_admin

---

## Sprint 8 — Polish, Tests, Responsive
**Goal:** Lint clean, full test coverage on critical paths, responsive on all widths.

### Tasks
- [ ] Replace `NavigationRail` on compact widths with `BottomNavigationBar`
- [ ] Fix stat card aspect ratio on narrow screens (switch to `Wrap`)
- [ ] Make delta chip colour conditional (green positive, red negative, amber warning)
- [ ] Add hero banner dynamic greeting (morning/afternoon/evening)
- [ ] Drive sidebar daily-summary footer from live provider
- [ ] `ShimmerCard` on stat cards, table rows, panels
- [ ] `_EmptyView` for all list screens
- [ ] `_ErrorView` with retry for all async providers
- [ ] Widget tests: login validation, dashboard loads with mocked provider
- [ ] Widget tests: vendors list shows approve button, confirm dialog fires
- [ ] Integration smoke test: cold start → login → dashboard → vendors
- [ ] Run full monorepo verification:
  ```powershell
  cd backend && npm test
  cd user_app && flutter analyze && flutter test
  cd vendor_app && flutter analyze && flutter test
  cd admin_app && flutter analyze && flutter test
  ```

### Acceptance
- Zero `flutter analyze` issues
- All tests green across the monorepo
- Dashboard usable at 600px width (tablet landscape)

---

## New Backend Endpoints Required

| Endpoint | Sprint | Notes |
|---|---|---|
| `GET /api/v1/admin/dashboard/summary` | 2 | Already added |
| `GET /api/v1/admin/charts` | 2 | Already exists |
| `GET /api/v1/admin/vendors/pending` | 3 | Already exists |
| `PATCH /api/v1/admin/vendors/:id/approve` | 3 | Already exists |
| `DELETE /api/v1/admin/vendors/:id` | 3 | New |
| `GET /api/v1/admin/orders` | 4 | New (paginated) |
| `PATCH /api/v1/admin/orders/:id/cancel` | 4 | New |
| `GET /api/v1/admin/users` | 5 | New (paginated) |
| `PATCH /api/v1/admin/users/:id/block` | 5 | New |
| `PATCH /api/v1/admin/users/:id/role` | 5 | Maps to existing `POST /users/role` |
| `GET /api/v1/admin/finance/summary` | 6 | New |
| `GET /api/v1/admin/finance/payouts` | 6 | New |
| `GET /api/v1/admin/audit` | 7 | New |
| `GET /api/v1/admin/settings` | 7 | New |
| `POST /api/v1/admin/settings` | 7 | New (super_admin only) |

---

## Definition of Done (all sprints)
- Code compiles with zero errors
- `flutter analyze` is clean (no warnings)
- All new screens have at least one widget test
- All backend endpoint changes have a Jest test
- AGENTS.md cross-app update rule followed for every API change
