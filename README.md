# Swift
A comprehensive, real-time logistics and food delivery platform connecting students with premium vendors.

## 🌟 Platform Components

1. **User Mobile App (Flutter)**: Allows students and staff to browse vendors, order food, and track deliveries in real-time.
2. **Vendor Dashboard (React/Vite)**: A tablet-optimized web dashboard for canteens to manage their menus and process live orders.
3. **Admin Dashboard (React/Vite)**: A control panel for campus management to oversee vendor approvals and platform analytics.
4. **Backend API (Node.js/Fastify)**: The central brain handling authentication, order processing, and RBAC security.
5. **Database (Supabase PostgreSQL)**: A strictly secured database using Row Level Security (RLS) with Realtime WebSockets built-in.

## 🚀 Getting Started

### Prerequisites
- Node.js (v18+)
- Flutter SDK (v3.10+)
- A Supabase Project (Free Tier works)

### Local Setup

1. **Supabase**
   - Head to [Supabase](https://supabase.com) and create a project.
   - Run the SQL script found in `supabase/schema.sql` in the Supabase SQL Editor.
   - Grab your Project URL and anon/service keys.

2. **Backend Services**
   ```bash
   cd backend
   npm install
   cp .env.example .env
   # Add your Supabase keys to .env
   npm run dev
   ```

   Contract governance endpoints (Sprint 3+):
   - `GET /api/v1/contracts/registry` returns canonical request/response contract metadata and standardized error envelope details.
   - `GET /api/v1/contracts/changelog` returns versioned contract change history for consumer sync.
   - `GET /api/v1/contracts/flags` returns staged rollout flags for contract/reliability features.

   Reliability standards (Sprint 4):
   - Admin list endpoints expose shared pagination metadata (`meta.totalPages`, `meta.hasNextPage`, `meta.hasPreviousPage`).
   - App clients apply bounded retry/backoff, superseded request cancellation, and short-lived contracts feed caching.

   Trust surfaces (Sprint 5):
   - Order create/list responses include ETA confidence envelope (`eta.min_minutes`, `eta.max_minutes`, `eta.confidence`).
   - Checkout and tracking experiences consume the same ETA trust contract for consistency.

   Vendor productivity (Sprint 6):
   - Vendor order queue responses include pacing metadata (`pacing.elapsed_minutes`, `pacing.target_prep_minutes`, `pacing.recommended_prep_minutes`, `pacing.sla_risk`, `pacing.pace_label`).
   - Vendor dashboard queue rails, sorts, and prep-time assist consume the same pacing contract.

   Admin governance (Sprint 7):
   - Admin dashboard now centers governance command workflows for moderation, audit, settings, and finance review.
   - Audit and settings flows emphasize decision traceability and safer local review before policy changes are saved.
   - Finance surfaces now highlight payout health and top-vendor visibility for faster operator review.

   Security hardening (Sprint 8):
   - Auth middleware rejects blocked or actively banned accounts with `403 Forbidden` on protected session flows.
   - Admin client now propagates `X-Client-Request-Id` and persistent `X-Device-Trust` headers for privileged API calls.
   - Backend error observability logs include server request id plus client request id correlation.
   - Sensitive admin actions (block user, reject vendor, cancel order) now require an explicit reason, captured through a dialog widget in the admin app and stored in the audit log.
   - Admin app `ReasonCaptureDialog` enforces a minimum 10-character justification before any destructive moderation action proceeds.
   - Admin app shell now surfaces session posture (`Trusted device` / `Untrusted device`) with an inline remediation banner so operators can confirm trust on active devices.
   - Customer-only mutations (`/orders`, `/orders/me`, `/addresses`, `/payments`, `/reviews`) now reject vendor/admin tokens with `403 Forbidden`.
   - Delivery location updates are now explicitly scoped to vendor or admin operators, and the vendor app clears/restores sessions only for vendor-role accounts.

3. **Vendor Dashboard**
   ```bash
   cd vendor-dashboard
   npm install
   npm run dev
   ```

4. **User Mobile App**
   ```bash
   cd mobile_app
   flutter pub get
   flutter run
   ```

## 🔒 Tech Stack
- **Flutter** & **Dart**
- **React.js** (Vite), **Tailwind CSS**
- **Node.js**, **Fastify**, **TypeScript**
- **Supabase** (PostgreSQL, Auth, Realtime)

## 🤝 Contributing
Please read the internal developer guides before pushing changes to the `main` branch. Ensure your code passes all lint checks.
