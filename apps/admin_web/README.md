# Admin Web (React)

React + Vite admin web app with three core routes:
- Landing page: `/`
- Login page: `/login`
- Dashboard with sidebar: `/dashboard` (admin-authenticated)

## Scripts

- `npm run dev` starts the development server.
- `npm run build` creates a production build.
- `npm run test` runs route-level UI tests.
- `npm run test:watch` runs tests in watch mode.

## Structure

- `src/pages` route-level pages.
- `src/components` reusable UI building blocks.
- `src/context` auth state provider and hooks.
- `src/services` backend API client.
- `src/config` runtime configuration helpers.
- `src/index.css` design tokens, layout, and responsive styles.
- `UI_PLAN.md` full UI implementation plan.

## Backend Connection

- Login endpoint: `POST /auth/session`
- Dashboard endpoints:
  - `GET /admin/stats`
  - `GET /admin/orders?limit=5&page=1`
- Auth header: `Authorization: Bearer <access_token>`

## Environment

- Default API URL: `http://localhost:3000/api/v1`
- Override with:
  - `VITE_API_BASE_URL=https://your-api.example.com/api/v1`

## Current Scope

- Route scaffolding with React Router and protected dashboard route.
- Admin-only session handling with local storage persistence.
- Backend-powered dashboard KPI and queue data states.
- Route/auth/data tests with mocked API responses.
