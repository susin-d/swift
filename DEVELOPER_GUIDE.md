# Developer & Contribution Guide

Welcome to the internal engineering guide for the Swift Platform.

## System Architecture Philosophy

This platform uses a **highly decoupled micro-architecture**.
- The **Backend** is entirely stateless. Sessions are managed via JWTs.
- The **Database** (Supabase) is the true source of truth and enforces security via PostgREST Row Level Security (RLS). Never trust the backend blindly; enforce rules at the database level!
- **Realtime** is handled by Supabase channels, not custom Socket.io servers. This drastically reduces the load on our Node servers.

## UI/UX Engineering Rules

When building components in React or Flutter, adhere to the **Teal Design System**:
- `Primary`: `#0D9488`
- `Accent`: `#CCFBF1`

1. **No custom CSS files**. Use Tailwind utility classes in React (`vendor-dashboard` and `admin-dashboard`).
2. **Component Reusability**. If a button or card design is used twice, extract it into `src/components/`.
3. Flutter widgets should strictly utilize the definitions declared in `/lib/theme/app_theme.dart`. Do not hardcode HEX colors in individual Flutter screens.

## Branching Strategy

We follow a simplified Git-Flow:
- `main`: Production-ready code. Commits here automatically deploy to Vercel/DigitalOcean.
- `staging`: Feature aggregation branch.
- `feature/*`: Your daily work branches (e.g., `feature/vendor-analytics-graphs`).

## API Contract Governance

- Canonical API contract source: `GET /api/v1/contracts/registry`.
- Contract change feed for client sync: `GET /api/v1/contracts/changelog`.
- Contract rollout flags feed: `GET /api/v1/contracts/flags`.
- Any request/response shape change must update the backend registry in `backend/src/contracts/registry.ts` in the same change set.
- Any contract-impacting release must append changelog metadata in `backend/src/contracts/changelog.ts`.
- Staged rollout toggles for consumers must be updated in `backend/src/contracts/flags.ts`.
- Consumer updates in `user_app`, `vendor_app`, and `admin_app` must be completed when affected contract entries change.
- Shared error payload shape is standardized as:
  - `error`: machine-readable type
  - `message`: human-readable message

## Sprint 4 Reliability Standards

- Backend list endpoints must use consistent pagination fields (`page`, `limit`, `total`) and `meta` pagination summary.
- Client networking layers must support:
  - bounded retry with incremental backoff for retryable failures
  - cancellation of superseded in-flight requests for high-frequency fetch flows
  - short-lived caching for contracts feeds (`/contracts/registry`, `/contracts/changelog`, `/contracts/flags`)
- Reliability behavior changes that affect payloads or client expectations must update:
  - `backend/src/contracts/registry.ts`
  - `backend/src/contracts/changelog.ts`
  - `backend/src/contracts/flags.ts`

## Sprint 5 Trust Surface Standards

- Order API responses should include ETA confidence envelope when returning order payloads used by checkout/tracking:
  - `eta.min_minutes`
  - `eta.max_minutes`
  - `eta.confidence`
- Compatibility for order item payload naming must be preserved (`id|menu_item_id`, `price|unit_price`) during transition windows.
- User-facing trust messaging should be consistent between checkout and tracking surfaces.

## Sprint 6 Vendor Productivity Standards

- Vendor queue responses should expose pacing metadata for operator prioritization when the order feed is used by vendor_app:
  - `pacing.elapsed_minutes`
  - `pacing.target_prep_minutes`
  - `pacing.recommended_prep_minutes`
  - `pacing.sla_risk`
  - `pacing.pace_label`
- Vendor productivity surfaces should keep manual fallback actions available even when fast-swipe or quick-triage actions are added.
- Queue filters and sort controls should remain client-safe and not require schema drift outside the documented contract fields.

## Sprint 7 Admin Governance Standards

- Admin workflow upgrades should reduce navigation cost for high-risk moderation and configuration actions without hiding the underlying source screens.
- Audit surfaces should make action severity, actor, target, and timestamp scannable in a single card so operators can investigate without opening detail drawers.
- Settings changes should support local draft review before save, including clear impact cues when commission or delivery values shift materially.
- Finance operator surfaces should summarize payout health at a glance and keep trend visibility readable on tablet widths.

## Sprint 8 Security and Compliance Standards

- Auth middleware must reject blocked or actively banned accounts with `403 Forbidden` on authenticated flows and keep error payload shape aligned with the standard taxonomy.
- Protected endpoint authentication must enforce strict bearer token format validation (`Authorization: Bearer <token>`) and reject empty/malformed bearer headers with `401 Unauthorized`.
- Admin privileged requests should propagate correlation metadata (`X-Client-Request-Id`) and stable device posture metadata (`X-Device-Trust`) for observability and risk analysis.
- Backend error logging for request failures should include server request id plus client request id correlation when available.
- Admin shell experiences should surface session posture continuously (`Trusted device` vs `Untrusted device`) and provide an in-context trust-confirm action for untrusted sessions.
- Any admin action that modifies user account status (`block`), vendor lifecycle state (`reject`), or order status (`cancel`) must include a `reason` string in the request body. The backend enforces this at `400 ValidationError` and records it in the audit log. The admin app must present a `ReasonCaptureDialog` (min 10 characters) before calling these endpoints.
- Customer-only mutation routes must use explicit `requireUser` enforcement instead of plain authentication. This applies to customer order creation/history, saved addresses, payments, and review creation.
- Vendor operational writes must use explicit vendor-scoped enforcement. `POST /delivery/location` should only be reachable by vendor/admin principals, and dedicated admin/vendor apps must invalidate restored or newly created sessions whose resolved role does not match the app surface.
- Any security behavior change must update all of:
  - `backend/src/contracts/registry.ts`
  - `backend/src/contracts/changelog.ts`
  - `backend/src/contracts/flags.ts`

## Setting up Realtime Connections
When integrating Supabase Realtime in the frontend apps, remember to subscribe to the specific `order_id` or `vendor_id`:

```javascript
// React Example for Vendor Dashboard
supabase
  .channel('custom-filter-channel')
  .on(
    'postgres_changes',
    { event: 'INSERT', schema: 'public', table: 'orders', filter: `vendor_id=eq.${myVendorId}` },
    (payload) => {
      console.log('New order received!', payload)
      // trigger alert sound
    }
  )
  .subscribe()
```

