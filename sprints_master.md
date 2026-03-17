# Unified Sprint Plan and Execution Board

This file combines planning, execution, and live sprint tracking previously split across:

- sprints_master.md (this file)
- sprints_kanban.md (daily operational board)

Status:

- Archived and removed: sprints.md, sprints_execution.md
- Active: sprints_master.md, sprints_kanban.md

## Program Objective

Create a coordinated roadmap to improve UI/UX quality, frontend architecture, backend robustness, and cross-app consistency for:

- backend
- user_app
- vendor_app
- admin_app

## Success Metrics

- 0 critical production defects per sprint release
- 99.9% API success rate for core flows
- < 2.0s median API response for high-traffic endpoints
- > = 90 UX performance targets on key pages/screens
  >
- > = 80% test coverage on critical business flows
  >
- flutter analyze clean for all Flutter apps and passing backend test suite

## Non-Negotiable Rules

- Any API contract change must update all impacted consumers in the same sprint.
- Shared enums/status/validation rules must remain synchronized across backend and all apps.
- Every functional, UI/UX, API, workflow, or config change must include same-sprint documentation updates.
- No sprint is complete without full monorepo verification:
  - backend: npm test
  - user_app: flutter analyze; flutter test
  - vendor_app: flutter analyze; flutter test
  - admin_app: flutter analyze; flutter test

## Signature Product Direction

- Brand concept: Campus Pulse
- Visual identity anchors:
  - Dynamic gradient system tied to state and time of day
  - Distinctive shape language (soft cards + angled section breaks)
  - Purposeful motion and staggered reveals
- Experience differentiators:
  - Context-aware UX (time and peak-hour signals)
  - Micro-personalization (favorites, repeat bundles, smart defaults)
  - Trust surfaces (SLA transparency, payout confidence, moderation traceability)

## Sprint Roadmap (S1-S10)

### Sprint 1 - Design System and UX Foundations

- Goals:
  - Establish one design language across all Flutter apps.
  - Remove inconsistent spacing, typography, and component behaviors.
- Core deliverables:
  - Shared design tokens and component standards
  - Common loading, empty, and error states
  - Accessibility baseline checks

### Sprint 2 - Navigation and Flow Clarity

- Goals:
  - Make navigation predictable and task-first in all apps.
  - Reduce taps for top workflows.
- Core deliverables:
  - User flow optimization discover -> cart -> checkout -> tracking
  - Vendor flow optimization for queue and status updates
  - Admin dashboard to action workflows

### Sprint 3 - API Contract Hardening and Governance

- Goals:
  - Stabilize API contracts and eliminate payload drift.
- Core deliverables:
  - API contract source of truth and error taxonomy alignment
  - Validation hardening and DTO normalization
  - Consumer updates across all apps

### Sprint 4 - Performance and Reliability

- Goals:
  - Improve responsiveness under load and degraded network conditions.
- Core deliverables:
  - Query optimization and pagination standards
  - Caching and request cancellation patterns
  - Perceived performance improvements in top flows

### Sprint 5 - User App Experience Upgrade

- Core deliverables:
  - Discovery, menu, checkout, and tracking improvements
  - Mood to Meal chips, Reorder Studio, ETA confidence band

### Sprint 6 - Vendor App Productivity Upgrade

- Core deliverables:
  - Queue and status productivity improvements
  - Rush Mode, prep-time suggestions, one-swipe 86 action

### Sprint 7 - Admin Governance Upgrade

- Core deliverables:
  - Moderation flow improvements and stronger audit usability
  - Settings safety and finance visibility upgrades
  - Command palette, incident board, decision preview panel

### Sprint 8 - Security, RBAC, Compliance

- Core deliverables:
  - RBAC parity and session hardening
  - Sensitive action safeguards and observability
  - Risk-scored actions and device trust model

### Sprint 9 - Quality Engineering Expansion

- Core deliverables:
  - Expanded backend and frontend test coverage
  - CI hard gates and regression protection
  - Visual regression snapshots and contract replay tests

### Sprint 10 - Launch Readiness and Improvement Loop

- Core deliverables:
  - Final UX polish and production readiness checks
  - North Star dashboards and experiment pipeline
  - In-app feedback instrumentation and triage loop

## Execution Lanes and Capacity (2-Week Sprint)

- Product: prioritization and metrics
- Design: UX strategy and design system
- Backend: APIs, validation, security
- Frontend User: user_app implementation
- Frontend Vendor: vendor_app implementation
- Frontend Admin: admin_app implementation
- QA: automation and regression gates
- DevOps: CI/CD, environments, rollback readiness

Capacity model:

- Backend: 20 points
- Frontend User: 16 points
- Frontend Vendor: 16 points
- Frontend Admin: 16 points
- Design: 10 points
- QA: 12 points
- DevOps: 8 points

## Release Governance

- Branching:
  - main protected
  - sprint/`<number>`-`<theme>` integration branches
- Merge requirements:
  - Domain lead review for impacted products
  - Green CI for all products
  - Contract checklist complete when backend APIs change
- Change windows:
  - Feature freeze by Day 10
  - Hardening only after freeze

## Live Sprint Board (Started)

### Active Sprint

- Sprint: Sprint 9
- Goal: Quality engineering expansion with stronger backend/frontend regression coverage and CI hard gates
- Dates: 2026-03-17 to 2026-03-30
- Status: In Progress

### Backlog

| ID    | Title                               | Product(s) | Owner          | Estimate | Dependency | Risk | Acceptance                                                   | Status  |
| ----- | ----------------------------------- | ---------- | -------------- | -------: | ---------- | ---- | ------------------------------------------------------------ | ------- |
| S9-02 | Expand backend controller coverage  | backend    | Backend Team   |        8 | S9-01      | Med  | High-risk controllers covered with passing unit/controller tests | Backlog |
| S9-03 | Expand user_app provider/model tests | user_app  | Frontend User  |        6 | S9-01      | Med  | Checkout/order/cart provider and model tests added and passing | Backlog |
| S9-04 | Expand vendor_app core and queue workflow tests | vendor_app | Frontend Vendor |      6 | S9-01      | Med  | Core API resilience and queue transition failure-path tests added and passing | Backlog |
| S9-05 | Expand admin_app governance tests   | admin_app  | Frontend Admin |        6 | S9-01      | Med  | Dashboard/finance/governance widget/provider coverage increased | Backlog |
| S9-06 | Full monorepo regression gate pass  | all apps + backend | QA + DevOps | 8 | S9-02,S9-03,S9-04,S9-05 | High | backend npm test + all Flutter analyze/test clean in CI and local matrix | Backlog |

### In Progress

| ID | Title | Product(s) | Owner | Started | Next Action | Status |
| -- | ----- | ---------- | ----- | ------- | ----------- | ------ |
| S9-01 | Sprint 9 coverage matrix baseline | backend, user_app, vendor_app, admin_app | Product + QA | 2026-03-17 | Finalize owners and target modules/screens for coverage expansion | In Progress |

### Sprint 9 Immediate Execution Plan

- backend
  - Expand controller/unit coverage for high-risk modules and contract replay tests.
  - Enforce CI gate parity for contract and RBAC-sensitive paths.
- admin_app
  - Increase widget and provider coverage for dashboard, finance, and governance workflows.
- user_app
  - Strengthen model/provider tests around checkout, orders, and cart correctness.
- vendor_app
  - Expand provider and queue workflow tests for status transitions and error handling.
- qa/devops
  - Maintain full monorepo verification matrix and prepare Sprint 9 closure checklist.

### Sprint 9 Kickoff Notes (2026-03-17)

- Sprint 9 moved to active execution state.
- Work sequence locked: baseline matrix first, then app/backend expansions, then full regression gate.
- Acceptance remains mandatory monorepo verification before closure.
- First coding slice started in vendor_app: ApiService resilience tests added for retry, envelope mapping, and cancel-key supersession in `vendor_app/test/core/api_service_test.dart`.
- Orders provider failure-path handling improved in `vendor_app/lib/features/orders/orders_provider.dart` so status update failures surface to state and callers.
- Queue-transition coverage expanded in `vendor_app/test/providers/orders_provider_test.dart` for patch payload verification, successful refresh, and failed status update handling.
- Dashboard widget coverage added in `vendor_app/test/widgets/dashboard_screen_test.dart` for popup-menu status updates and protected 86-hold failure feedback.
- Queue rail card layout in `vendor_app/lib/features/dashboard/dashboard_screen.dart` was tightened during Sprint 9 testing to remove overflow under constrained heights.

### Blocked

| ID | Title | Product(s) | Owner | Blocker | Since | Unblock Owner | ETA Impact |
| -- | ----- | ---------- | ----- | ------- | ----- | ------------- | ---------- |
|    |       |            |       |         |       |               |            |

### In Review

| ID | Title | Product(s) | Owner | PR/Branch | Reviewer | QA Scope | Status |
| -- | ----- | ---------- | ----- | --------- | -------- | -------- | ------ |
|    |       |            |       |           |          |          |        |

### Done

| ID    | Title                                  | Product(s)                      | Owner          | Completed On | Evidence                                                    | Status |
| ----- | -------------------------------------- | ------------------------------- | -------------- | ------------ | ----------------------------------------------------------- | ------ |
| S1-01 | Finalize design tokens                 | user_app, vendor_app, admin_app | Design Lead    | 2026-03-14   | Sprint 1 token map and component matrix committed           | Done   |
| S1-02 | Standardize button/input/card variants | user_app, vendor_app, admin_app | Frontend Guild | 2026-03-14   | Shared styles applied to top traffic screens                | Done   |
| S1-03 | Common empty/error/loading patterns    | user_app, vendor_app, admin_app | Frontend Guild | 2026-03-14   | Standardized loading and error/empty patterns in core flows | Done   |
| S1-04 | Accessibility baseline pass            | all apps                        | QA + Design    | 2026-03-14   | Initial accessibility pass and checks completed             | Done   |
| S1-05 | Visual regression baseline snapshots   | user_app, vendor_app, admin_app | QA             | 2026-03-14   | Baseline screen inventory and snapshot plan documented      | Done   |
| S2-01 | Navigation flow optimization           | user_app, vendor_app, admin_app | Frontend Guild | 2026-03-14   | Role-first route map updates and reduced action depth implemented | Done |
| S2-02 | Route guard hardening                  | backend, user_app, vendor_app, admin_app | Backend + Frontend Leads | 2026-03-14 | Deep-link-preserving login redirect behavior validated across apps | Done |
| S2-03 | Admin quick actions rail               | admin_app                        | Frontend Admin | 2026-03-14   | Dashboard quick actions rail wired for one-hop workflows | Done |
| S2-04 | Progressive disclosure navigation      | user_app, vendor_app, admin_app | Frontend Guild | 2026-03-14   | Compact and more-actions navigation patterns verified | Done |
| S2-05 | Deep-link and guard audit              | backend, user_app, vendor_app, admin_app | Backend + Frontend Leads | 2026-03-14 | Route/guard audit completed with full monorepo pass | Done |
| S3-01 | API contract source of truth update    | backend, user_app, vendor_app, admin_app | Backend + Frontend Leads | 2026-03-15 | Expanded contract registry coverage and new contracts feed endpoints (`/registry`, `/changelog`, `/flags`) | Done |
| S3-02 | Error taxonomy alignment               | backend, user_app, vendor_app, admin_app | Backend Team | 2026-03-15 | Standardized taxonomy envelope mapping (400/401/403/404/409/500) with regression tests | Done |
| S3-03 | Consumer DTO normalization             | user_app, vendor_app, admin_app | Frontend Guild | 2026-03-15 | API clients normalized for error envelope parsing and contracts feed consumption | Done |
| S3-04 | Contract changelog feed endpoint       | backend | Backend Team | 2026-03-15 | Versioned changelog feed implemented at `/api/v1/contracts/changelog` | Done |
| S3-05 | Feature-flag scaffolding for staged rollouts | backend, user_app, vendor_app, admin_app | Backend + Frontend Leads | 2026-03-15 | Contract feature flags feed implemented at `/api/v1/contracts/flags` with consumer clients | Done |
| S4-01 | Pagination standards and query optimization | backend, admin_app | Backend Team | 2026-03-15 | Shared pagination utility applied to admin list endpoints with consistent `meta` payload | Done |
| S4-02 | Retry/backoff policy unification | user_app, vendor_app, admin_app | Frontend Guild | 2026-03-15 | Bounded retry/backoff implemented for retryable network and 5xx failures | Done |
| S4-03 | Request cancellation and dedupe | user_app, vendor_app, admin_app | Frontend Guild | 2026-03-15 | Superseded request cancellation added in user/vendor clients and GET dedupe in admin client | Done |
| S4-04 | Contracts feed caching | user_app, vendor_app, admin_app | Frontend Guild | 2026-03-15 | TTL cache and force-refresh support added for contracts registry/changelog/flags services | Done |
| S4-05 | Reliability governance and verification | backend, user_app, vendor_app, admin_app | QA + DevOps | 2026-03-15 | Registry/changelog/flags/docs updated and full monorepo verification passed | Done |
| S5-01 | Discovery and intent-driven browse | user_app | Frontend User | 2026-03-15 | Mood chips, reorder studio entry, and ETA confidence band implemented on Home with green analyze/test | Done |
| S5-02 | Menu detail and decision clarity pass | user_app | Frontend User | 2026-03-15 | Category chips, availability/sort controls, and inline cart quantity stepper shipped on menu screen with green analyze/test | Done |
| S5-03 | Checkout and ETA confidence band | user_app, backend | Frontend User + Backend | 2026-03-15 | Backend ETA envelope and checkout/tracking trust messaging shipped with backend and user_app verification green | Done |
| S5-04 | Reorder Studio quick-repeat flow | user_app | Frontend User | 2026-03-15 | Reorder Studio one-tap repeat now places last order from Home with loading/error handling and routes to tracking | Done |
| S5-05 | User app UX regression and docs closure | user_app, backend, vendor_app, admin_app | QA + Product | 2026-03-15 | Full monorepo verification matrix passed and Sprint 5 docs/governance artifacts updated | Done |
| S6-01 | Rush mode and quick-action baseline | vendor_app | Frontend Vendor | 2026-03-15 | Dashboard now ships Rush Mode toggle, prep-time suggestion chips, swipe-to-progress queue action, and one-swipe 86 hold flow | Done |
| S6-02 | Queue triage rails and fast filters | vendor_app | Frontend Vendor | 2026-03-15 | Dashboard now supports queue rail counts, status filters, ready/newest/high-value sorting, and filtered empty-state feedback | Done |
| S6-03 | Prep-time assist and SLA pacing | vendor_app, backend | Frontend Vendor + Backend | 2026-03-15 | Vendor order queue now exposes pacing metadata and dashboard highlights urgent/watch orders with prep-time assist summary | Done |
| S6-04 | One-swipe 86 workflows and guardrails | vendor_app | Frontend Vendor | 2026-03-15 | Left-swipe 86 flow now requires confirmation, supports undo, and locks completed/held orders from swipe actions | Done |
| S6-05 | Vendor productivity regression and docs closure | vendor_app, backend, user_app, admin_app | QA + Product | 2026-03-15 | Full monorepo verification matrix passed and Sprint 6 docs/governance artifacts updated | Done |
| S7-01 | Governance command deck and dashboard upgrades | admin_app | Frontend Admin | 2026-03-15 | Dashboard now surfaces governance command cards, escalation shortcuts, and faster action routing for moderation and finance workflows | Done |
| S7-02 | Audit usability and decision traceability | admin_app | Frontend Admin | 2026-03-15 | Audit timeline now supports search, severity cues, action narratives, and decision-summary chips for faster investigations | Done |
| S7-03 | Settings safety preview and guardrails | admin_app | Frontend Admin | 2026-03-15 | Settings screen now shows local draft preview, change-impact badge, and reset/save guardrails before policy updates | Done |
| S7-04 | Finance visibility and payout health | admin_app | Frontend Admin | 2026-03-15 | Finance screen now includes payout health counts, top-vendor visibility, and richer 7-day trend readouts for operator review | Done |
| S7-05 | Admin governance docs and regression closure | admin_app, backend, user_app, vendor_app | QA + Product | 2026-03-15 | Admin governance docs updated and full monorepo verification matrix passed for Sprint 7 closure | Done |
| S8-01 | Auth and session enforcement hardening | backend, admin_app | Backend + Frontend Admin | 2026-03-15 | Blocked/banned account denial enforced in auth middleware and admin client now emits request-trace plus device-trust headers | Done |
| S8-02 | Sensitive action safeguards and reason capture | backend, admin_app | Backend + Frontend Admin | 2026-03-15 | Reason validation enforced for block/reject/cancel; audit log stores reason; ReasonCaptureDialog in admin_app; contracts v2026.03.s8.2; 47 backend tests + all Flutter apps green | Done |
| S8-03 | RBAC parity and route authorization audit | backend, user_app, vendor_app | Backend + Frontend Leads | 2026-03-15 | Added requireUser enforcement for customer mutations, vendor/admin gate for delivery writes, vendor_app role validation on login/restore, contracts v2026.03.s8.3, backend 54 tests + vendor_app auth regression coverage green | Done |
| S8-04 | Device trust and session posture UX | admin_app | Frontend Admin | 2026-03-15 | Admin shell now displays trusted/untrusted session posture cues, untrusted warning banner, and one-click trust confirmation workflow with widget coverage | Done |
| S8-05 | Security docs and regression closure | backend, user_app, vendor_app, admin_app | QA + Product | 2026-03-15 | Sprint 8 docs updated (README, API_REFERENCE, DEVELOPER_GUIDE) and full monorepo verification matrix passed (backend 47 tests, all Flutter apps analyze/test clean) | Done |

### Sprint 8 Burndown Snapshot (Closed)

- Planned points: 30
- Completed points: 30
- Remaining points: 0
- At risk: No

## Sprint 8 Progress Evidence

### S8-01 — Auth and session enforcement hardening

- backend
  - Auth middleware now enforces blocked/banned account denial with 403 responses in `backend/src/middleware/auth.ts`.
  - Global error handler logs now include request id and client request id metadata in `backend/src/app.ts`.
  - Added blocked-account regression test coverage in `backend/tests/unit/middleware/auth.test.ts`.
- admin_app
  - API client now emits `X-Client-Request-Id` and persisted `X-Device-Trust` headers in `admin_app/lib/core/network/api_client.dart`.
- governance
  - Updated contract governance metadata in `backend/src/contracts/registry.ts`, `backend/src/contracts/changelog.ts`, and `backend/src/contracts/flags.ts` for Sprint 8 auth/session behavior.

### S8-02 — Sensitive action safeguards and reason capture

- backend
  - `logAdminAction` in `backend/src/controllers/adminController.ts` now accepts and persists a `reason` parameter into the `admin_logs` table.
  - `rejectVendor`, `cancelAdminOrder`, and `blockAdminUser` (when `blocked=true`) now require `reason` in the request body; omitting it returns 400.
  - `getAdminAuditLogs` SELECT now includes the `reason` field.
  - `reason TEXT` column added to `admin_logs` table in `supabase/schema.sql`.
  - 3 existing tests updated and 3 new validation tests added in `backend/tests/unit/controllers/adminController.test.ts` (47 total, 12 suites, all pass).
- admin_app
  - New shared widget `ReasonCaptureDialog` at `admin_app/lib/shared/widgets/reason_capture_dialog.dart` enforces a minimum 10-character reason before confirmation.
  - `vendors_screen.dart` uses `ReasonCaptureDialog` for single and bulk vendor rejection flows.
  - `users_screen.dart` uses `ReasonCaptureDialog` when blocking a user.
  - Reason field is threaded through providers (`vendors_provider.dart`, `users_provider.dart`) and services (`vendors_service.dart`, `users_service.dart`).
- governance
  - Contract version bumped to `2026.03.s8.2`; 3 new endpoint contracts registered (`admin.user.block`, `admin.vendor.reject`, `admin.order.cancel`) in `backend/src/contracts/registry.ts`.
  - Changelog entry `chg-2026-03-15-11` added in `backend/src/contracts/changelog.ts`.
  - Feature flag `security.sensitive_action_reason.v1` added in `backend/src/contracts/flags.ts`.

### S8-03 — RBAC parity and route authorization audit

- backend
  - Added `requireUser` in `backend/src/middleware/rbac.ts` and applied it to customer-only routes in `backend/src/routes/orders.ts`, `backend/src/routes/addresses.ts`, `backend/src/routes/payments.ts`, and `backend/src/routes/reviews.ts`.
  - Added explicit vendor/admin RBAC to delivery writes in `backend/src/routes/delivery.ts`.
  - Added API regression coverage in `backend/tests/api/rbac_parity.test.ts`, bringing backend totals to 54 passing tests across 13 suites.
- vendor_app
  - `vendor_app/lib/features/auth/auth_provider.dart` now validates `/auth/me` role on session restore and rejects non-vendor roles during login before persisting the token.
  - Added vendor auth regression coverage in `vendor_app/test/auth/auth_provider_test.dart`.
- governance
  - Contract registry version bumped to `2026.03.s8.3` and customer endpoint auth scopes updated from generic authenticated access to explicit `user` role in `backend/src/contracts/registry.ts`.
  - Changelog entry `chg-2026-03-15-12` added in `backend/src/contracts/changelog.ts`.
  - Feature flag `security.role_scope_enforcement.v1` added in `backend/src/contracts/flags.ts`.

- verification
  - backend: `npm test` pass (54 tests, 13 suites)
  - user_app: `flutter analyze` pass
  - user_app: `flutter test` pass
  - vendor_app: `flutter analyze` pass
  - vendor_app: `flutter test` pass

### S8-04 — Device trust and session posture UX

- admin_app
  - Added session posture state management in `admin_app/lib/core/config/session_posture_provider.dart` to classify trusted vs untrusted admin sessions using persisted device trust metadata.
  - Updated shell header status chip in `admin_app/lib/shared/widgets/app_shell.dart` to surface `Trusted device` or `Untrusted device` posture at all times.
  - Added untrusted posture remediation banner in `admin_app/lib/shared/widgets/app_shell.dart` with a one-click `Trust this device` control.
  - Added widget regression coverage in `admin_app/test/widgets/shared/app_shell_test.dart` for untrusted posture banner visibility.
  - admin_app: `flutter analyze` pass
  - admin_app: `flutter test` pass

## Sprint 7 Progress Evidence

- admin_app
  - Added governance command deck and action routing on the dashboard in `admin_app/lib/features/dashboard/presentation/screens/dashboard_screen.dart`.
  - Added faster moderation and finance shortcuts directly from the dashboard quick action rail.
  - Added audit search, severity badges, action narratives, and operator summary chips in `admin_app/lib/features/audit/presentation/screens/audit_logs_screen.dart`.
  - Added settings decision preview, change-impact label, and reset/save draft controls in `admin_app/lib/features/settings/presentation/screens/settings_screen.dart`.
  - Added finance visibility hero, payout-health panel, and richer chart row detail in `admin_app/lib/features/finance/presentation/screens/finance_screen.dart`.
  - Added widget coverage for audit search and settings draft-state behavior in `admin_app/test/widgets/audit/audit_logs_screen_test.dart` and `admin_app/test/widgets/settings/settings_screen_test.dart`.
- verification
  - backend: `npm test` pass
  - user_app: `flutter analyze` pass
  - user_app: `flutter test` pass
  - vendor_app: `flutter analyze` pass
  - vendor_app: `flutter test` pass
  - admin_app: `flutter analyze` pass
  - admin_app: `flutter test` pass
- Sprint 7 completion report created in `sprint7_completion_report.md`.

## Sprint 5 Progress Evidence

- user_app
  - Home screen upgraded to stateful discovery experience in `user_app/lib/screens/home/home_screen.dart`.
  - Added Mood-to-Meal chip interactions with keyword-based intent filtering.
  - Added Reorder Studio card fed by latest order from `userOrdersProvider`.
  - Added ETA confidence band in hero trust surface area.
  - Menu screen upgraded for decision clarity in `user_app/lib/screens/menu/menu_screen.dart`.
  - Added category chips, availability filter, and sort toggle for fast menu refinement.
  - Added inline quantity stepper controls and category clarity metadata in `user_app/lib/widgets/menu_item_card.dart`.
- backend
  - Added ETA confidence envelope on order create/list/update responses in `backend/src/controllers/orderController.ts`.
  - Added order payload compatibility for line item fields (`id|menu_item_id`, `price|unit_price`).
  - Updated order trust-surface contracts in `backend/src/contracts/registry.ts`, `backend/src/contracts/changelog.ts`, and `backend/src/contracts/flags.ts`.
- user_app
  - Added checkout ETA trust surface and corrected vendor/order payload mapping in `user_app/lib/screens/cart/cart_screen.dart`.
  - Added tracking ETA confidence card in `user_app/lib/screens/orders/order_tracking_screen.dart`.
  - Added ETA envelope parsing/fallback in `user_app/lib/models/order_model.dart`.
  - Added Reorder Studio one-tap repeat flow (place order from latest order snapshot) in `user_app/lib/screens/home/home_screen.dart`.
- verification
  - backend: `npm test` pass
  - user_app: `flutter analyze` pass
  - user_app: `flutter test` pass
  - vendor_app: `flutter analyze` pass
  - vendor_app: `flutter test` pass
  - admin_app: `flutter analyze` pass
  - admin_app: `flutter test` pass

- Sprint 5 completion report created in `sprint5_completion_report.md`.

## Sprint 6 Progress Evidence

- vendor_app
  - Dashboard productivity baseline delivered in `vendor_app/lib/features/dashboard/dashboard_screen.dart`.
  - Added Rush Mode toggle and prep-time suggestion chips for faster pacing decisions.
  - Added swipe-to-progress status action (start-to-end) and one-swipe 86 hold action (end-to-start).
  - Added inline snack-bar feedback and retained manual status popup controls.
  - Added queue triage rails with live counts and tap-to-filter workflow buckets.
  - Added ready-first, newest, and high-value sort controls with filtered empty-state handling.
- backend
  - Vendor order queue responses now include pacing metadata in `backend/src/controllers/orderController.ts`.
  - Updated vendor pacing contract governance in `backend/src/contracts/registry.ts`, `backend/src/contracts/changelog.ts`, and `backend/src/contracts/flags.ts`.
- vendor_app
  - Added pacing summary strip for urgent/watch counts and prep target review.
  - Added per-order SLA risk badges, elapsed minutes, and recommended prep guidance on dashboard cards.
  - Added protected 86 hold workflow with confirmation sheet and undo recovery.
  - Locked completed and held orders from swipe actions and added safeguard guidance strip.
- verification
  - backend: `npm test` pass
  - vendor_app: `flutter analyze` pass
  - vendor_app: `flutter test` pass
  - user_app: `flutter analyze` pass
  - user_app: `flutter test` pass
  - admin_app: `flutter analyze` pass
  - admin_app: `flutter test` pass

- Sprint 6 completion report created in `sprint6_completion_report.md`.

## Sprint 4 Completion Evidence

- backend
  - Added shared pagination utility in `backend/src/utils/pagination.ts`.
  - Standardized admin list responses with `meta` envelope in:
    - `GET /api/v1/admin/orders`
    - `GET /api/v1/admin/users`
    - `GET /api/v1/admin/audit`
    - `GET /api/v1/admin/vendors/pending`
  - Updated contract governance sources:
    - `backend/src/contracts/registry.ts` -> version `2026.03.s4.1`
    - `backend/src/contracts/changelog.ts`
    - `backend/src/contracts/flags.ts`
- user_app
  - Added retry/backoff and in-flight request cancellation to `ApiService`.
  - Added TTL cache and force-refresh support in contracts service.
- vendor_app
  - Added retry/backoff and in-flight request cancellation to `ApiService`.
  - Added TTL cache and force-refresh support in contracts service.
- admin_app
  - Added global GET dedupe and retry/backoff policy in `ApiClient` interceptor chain.
  - Added TTL cache and force-refresh support in contracts service.
- verification
  - backend: `npm test` pass (12/12 suites, 43/43 tests)
  - user_app: `flutter analyze; flutter test` pass
  - vendor_app: `flutter analyze; flutter test` pass
  - admin_app: `flutter analyze; flutter test` pass

- Sprint 4 completion report created in `sprint4_completion_report.md`.

## Sprint 3 Completion Evidence

- backend
  - Expanded registry coverage and added versioned contracts feeds:
    - `/api/v1/contracts/registry`
    - `/api/v1/contracts/changelog`
    - `/api/v1/contracts/flags`
  - Standardized error taxonomy envelope mapping:
    - `400 ValidationError`
    - `401 Unauthorized`
    - `403 Forbidden`
    - `404 NotFound`
    - `409 Conflict`
    - `500 InternalServerError`
- user_app
  - API client now normalizes backend envelope and throws typed API exceptions.
  - Contracts client supports registry/changelog/flags feeds.
- vendor_app
  - API client now normalizes backend envelope and throws typed API exceptions.
  - Contracts client supports registry/changelog/flags feeds.
- admin_app
  - Service layer normalized around shared API exception parsing.
  - Contracts client supports registry/changelog/flags feeds.
- verification
  - backend: `npm test` pass (12/12 suites, 43/43 tests)
  - user_app: `flutter analyze; flutter test` pass
  - vendor_app: `flutter analyze; flutter test` pass
  - admin_app: `flutter analyze; flutter test` pass

- Sprint 3 completion report created in `sprint3_completion_report.md`.

## Sprint 2 Completion Evidence

- user_app
  - Deep-link destination preservation through login implemented in `user_app/lib/core/router/app_router.dart`.
- vendor_app
  - Deep-link destination preservation through login implemented in `vendor_app/lib/core/router.dart`.
  - Faster order triage with direct status update menu in `vendor_app/lib/features/dashboard/dashboard_screen.dart`.
- admin_app
  - Deep-link destination preservation through login implemented in `admin_app/lib/core/config/app_router.dart`.
  - Quick actions rail for one-hop moderation and operations shortcuts in `admin_app/lib/features/dashboard/presentation/screens/dashboard_screen.dart`.
- verification
  - backend: `npm test` pass
  - user_app: `flutter analyze; flutter test` pass
  - vendor_app: `flutter analyze; flutter test` pass
  - admin_app: `flutter analyze; flutter test` pass

- Sprint 2 completion report created in `sprint2_completion_report.md`.

## Sprint 1 Completion Evidence

- Unified planning and execution source finalized in this file and `sprints_kanban.md`.
- Documentation cleanup completed:
  - Removed legacy split plan files.
  - Updated `AGENTS.md` planning doc references.
- Sprint completion report created in `sprint1_completion_report.md`.

## Ceremony Checklist

- Planning:
  - Confirm success metrics and sprint capacity
  - Finalize scope and dependencies
- Mid-sprint checkpoint:
  - Backend and app contract sync review
  - Integration smoke checks
- End-sprint:
  - Demo UX and functional outcomes
  - Retro with carry-over causes and owners

## Tracking Template

- ID:
- Title:
- Product(s): backend/user_app/vendor_app/admin_app
- Owner:
- Estimate:
- Dependency:
- Risk level:
- Feature flag:
- Test plan:
- Acceptance criteria:
- Status: todo/in-progress/in-review/done
