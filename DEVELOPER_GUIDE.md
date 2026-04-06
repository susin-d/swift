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

## Migration Order
Apply in sequence:
1. `supabase/migrations/20260405_phase1_phase2_reliability.sql`
2. `supabase/migrations/20260405_phase3_phase4_backlog.sql`

## What This Recovery Added
- Persistent chat/support with admin support triage tooling.
- Admin promo CRUD persistence contract.
- Wallet APIs and transaction ledger model.
- Deferred user account deletion workflow.
- Growth and retention API set (referrals, loyalty, subscriptions, analytics, vendor watch).
- Advanced APIs (group order lifecycle, refunds).
- User/admin app UX updates for support, growth hub, and operational triage.

## Cross-App Rule
Any backend API contract change must be reflected in all impacted apps in the same change set:
- request/response payloads
- status and error shapes
- route prefixes and auth/RBAC behavior

## Documentation Rule
When code changes, update docs in the same PR:
- `README.md`
- `API_REFERENCE.md`
- `DEVELOPER_GUIDE.md`
- `PROJECT_DOCUMENTATION.md` (if behavior/scope changed)
