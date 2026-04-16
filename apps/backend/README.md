# backend

Node.js/Fastify API service for the Campus Pulse platform.

## Development Commands

Run from `backend/`:

```bash
npm install
npm run dev
npm run build
npm start
```

## Test Documentation

Run from `backend/`:

```bash
npm test
```

Optional API contract and live sweep checks:

```bash
npm run test:api
npm run test:api:live
npm run test:api:live:flow
```

What this covers:

- Jest-based backend test suite (`npm test`) for API/business logic regression checks.
- API contract and endpoint sweeps for broader integration confidence (`test:api*` scripts).

Passing criteria:

- `npm test` completes with no failing tests.
- When run, `npm run test:api` and live sweep scripts complete without endpoint contract failures.

## Frontend Connection

Set `CORS_ALLOWED_ORIGINS` to include the frontend origin when the browser app is deployed separately.
For this repository's production frontend, include `https://swift-campus.vercel.app`.

For local development, keep localhost origins in the allowlist so the Flutter apps can call the API during `flutter run`.

The admin web portal consumes the admin routes under `/api/v1/admin`, including support ticket timelines at `/api/v1/admin/support/tickets/:id/timeline` and broadcast notifications at `/api/v1/admin/notifications/broadcast`.

## Logging

Fastify request logging is enabled outside the test environment. Set `LOG_LEVEL` to control verbosity, for example `info`, `warn`, or `debug`.

## Monorepo Verification Policy

When backend contracts, auth, RBAC, payloads, or business rules change, validate impacted Flutter apps (`user_app`, `vendor_app`, `admin_app`) in the same change set according to repository governance.
