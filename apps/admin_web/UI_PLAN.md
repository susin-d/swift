# Admin Web UI/UX + Backend Integration Plan

## Objective
- Deliver an admin control console that is backend-connected, role-safe, and fast for operations workflows.

## Route Map
- `/`: landing and product framing.
- `/login`: admin authentication flow.
- `/dashboard`: authenticated operations dashboard (guarded).

## UX Plan By Screen

### Landing (`/`)
- Command-surface hero with stronger operational framing and contrast-led composition.
- Three-screen vertical flow (hero, workflow loop, reliability/CTA) to create a full landing journey.
- Primary CTA (`Enter Admin`) and secondary CTA (`View Live Console`) for fast navigation.
- Signal-board panel presenting live-style metrics and system pulse.
- Focus marquee chips for high-frequency admin workflows (escalations, approvals, fraud, payouts).

### Login (`/login`)
- Simple credentials form (`email`, `password`) with validation by required fields.
- Inline backend error rendering (`401`, `403`, validation errors).
- Submit button shows in-progress state while request is pending.
- Successful admin login transitions directly to dashboard.

### Dashboard (`/dashboard`)
- Sidebar for information architecture and session actions (including sign out).
- KPI cards powered by backend `/admin/stats`.
- Recent queue table powered by backend `/admin/orders`.
- Built-in loading, empty, and error states to avoid blank views.

## Backend Contract Integration

### Environment
- `VITE_API_BASE_URL` drives the base URL.
- Local default: `http://localhost:3000/api/v1`.

### Auth Contract
- `POST /auth/session`
- Required request fields:
  - `email`
  - `password`
- Required response fields:
  - `user`
  - `session.access_token`
- Frontend guard:
  - Allow dashboard only when `user.role === "admin"` and token exists.

### Dashboard Contracts
- `GET /admin/stats` for summary cards.
- `GET /admin/orders?limit=5&page=1` for recent queue snapshot.
- Request headers:
  - `Authorization: Bearer <access_token>`

## State Model
- Session state:
  - persisted in localStorage key `swift.admin.session`
  - shape: `{ user, token }`
- Route protection:
  - unauthenticated users redirected to `/login`
- Data state:
  - `isLoading`
  - `loadError`
  - `stats`
  - `orders`

## Accessibility Requirements
- Semantic layout: `main`, `section`, `nav`, `table`.
- Keyboard-visible focus rings for links, buttons, and inputs.
- Error states surfaced with `role="alert"` for assistive technologies.

## Execution Phases
1. UX baseline:
   - Landing/login/dashboard layout and responsive behavior.
2. Auth integration:
   - Session API wiring + admin role gate + dashboard route guard.
3. Dashboard data integration:
   - Live KPI + order queue fetch with resilient states.
4. Validation and polish:
   - Error copy, sign-out flow, and loading affordances.

## Test Plan
- Route tests:
  - landing render
  - login render
  - dashboard redirect when unauthenticated
- Auth flow tests:
  - successful login navigates to dashboard
  - non-admin or invalid credentials show error state
- Data tests:
  - dashboard renders API-backed stats and recent orders
  - empty queue message appears when no orders are returned
