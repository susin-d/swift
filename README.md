# Swift
A comprehensive, real-time logistics and food delivery platform connecting students with premium vendors.

## Documentation Index
- Consolidated platform documentation: [PROJECT_DOCUMENTATION.md](./PROJECT_DOCUMENTATION.md)
- API details: [API_REFERENCE.md](./API_REFERENCE.md)
- Developer runbook: [DEVELOPER_GUIDE.md](./DEVELOPER_GUIDE.md)
- User app features: [user_features.md](./user_features.md)
- Admin app features: [admin_features.md](./admin_features.md)

## 🌟 Platform Components

1. **User App (Flutter)**: Allows students and staff to browse vendors, order food, and track deliveries in real-time.
2. **Vendor App (Flutter)**: Vendor operations app for queue triage, prep-time pacing, and live order handling.
3. **Admin App (Flutter)**: Governance control panel for moderation, audits, settings safety, and finance visibility.
4. **Backend API (Node.js/Fastify)**: The central brain handling authentication, order processing, contracts, and RBAC security.
5. **Admin Web (React/Vite)**: Browser-based admin operations interface with landing, login, and dashboard routes.
6. **Database (Supabase PostgreSQL)**: A strictly secured database using Row Level Security (RLS) with Realtime support.

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
   # Add your Supabase, Razorpay, and Brevo keys to .env
   npm run dev
   ```

   Required password-reset email variables:
   - `BREVO_API_KEY` (Brevo API v3 key)
   - `BREVO_FROM_EMAIL` (verified sender email in Brevo)
   - `BREVO_FROM_NAME` (optional display name, defaults to `Swift Support`)
   - `PASSWORD_RESET_OTP_TTL_MINUTES` (optional, default `10`)
   - `PASSWORD_RESET_OTP_MAX_ATTEMPTS` (optional, default `5`)

   Script credential variables (for local admin/demo scripts):
   - `ADMIN_EMAIL`, `ADMIN_PASSWORD`, `ADMIN_NAME`
   - `TEST_VENDOR_EMAIL`, `TEST_VENDOR_PASSWORD`, `TEST_VENDOR_NAME`
   - `TEST_USER_EMAIL`, `TEST_USER_PASSWORD`, `TEST_USER_NAME`
   - `DEMO_USER_EMAIL`, `DEMO_VENDOR_EMAIL`, `DEMO_ADMIN_EMAIL`

   Production safety:
   - Backend startup now fails in `NODE_ENV=production` if `SUPABASE_URL` or `SUPABASE_SERVICE_ROLE_KEY` are missing or placeholder values.
   - Keep service-role credentials only in server environment variables, never in client apps.
   - `npm run test:api` is a local smoke harness; set `TEST_VENDOR_ID` and `TEST_ORDER_ID` to exercise vendor- and delivery-scoped routes instead of using placeholder IDs.

   Contract governance endpoints:
   - `GET /api/v1/contracts/registry` returns canonical request/response contract metadata and standardized error envelope details.
   - `GET /api/v1/contracts/changelog` returns versioned contract change history for consumer sync.
   - `GET /api/v1/contracts/flags` returns staged rollout flags for contract/reliability features.
    - Password reset OTP flow endpoints:
       - `POST /api/v1/auth/register` creates the user and dispatches a 6-digit OTP email through Brevo.
       - `POST /api/v1/auth/password/forgot` sends a 6-digit PIN through Brevo.
       - `POST /api/v1/auth/password/reset` verifies email + PIN and updates password.
   - `POST /api/v1/chat/rooms`, `GET /api/v1/chat/rooms/:id/messages`, and `POST /api/v1/chat/rooms/:id/messages` provide authenticated in-app chat room workflows.
   - `POST /api/v1/support/tickets`, `GET /api/v1/support/tickets`, `GET /api/v1/support/tickets/me`, and `PATCH /api/v1/support/tickets/:id` provide authenticated support ticket creation and lifecycle updates.
   - `GET /api/v1/admin/support/tickets` and `PATCH /api/v1/admin/support/tickets/:id` provide admin support inbox triage and assignment.
   - `GET /api/v1/wallet/balance`, `PATCH /api/v1/wallet/topup`, and `GET /api/v1/wallet/transactions` provide authenticated wallet balance and ledger workflows.
   - `DELETE /api/v1/users/me`, `GET /api/v1/users/me/deletion`, and `PATCH /api/v1/users/me/deletion/cancel` provide deferred 7-day account deletion with cancel support.
   - Growth and retention APIs now include referrals (`/api/v1/referrals/*`), loyalty (`/api/v1/loyalty/*`), subscriptions (`/api/v1/subscriptions/*`), spend analytics (`/api/v1/analytics/*`), vendor watch (`POST/DELETE /api/v1/vendors/:id/watch`), group-order split (`/api/v1/orders/group`, `/api/v1/orders/:id/split`), and refund requests (`POST /api/v1/orders/:id/refund`, `GET /api/v1/refunds/me`).

   Reliability standards:
   - Admin list endpoints expose shared pagination metadata (`meta.totalPages`, `meta.hasNextPage`, `meta.hasPreviousPage`).
   - App clients apply bounded retry/backoff, superseded request cancellation, and short-lived contracts feed caching.
   - User app now degrades gracefully when recommendations or notifications endpoints temporarily return server errors, keeping home and notifications usable with safe fallbacks.
   - Basket checkout summary is height-capped with internal scrolling so cart food items remain visible on smaller screens.
   - User cart now syncs with backend through `/api/v1/cart` (`GET`/`PATCH`) with local cache fallback in `user_app`.

   Trust surfaces:
   - Order create/list responses include ETA confidence envelope (`eta.min_minutes`, `eta.max_minutes`, `eta.confidence`).
   - Checkout and tracking experiences consume the same ETA trust contract for consistency.

   Vendor productivity:
   - Vendor order queue responses include pacing metadata (`pacing.elapsed_minutes`, `pacing.target_prep_minutes`, `pacing.recommended_prep_minutes`, `pacing.sla_risk`, `pacing.pace_label`).
   - Vendor dashboard queue rails, sorts, and prep-time assist consume the same pacing contract.

   Admin governance:
   - Admin dashboard now centers governance command workflows for moderation, audit, settings, and finance review.
   - Audit and settings flows emphasize decision traceability and safer local review before policy changes are saved.
   - Finance surfaces now highlight payout health and top-vendor visibility for faster operator review.

   Security hardening:
   - Authentication now uses backend-managed email/password credentials with backend-issued JWT access tokens.
   - Auth middleware rejects blocked or actively banned accounts with `403 Forbidden` on protected session flows.
   - Admin client now propagates `X-Client-Request-Id` and persistent `X-Device-Trust` headers for privileged API calls.
   - Backend error observability logs include server request id plus client request id correlation.
   - Sensitive admin actions (block user, reject vendor, cancel order) now require an explicit reason, captured through a dialog widget in the admin app and stored in the audit log.
   - Admin app `ReasonCaptureDialog` enforces a minimum 10-character justification before any destructive moderation action proceeds.
   - Admin app shell now surfaces session posture (`Trusted device` / `Untrusted device`) with an inline remediation banner so operators can confirm trust on active devices.
   - Customer-only mutations (`/orders`, `/orders/me`, `/addresses`, `/payments`, `/reviews`) now reject vendor/admin tokens with `403 Forbidden`.
   - Delivery location updates are now explicitly scoped to vendor or admin operators, and the vendor app clears/restores sessions only for vendor-role accounts.
   - Chat and support workflows now persist in Supabase-backed tables (`chat_rooms`, `chat_messages`, `support_tickets`) to avoid data loss on backend restart.

   Live API smoke test:
   - Run `cd backend && npm run test:api:live` to execute a live deployment API sweep.
   - Run `cd backend && npm run test:api:live:flow` for a single-flow test that attempts one signup, logs in as the user, then sweeps the remaining endpoints.
   - Optional credential env vars for broader role coverage: `LIVE_USER_EMAIL`, `LIVE_USER_PASSWORD`, `LIVE_VENDOR_EMAIL`, `LIVE_VENDOR_PASSWORD`, `LIVE_ADMIN_EMAIL`, `LIVE_ADMIN_PASSWORD`.
   - JSON response reports are written to `backend/reports/live-api-responses-latest.json` and timestamped files under `backend/reports/`.
   - Health checks are exposed as both `/health` and `/api/health` for compatibility with local and serverless path routing.
   - Several read/list APIs now degrade to safe empty or reduced-shape responses when optional DB relations are unavailable, reducing live `500` risk.
   - If production schema drift is detected, run `backend/scripts/live_contract_hardening.sql` in Supabase SQL Editor to align orders, reviews, admin_logs, and RLS policies with the current API contract.
   - For launch readiness, run `backend/scripts/final_launch_db_fix.sql` to align orders plus address-book schema (`user_addresses`) and policies used by `/api/v1/addresses` save flows.

3. **Vendor App**
   ```bash
   cd vendor_app
   flutter pub get
   flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1
   ```

4. **User App**
   ```bash
   cd user_app
   flutter pub get
    flutter run \
         --dart-define=BACKEND_API_URL=<BACKEND_API_URL>
   ```

    Release build example:
    ```bash
    flutter build apk --release \
       --dart-define=BACKEND_API_URL=<BACKEND_API_URL>
    ```

    Optional support contact defines:
   - `--dart-define=SUPPORT_EMAIL=<SUPPORT_EMAIL>`
    - `--dart-define=SUPPORT_EMAIL_SUBJECT="Support Request"`
   - `--dart-define=SUPPORT_PHONE=<SUPPORT_PHONE>`
   - `--dart-define=SUPPORT_PHONE_DISPLAY="<SUPPORT_PHONE_DISPLAY>"`

5. **Admin App**
   ```bash
   cd admin_app
   flutter pub get
   flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1
   ```

   Optional demo-login defines (disabled by default):
   - `--dart-define=DEMO_USER_EMAIL=... --dart-define=DEMO_USER_PASSWORD=...`
   - `--dart-define=DEMO_VENDOR_EMAIL=... --dart-define=DEMO_VENDOR_PASSWORD=...`
   - `--dart-define=DEMO_ADMIN_EMAIL=... --dart-define=DEMO_ADMIN_PASSWORD=...`

6. **Admin Web (React)**
   ```bash
   cd apps/admin_web
   npm install
   npm run dev
   ```

API contract versioning:
- Existing clients continue on `/api/v1`.
- Security-hardened finance/growth routes are available at `/api/v2` (`/wallet/*`, growth endpoints), with controlled migration and deprecation of unsafe v1 mutation patterns.

## 🎨 UI Language
- User app now uses a shell-based customer layout with a shared floating bottom navigation, branded ambient background, and consistent header treatment across Home, Orders, Cart, and Profile.
- User app primary flows now share the same visual language for discovery, checkout, tracking, and account management instead of screen-by-screen layout variations.
- Vendor and Admin apps now use a shared white-mode visual direction with stronger typographic hierarchy, cleaner card geometry, and calmer surface contrast.
- Vendor app theme is centralized in `vendor_app/lib/core/vendor_theme.dart` for consistent styling across future screens.
- Admin app theme has been refined in `admin_app/lib/core/config/admin_theme.dart` with expressive typography and improved readability for operations-heavy screens.

## 🔒 Tech Stack
- **Flutter** & **Dart**
- **React.js** (Vite), **Tailwind CSS**
- **Node.js**, **Fastify**, **TypeScript**
- **Supabase** (PostgreSQL, Auth, Realtime)

## 🤝 Contributing
Please read the internal developer guides before pushing changes to the `main` branch. Ensure your code passes all lint checks.

## 🌐 Website
- Website rollout details are maintained with the active launch documentation.
