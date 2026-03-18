# Sprint Kanban Board

Source plans:
- [sprints_master.md](sprints_master.md)

## How to Use
- Move items between sections during standups.
- Keep one owner per card.
- Add blockers immediately with ETA risk.
- Update status at least once per day.

## Status Legend
- Backlog: approved but not started
- In Progress: actively worked
- Blocked: cannot proceed due to dependency/risk
- In Review: implementation done, pending QA/review
- Done: accepted and released for sprint scope

## Current Sprint Focus
- Sprint: Sprint 9
- Goal: Quality engineering expansion with stronger regression coverage and CI hard gates
- Sprint dates: 2026-03-17 to 2026-03-30
- Sprint status: In Progress

## Backlog
| ID | Title | Product(s) | Owner | Estimate | Dependency | Risk | Acceptance | Status |
|---|---|---|---|---:|---|---|---|---|
| S9-02 | Expand backend controller/unit and contract replay tests | backend | Backend Team | 8 | S9-01 | Med | High-risk backend areas covered with green test suite | Backlog |
| S9-03 | Expand user_app model/provider tests | user_app | Frontend User | 6 | S9-01 | Med | Cart, checkout, and order path tests added and green | Backlog |
| S9-04 | Expand vendor_app core and queue transition tests | vendor_app | Frontend Vendor | 6 | S9-01 | Med | Core API resilience plus queue workflow failure-path tests added and green | Backlog |
| S9-05 | Expand admin_app dashboard/finance/governance tests | admin_app | Frontend Admin | 6 | S9-01 | Med | Coverage increase with stable widget/provider tests | Backlog |
| S9-06 | Full monorepo verification matrix and CI gate pass | backend + all apps | QA + DevOps | 8 | S9-02,S9-03,S9-04,S9-05 | High | backend npm test + all Flutter analyze/test green | Backlog |

## In Progress
| ID | Title | Product(s) | Owner | Started | Next Action | Status |
|---|---|---|---|---|---|---|
| S9-01 | Sprint 9 coverage matrix baseline | backend + all apps | Product + QA | 2026-03-17 | Lock module/screen target list and publish owner checklist | In Progress |
| S9-02 | Expand backend controller/unit and contract replay tests | backend | Backend Team | 2026-03-17 | Continue from admin controller expansion into auth/order API replay cases | In Progress |
| S9-04 | Expand vendor_app core and queue transition tests | vendor_app | Frontend Vendor | 2026-03-17 | Vendor core, provider, and dashboard widget queue-action coverage now in place; next move is wider regression sweep | In Progress |

## Sprint 9 Day-By-Day Plan
- Day 1 (2026-03-17)
  - Finalize Sprint 9 test expansion scope and ownership.
  - Owner: Product + QA
  - Output: Sprint 9 coverage matrix baseline
- Day 2 (2026-03-18)
  - Expand backend controller/unit and contract replay tests.
  - Owner: Backend
  - Output: S9 backend coverage increment
- Day 3 (2026-03-19)
  - Expand user_app model/provider tests (orders/cart/checkout paths).
  - Owner: Frontend User
  - Output: S9 user_app test increment
- Day 4 (2026-03-20)
  - Expand vendor_app provider/queue transition tests.
  - Owner: Frontend Vendor
  - Output: S9 vendor_app test increment
- Day 5 (2026-03-21)
  - Expand admin_app dashboard/finance/governance tests.
  - Owner: Frontend Admin
  - Output: S9 admin_app test increment
- Day 6 (2026-03-22)
  - Execute full monorepo verification and close flaky tests.
  - Owner: QA + DevOps
  - Output: Sprint 9 verification matrix
- Day 7 (2026-03-23)
  - Finalize docs and closure readiness checkpoint.
  - Owner: Product + QA
  - Output: Sprint 9 closure readiness decision

## Blocked
| ID | Title | Product(s) | Owner | Blocker | Since | Unblock Owner | ETA Impact |
|---|---|---|---|---|---|---|---|
|  |  |  |  |  |  |  |  |

## In Review
| ID | Title | Product(s) | Owner | PR/Branch | Reviewer | QA Scope | Status |
|---|---|---|---|---|---|---|---|
|  |  |  |  |  |  |  |  |

## Done
| ID | Title | Product(s) | Owner | Completed On | Evidence | Status |
|---|---|---|---|---|---|---|
| S1-01 | Finalize design tokens | user_app, vendor_app, admin_app | Design Lead | 2026-03-14 | Token map and component references published | Done |
| S1-02 | Standardize button/input/card variants | user_app, vendor_app, admin_app | Frontend Guild | 2026-03-14 | Shared component standardization in top screens | Done |
| S1-03 | Common empty/error/loading patterns | user_app, vendor_app, admin_app | Frontend Guild | 2026-03-14 | Cross-app loading/empty/error pattern normalization | Done |
| S1-04 | Accessibility baseline pass | all apps | QA + Design | 2026-03-14 | Baseline accessibility checks completed | Done |
| S1-05 | Visual regression baseline snapshots | user_app, vendor_app, admin_app | QA | 2026-03-14 | Snapshot inventory and baseline planning completed | Done |
| S2-01 | Navigation flow optimization | user_app, vendor_app, admin_app | Frontend Guild | 2026-03-14 | Route-flow improvements implemented for user/vendor/admin | Done |
| S2-02 | Route guard hardening | backend + all apps | Backend + Frontend Leads | 2026-03-14 | Deep-link login-return guard logic implemented and validated | Done |
| S2-03 | Admin quick actions rail | admin_app | Frontend Admin | 2026-03-14 | One-hop quick actions confirmed in dashboard workflows | Done |
| S2-04 | Progressive disclosure navigation | user_app, vendor_app, admin_app | Frontend Guild | 2026-03-14 | Compact plus More-actions patterns verified | Done |
| S2-05 | Deep-link and route-guard audit | backend + all apps | Backend + Frontend Leads | 2026-03-14 | Audit completed with full monorepo verification pass | Done |
| S3-01 | API contract source of truth update | backend, user_app, vendor_app, admin_app | Backend + Frontend Leads | 2026-03-15 | Expanded registry and shipped contracts feeds (`/registry`, `/changelog`, `/flags`) | Done |
| S3-02 | Error taxonomy alignment | backend, user_app, vendor_app, admin_app | Backend Team | 2026-03-15 | Standardized 400/401/403/404/409/500 error envelope taxonomy and tests | Done |
| S3-03 | Consumer DTO normalization | user_app, vendor_app, admin_app | Frontend Guild | 2026-03-15 | App API clients normalized for envelope parsing and contracts feed consumption | Done |
| S3-04 | Contract changelog feed endpoint | backend | Backend Team | 2026-03-15 | Implemented `/api/v1/contracts/changelog` contract change feed | Done |
| S3-05 | Feature-flag scaffolding for staged rollouts | backend, user_app, vendor_app, admin_app | Backend + Frontend Leads | 2026-03-15 | Implemented `/api/v1/contracts/flags` feed and consumer service support | Done |
| S4-01 | Pagination standards and query optimization | backend, admin_app | Backend Team | 2026-03-15 | Shared pagination utility and unified `meta` response added to admin list APIs | Done |
| S4-02 | Retry/backoff policy unification | user_app, vendor_app, admin_app | Frontend Guild | 2026-03-15 | Bounded retry/backoff implemented for retryable failures in all apps | Done |
| S4-03 | Request cancellation and dedupe | user_app, vendor_app, admin_app | Frontend Guild | 2026-03-15 | Superseded request cancellation and admin GET dedupe implemented | Done |
| S4-04 | Contracts feed caching | user_app, vendor_app, admin_app | Frontend Guild | 2026-03-15 | TTL cache and force-refresh support added for contracts feeds | Done |
| S4-05 | Reliability governance and verification | backend, user_app, vendor_app, admin_app | QA + DevOps | 2026-03-15 | Contracts/docs updates and full monorepo verification completed | Done |
| S5-01 | Discovery and intent-driven browse | user_app | Frontend User | 2026-03-15 | Home now ships mood chips, reorder studio card, and ETA confidence band; user_app analyze/test green | Done |
| S5-02 | Menu detail and decision clarity pass | user_app | Frontend User | 2026-03-15 | Category chips, availability/sort controls, and inline cart quantity stepper implemented; user_app analyze/test green | Done |
| S5-03 | Checkout and ETA confidence band | user_app, backend | Frontend User + Backend | 2026-03-15 | Backend ETA envelope and user checkout/tracking trust surfaces implemented; backend and user_app tests green | Done |
| S5-04 | Reorder Studio quick-repeat flow | user_app | Frontend User | 2026-03-15 | One-tap repeat from Reorder Studio now places latest order and routes to tracking with submit/error handling | Done |
| S5-05 | User app UX regression and docs closure | user_app, backend, vendor_app, admin_app | QA + Product | 2026-03-15 | Full monorepo verify matrix passed and sprint docs updated for closure | Done |
| S6-01 | Rush mode and quick-action baseline | vendor_app | Frontend Vendor | 2026-03-15 | Rush Mode toggle, prep suggestions, swipe-to-progress queue action, and one-swipe 86 hold flow delivered on dashboard | Done |
| S6-02 | Queue triage rails and fast filters | vendor_app | Frontend Vendor | 2026-03-15 | Queue rails, fast status filters, and ready/newest/high-value sorting delivered on dashboard | Done |
| S6-03 | Prep-time assist and SLA pacing | vendor_app, backend | Frontend Vendor + Backend | 2026-03-15 | Backend pacing metadata and vendor dashboard urgent/watch prep assist surfaces delivered with backend and vendor_app verification green | Done |
| S6-04 | One-swipe 86 workflows and guardrails | vendor_app | Frontend Vendor | 2026-03-15 | Protected 86 confirmation, undo recovery, and swipe locking for completed/held orders delivered on dashboard | Done |
| S6-05 | Vendor productivity regression and docs closure | vendor_app, backend, user_app, admin_app | QA + Product | 2026-03-15 | Full monorepo verification matrix passed and Sprint 6 docs updated for closure | Done |
| S7-01 | Governance command deck and dashboard upgrades | admin_app | Frontend Admin | 2026-03-15 | Dashboard command deck, escalation shortcuts, and governance action routing delivered | Done |
| S7-02 | Audit usability and decision traceability | admin_app | Frontend Admin | 2026-03-15 | Audit search, severity cues, summary chips, and action narratives delivered | Done |
| S7-03 | Settings safety preview and guardrails | admin_app | Frontend Admin | 2026-03-15 | Settings draft preview, impact badge, and reset/save controls delivered | Done |
| S7-04 | Finance visibility and payout health | admin_app | Frontend Admin | 2026-03-15 | Finance visibility hero, payout health panel, and richer trend readout delivered | Done |
| S7-05 | Admin governance docs and regression closure | admin_app, backend, user_app, vendor_app | QA + Product | 2026-03-15 | Full monorepo verification matrix passed and sprint docs updated for closure | Done |
| S8-01 | Auth and session enforcement hardening | backend, admin_app | Backend + Frontend Admin | 2026-03-15 | Blocked/banned account denial and request-trace/device-trust propagation delivered; governance metadata updated | Done |
| S8-02 | Sensitive action safeguards and reason capture | backend, admin_app | Backend + Frontend Admin | 2026-03-15 | Reason validation on block/reject/cancel; ReasonCaptureDialog widget; contracts updated; 47 backend tests + all Flutter apps green | Done |
| S8-03 | RBAC parity and route authorization audit | backend, user_app, vendor_app | Backend + Frontend Leads | 2026-03-15 | requireUser added for customer mutations, delivery writes vendor/admin gated, vendor_app session role validation added, contracts updated, backend 54 tests + vendor auth tests green | Done |
| S8-04 | Device trust and session posture UX | admin_app | Frontend Admin | 2026-03-15 | App shell now exposes trusted/untrusted posture cue, untrusted remediation banner, and trust-confirm action with widget coverage | Done |
| S8-05 | Security docs and regression closure | backend, user_app, vendor_app, admin_app | QA + Product | 2026-03-15 | Sprint 8 docs updated (README, API_REFERENCE, DEVELOPER_GUIDE) and full monorepo verification matrix passed (backend 47 tests, all Flutter apps analyze/test clean) | Done |

## Sprint Burndown Snapshot
- Planned points: 34
- Completed points: 0
- Remaining points: 34
- At risk: Low

## Daily Standup Notes
### YYYY-MM-DD
- Yesterday:
- Today:
- Blockers:

### 2026-03-14
- Yesterday: Closed Sprint 1 with all tasks complete.
- Today: Completed Sprint 2 implementation and closure checks:
  - user_app: protected-route redirect preserves intended deep-link via login `from` query.
  - vendor_app: same deep-link-preserving guard behavior and faster order triage status update menu.
  - admin_app: deep-link-preserving login return behavior implemented in app router.
  - full verification passed: backend `npm test`, and `flutter analyze; flutter test` for user_app, vendor_app, admin_app.
  - Sprint 3 kickoff: added canonical contract registry endpoint at `/api/v1/contracts/registry` with versioned schema metadata for key APIs.
  - added backend contract registry test suite and updated governance docs (`API_REFERENCE.md`, `DEVELOPER_GUIDE.md`, `README.md`).
- Blockers: None reported.

### 2026-03-15
- Yesterday: Sprint 3 kickoff and backend contracts registry endpoint implementation completed.
- Today:
  - aligned admin_app data services to standardized backend error envelope parsing.
  - aligned user_app and vendor_app API clients to standardized backend error envelope parsing.
  - added contracts registry service clients in admin_app, user_app, and vendor_app for contract-driven consumer updates.
  - standardized backend global error taxonomy mapping for 400/401/403/404/409/500 envelopes.
  - added API taxonomy regression tests for 400/401/403/404/409/500 envelope assertions.
  - added versioned contracts changelog and flags feeds with backend route and test coverage.
  - implemented Sprint 4 reliability hardening:
    - backend shared pagination utility and unified admin list `meta` envelopes.
    - user_app/vendor_app bounded retry-backoff and request cancellation handling.
    - admin_app global GET dedupe and retry-backoff policy in shared API client.
    - contracts feed TTL cache in user_app/vendor_app/admin_app services.
  - updated contract governance artifacts (`registry`, `changelog`, `flags`) and reliability documentation.
  - full verification pass completed: backend `npm test`; `flutter analyze; flutter test` for user_app, vendor_app, admin_app.
  - Sprint 5 S5-01 implemented in user_app Home:
    - Mood-to-Meal chip row with active-state selection and intent filtering.
    - Reorder Studio card using latest user order and vendor deep-link entry.
    - ETA confidence trust message band in top hero area.
  - Sprint 5 S5-02 implemented in user_app Menu:
    - Category chips and availability/sort quick controls for decision clarity.
    - Inline plus/minus quantity stepper directly on menu cards.
    - Category badges and improved no-match feedback for filtered results.
  - Sprint 5 S5-03 implemented across backend and user_app:
    - Backend order responses now include ETA confidence envelope (`eta.min_minutes`, `eta.max_minutes`, `eta.confidence`).
    - Checkout summary now renders ETA trust surface and uses corrected vendor and line-item mapping.
    - Order tracking now renders ETA confidence card from response payload/fallback model.
  - verification pass completed for Sprint 5 slice: backend `npm test`; user_app `flutter analyze`; `flutter test`.
  - Sprint 5 S5-04 implemented in user_app Home:
    - Reorder Studio now supports one-tap repeat-order placement from latest order snapshot.
    - Added loading state, failure handling, and successful transition to order tracking route.
  - verification pass completed for Sprint 5 slice: user_app `flutter analyze`; `flutter test`.
  - Sprint 5 S5-05 closure completed:
    - Full verification matrix passed: backend `npm test`, user_app `flutter analyze/test`, vendor_app `flutter analyze/test`, admin_app `flutter analyze/test`.
    - Sprint closure docs and evidence updated, including `sprint5_completion_report.md`.
  - Sprint 6 kickoff and S6-01 completion:
    - Vendor dashboard now supports Rush Mode toggle and prep-time suggestion chips.
    - Added swipe gestures for quick status progression and one-swipe 86 hold action.
    - vendor_app verification pass completed: `flutter analyze`; `flutter test`.
  - Sprint 6 S6-02 implemented in vendor_app Dashboard:
    - Added queue triage rails with live counts for All, Accepted, Preparing, Ready, and 86 Hold buckets.
    - Added ready-first, newest, and high-value sorting controls.
    - Added filtered empty-state feedback for no-match queue views.
    - vendor_app verification pass completed: `flutter analyze`; `flutter test`.
  - Sprint 6 S6-03 implemented across backend and vendor_app:
    - Vendor order queue responses now include pacing metadata (`elapsed_minutes`, `target_prep_minutes`, `recommended_prep_minutes`, `sla_risk`, `pace_label`).
    - Vendor dashboard now surfaces urgent/watch pacing counts and per-order prep guidance.
    - verification pass completed: backend `npm test`; vendor_app `flutter analyze`; `flutter test`.
  - Sprint 6 S6-04 implemented in vendor_app Dashboard:
    - Left-swipe 86 flow now requires confirmation and exposes contextual pacing details before hold action.
    - Added undo recovery in snackbar and blocked swipe actions for completed/held orders.
    - vendor_app verification pass completed: `flutter analyze`; `flutter test`.
  - Sprint 6 S6-05 closure completed:
    - Full verification matrix passed: backend `npm test`, user_app `flutter analyze/test`, vendor_app `flutter analyze/test`, admin_app `flutter analyze/test`.
    - Sprint closure docs and evidence updated, including `sprint6_completion_report.md`.
  - Sprint 7 S7-01 through S7-04 implemented in admin_app:
    - Dashboard now exposes a governance command deck and quicker action routing across moderation, settings, audit, and finance workflows.
    - Audit timeline now supports local search, severity cues, summary chips, and richer action narratives.
    - Settings screen now supports local draft preview, change-impact labeling, and safer reset/save guardrails.
    - Finance screen now surfaces payout health counts, top-vendor context, and richer trend readouts for operator review.
    - Added widget coverage for audit search and settings draft preview behavior.
  - Sprint 7 S7-05 closure completed:
    - Full verification matrix passed: backend `npm test`, user_app `flutter analyze/test`, vendor_app `flutter analyze/test`, admin_app `flutter analyze/test`.
    - Sprint closure docs and evidence updated, including `sprint7_completion_report.md`.
- Blockers: None reported.

### 2026-03-17
- Yesterday: Sprint 8 closure and docs sync completed.
- Today:
  - Sprint 9 started and moved to In Progress.
  - S9-01 (coverage matrix baseline) started.
  - Owners and dependencies aligned for S9-02 through S9-06.
  - Added vendor_app core API resilience tests at `test/core/api_service_test.dart` (retry, envelope mapping, cancel-key supersession), passing via `flutter test test/core/api_service_test.dart`.
  - Improved orders status update error handling in `lib/features/orders/orders_provider.dart` and expanded `test/providers/orders_provider_test.dart` to cover successful refresh plus failed patch handling, passing via `flutter test test/providers/orders_provider_test.dart`.
  - Added dashboard widget coverage in `test/widgets/dashboard_screen_test.dart` for Update-menu success flow and protected 86-hold failure feedback; fixed queue rail overflow in `lib/features/dashboard/dashboard_screen.dart`; passing via `flutter test test/widgets/dashboard_screen_test.dart`.
  - Expanded backend admin controller coverage in `backend/tests/unit/controllers/adminController.test.ts` with new dashboard-summary and chart-data replay tests; passing via `npm test -- tests/unit/controllers/adminController.test.ts`.
  - Aligned admin stats output to include canonical `revenue` plus `gmv` alias in backend controller, and added regression test coverage for that contract in `backend/tests/unit/controllers/adminController.test.ts`.
  - Expanded backend auth/order API replay suites (`backend/tests/api/auth_expanded.test.ts`, `backend/tests/api/orders_expanded.test.ts`) with role-forcing, fallback-profile, and ETA/pacing contract assertions; passing via `npm test -- tests/api/auth_expanded.test.ts tests/api/orders_expanded.test.ts`.
- Blockers: None reported.

### YYYY-MM-DD
- Yesterday:
- Today:
- Blockers:

## Integration Checkpoint (Mid-Sprint)
- Backend <-> App contract sync status:
- Cross-app test status:
  - backend npm test: pass
  - user_app analyze/test: pass
  - vendor_app analyze/test: pass
  - admin_app analyze/test: pass
- Risks requiring scope adjustment:

## End-Sprint Demo Checklist
- UX outcomes demonstrated:
- API changes demonstrated:
- Test/analyze outputs captured:
- Stakeholder sign-off:

## Next Sprint Queue (Preview)
| Priority | Candidate Story | Product(s) | Dependency | Risk |
|---|---|---|---|---|
| P1 | Launch readiness verification matrix and release checklist | backend + all apps | Sprint 9 complete | High |
| P1 | North Star dashboard instrumentation and baseline tracking | backend + user_app + vendor_app + admin_app | Sprint 9 complete | Med |
| P2 | In-app feedback capture and triage workflow | user_app + vendor_app + admin_app + backend | Sprint 9 complete | Med |
