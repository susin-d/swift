# Developer Guide

## Canonical References
- Full platform documentation: `PROJECT_DOCUMENTATION.md`
- API contract and endpoint details: `API_REFERENCE.md`

## Repo Structure
- `backend/` Fastify + TypeScript API.
- `user_app/` Flutter customer app.
- `vendor_app/` Flutter vendor app.
- `admin_app/` Flutter admin app.
- `supabase/` schema and migrations.

## Required Verification
Run before merge:

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

## CI Quality Gates
- Secret scanning is mandatory (`.github/workflows/secret-scan.yml`) and blocks leaked credentials.
- Backend CI must run full Jest and contract compliance suites.
- Backend CI enforces API performance budgets (`tests/api/performance_budgets.test.ts`) to catch contract payload bloat.
- Flutter CI must pass analyze + test for `user_app`, `vendor_app`, and `admin_app`.
- Any API contract changes require synchronized app consumer updates and docs updates in the same PR.

## Live API Flow Test
- Run `cd backend && npm run test:api:live:flow` to execute one live scenario: single signup attempt, user login, then endpoint sweep.
- The test writes JSON output to `backend/reports/live-api-responses-latest.json`.
- Provide optional role credentials as env vars (`LIVE_USER_*`, `LIVE_VENDOR_*`, `LIVE_ADMIN_*`) to include protected vendor/admin endpoint checks.

## Migration Order
Apply in sequence:
1. `supabase/migrations/20260405_phase1_phase2_reliability.sql`
2. `supabase/migrations/20260405_phase3_phase4_backlog.sql`
3. `supabase/migrations/20260407_custom_auth_accounts.sql`

## What This Recovery Added
- Persistent chat/support with admin support triage tooling.
- Admin promo CRUD persistence contract.
- Wallet APIs and transaction ledger model.
- Deferred user account deletion workflow.
- Growth and retention API set (referrals, loyalty, subscriptions, analytics, vendor watch).
- Advanced APIs (group order lifecycle, refunds).
- User/admin app UX updates for support, growth hub, and operational triage.

## User App UI Architecture
- `user_app/lib/core/widgets/customer_shell.dart` is the shared customer-app scaffold for the primary tabs.
- Home, Orders, Cart, and Profile should keep using the shared shell so navigation, spacing, and branded background treatment stay consistent.
- Screen-specific business logic should remain inside feature screens; shell-level code should stay focused on layout, navigation, and shared presentation only.

## Cross-App Rule
Any backend API contract change must be reflected in all impacted apps in the same change set:
- request/response payloads
- status and error shapes
- route prefixes and auth/RBAC behavior
- Auth login convention: clients call `/auth/session` against app base URL (`/api/v1`), which maps to `POST /api/v1/auth/session`.

## Documentation Rule
When code changes, update docs in the same PR:
- `README.md`
- `API_REFERENCE.md`
- `DEVELOPER_GUIDE.md`
- `PROJECT_DOCUMENTATION.md` (if behavior/scope changed)
