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

## Monorepo Verification Policy

When backend contracts, auth, RBAC, payloads, or business rules change, validate impacted Flutter apps (`user_app`, `vendor_app`, `admin_app`) in the same change set according to repository governance.
