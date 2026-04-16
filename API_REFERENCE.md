> Canonical consolidated reference: `PROJECT_DOCUMENTATION.md`

## Payments (Razorpay)

### `POST /payments/create-order`
Creates a Razorpay payment order and returns the order details and public key.
- **Request Body:**
  ```json
  {
    "order_id": "uuid-of-backend-order",
    "currency": "INR" // optional, defaults to INR
  }
  ```
- **Response** `200 OK`:
  ```json
  {
    "id": "order_xyz...", // Razorpay order ID
    "backend_order_id": "uuid-of-backend-order",
    "amount": 15000, // derived from backend order total, in paise
    "currency": "INR",
    ...other Razorpay order fields,
    "key": "rzp_test_..." // public Razorpay key for frontend
  }
  ```

### `POST /payments/verify`
Verifies a Razorpay payment signature after payment completion.
- **Request Body:**
  ```json
  {
    "razorpay_order_id": "order_xyz...",
    "razorpay_payment_id": "pay_abc...",
    "razorpay_signature": "..."
  }
  ```
- **Response** `200 OK`:
  ```json
  { "status": "success", "message": "Payment verified" }
  ```
- **Error Response** `400 Bad Request`:
  ```json
  { "status": "failure", "message": "Signature mismatch" }
  ```
# API Reference

This document outlines the core RESTful endpoints exposed by the Swift backend.

**Base URL (Production)**: `<API_BASE_URL>/api/v1`

**Base URL (Local Development)**: `http://localhost:3000/api/v1`

**Versioned secure routes (migration)**: `<API_BASE_URL>/api/v2`
- Finance and growth mutations now have `/api/v2` availability for controlled breaking-change rollout.
- Clients should migrate mutating wallet/loyalty/subscription flows to v2 contracts.

## Health Check

### `GET /health`
Primary backend health endpoint for local/server deployments.

### `GET /api/health`
Deployment-compatible health alias for serverless/API-gateway setups that preserve the `/api` prefix in forwarded paths.

## Contract Registry

Canonical source-of-truth endpoint for API request/response contracts consumed by backend, user_app, vendor_app, and admin_app.

### `GET /contracts/registry`
Returns versioned contract metadata for high-traffic endpoints and the shared error envelope.
- **Response** `200 OK`:
  ```json
  {
    "version": "2026.03.s11.4",
    "generatedAt": "2026-03-15T18:00:00.000Z",
    "totalEndpoints": 42,
    "errorEnvelope": {
      "description": "Standardized error envelope for non-2xx responses.",
      "fields": [
        { "name": "error", "type": "string", "required": true, "description": "Machine-readable error type." },
        { "name": "message", "type": "string", "required": true, "description": "Human-readable message." }
      ]
    },
    "endpoints": [
      {
        "id": "auth.session.create",
        "method": "POST",
        "path": "/api/v1/auth/session"
      }
    ]
  }
  ```

### `GET /contracts/changelog`
Returns chronological, versioned contract changes for consumer compatibility checks.
- Optional query params:
  - `since`: ISO timestamp filter (returns only newer changes)
- **Response** `200 OK`:
  ```json
  {
    "version": "2026.03.s11.4",
    "count": 27,
    "changes": [
      {
        "id": "chg-2026-03-15-01",
        "changeType": "added",
        "endpointId": "contracts.flags.get",
        "summary": "Added contracts feature-flags endpoint for staged rollout control."
      }
    ]
  }
  ```

### `GET /contracts/flags`
Returns feature flags for staged contract-rollout adoption across app consumers.
- **Response** `200 OK`:
  ```json
  {
    "version": "2026.03.s11.4",
    "count": 11,
    "flags": [
      {
        "key": "contracts.error_taxonomy.v2",
        "enabled": true,
        "rollout": "global"
      }
    ]
  }
  ```

## Admin Reliability and Pagination

Admin list endpoints now follow a shared pagination envelope with metadata for predictable client behavior.

### Shared query parameters
- `page`: 1-based page number (default: `1`)
- `limit`: page size (default: `20`, max: `100`)

### Shared response metadata
```json
{
  "page": 1,
  "limit": 20,
  "total": 57,
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 57,
    "totalPages": 3,
    "hasNextPage": true,
    "hasPreviousPage": false
  }
}
```

### `GET /admin/orders`
Returns paginated orders and metadata.

Implementation note:
- If optional join relations are unavailable in a deployment schema, the endpoint falls back to a reduced order shape instead of returning `500`.

### `GET /admin/users`
Returns paginated users and metadata.

### `GET /admin/audit`
Returns paginated admin audit logs and metadata. Each entry includes a `reason` field for sensitive actions.

Implementation note:
- If `admin_logs` is unavailable in a deployment schema, the endpoint returns an empty paginated result (`logs: []`) instead of `500`.

### `GET /admin/vendors/pending`
Returns paginated pending vendors and metadata.

Implementation note:
- If owner joins or status-filter support are unavailable in a deployment schema, the endpoint degrades safely with an empty paginated result.

### `GET /admin/stats`
Returns top-level admin metrics.

- **Response** `200 OK`:
  ```json
  {
    "stats": {
      "users": 120,
      "vendors": 18,
      "orders": 542,
      "revenue": 128450,
      "gmv": 128450
    }
  }
  ```

Notes:
- `revenue` is the canonical contract field for admin consumers.
- `gmv` remains as a backward-compatible alias and mirrors `revenue`.

### `GET /admin/dashboard/summary`
Returns dashboard summary totals used by admin stat cards.

- **Response** `200 OK`:
  ```json
  {
    "summary": {
      "total_users": 120,
      "total_vendors": 18,
      "active_orders": 542,
      "completed_orders": 510,
      "revenue": 128450
    }
  }
  ```

### `GET /admin/charts`
Returns 7-day trend points for dashboard charts.

- **Response** `200 OK`:
  ```json
  {
    "chartData": [
      { "name": "Mon", "orders": 42, "revenue": 12840 },
      { "name": "Tue", "orders": 39, "revenue": 11790 }
    ]
  }
  ```

### `GET /admin/finance/summary`
Returns finance summary totals for admin finance cards.

- **Response** `200 OK`:
  ```json
  {
    "summary": {
      "total_revenue": 128450,
      "today_revenue": 4300,
      "week_revenue": 25200,
      "month_revenue": 101100
    }
  }
  ```


## Sensitive Action Safeguards

The following admin mutation endpoints require a `reason` string in their request body (minimum 10 characters). The reason is validated server-side (returns `400 ValidationError` if absent or blank) and stored in the audit log, retrievable via `GET /admin/audit`.

| Endpoint | Condition |
|---|---|
| `PATCH /api/v1/admin/users/:id/block` | Required when `blocked: true` |
| `PATCH /api/v1/admin/vendors/:id/reject` | Always required |
| `PATCH /api/v1/admin/orders/:id/cancel` | Always required |

**Request body example (block user):**
```json
{ "blocked": true, "reason": "Repeated terms of service violations." }
```

**Request body example (reject vendor):**
```json
{ "reason": "Application does not meet food safety documentation requirements." }
```
## Standard Error Taxonomy

All non-2xx endpoints return the same envelope:

```json
{
  "error": "ValidationError|Unauthorized|Forbidden|NotFound|Conflict|InternalServerError",
  "message": "Human-readable message"
}
```

Status mapping:
- `400` -> `ValidationError`
- `401` -> `Unauthorized`
- `403` -> `Forbidden`
- `404` -> `NotFound`
- `409` -> `Conflict`
- `500` -> `InternalServerError`

## Authentication

## Chat and Support

All chat and support routes require an authenticated bearer token.

### `POST /chat/rooms`
Creates a chat room for support or operational conversations.

- **Request body**:
  ```json
  {
    "topic": "Order issue follow-up",
    "participantIds": ["agent-user-id"]
  }
  ```
- **Response** `201 Created`:
  ```json
  {
    "room": {
      "id": "room_...",
      "topic": "Order issue follow-up",
      "status": "active",
      "createdBy": "user-id",
      "participants": ["user-id", "agent-user-id"],
      "createdAt": "2026-03-27T12:00:00.000Z",
      "updatedAt": "2026-03-27T12:00:00.000Z"
    }
  }
  ```

### `GET /chat/rooms/:id/messages`
Returns room messages for room participants (admins can read all rooms).

- Optional query params:
  - `limit`: number of recent messages to return (default `50`, max `100`)
- **Response** `200 OK`:
  ```json
  {
    "roomId": "room_...",
    "messages": [
      {
        "id": "msg_...",
        "roomId": "room_...",
        "senderId": "agent-user-id",
        "content": "Hello, how can I help?",
        "createdAt": "2026-03-27T12:05:00.000Z"
      }
    ],
    "meta": {
      "count": 1,
      "limit": 50
    }
  }
  ```

### `POST /chat/rooms/:id/messages`
Adds a message to an active room.

- **Request body**:
  ```json
  {
    "content": "I am missing one item in my order."
  }
  ```
- **Response** `201 Created`:
  ```json
  {
    "message": {
      "id": "msg_...",
      "roomId": "room_...",
      "senderId": "user-id",
      "content": "I am missing one item in my order.",
      "createdAt": "2026-03-27T12:06:00.000Z"
    }
  }
  ```

### `POST /support/tickets`
Creates a support ticket.

- **Request body**:
  ```json
  {
    "subject": "Missing item",
    "description": "My combo meal was missing the drink.",
    "priority": "high",
    "orderId": "order-id-optional"
  }

### `GET /admin/support/tickets`
Returns paginated support inbox entries for admins.

- Query params:
  - `page` (default `1`)
  - `limit` (default `20`, max `100`)
  - `status` (optional: `open|in_progress|resolved|closed`)
- **Response** `200 OK`:
  ```json
  {
    "tickets": [
      {
        "id": "ticket-id",
        "status": "open",
        "priority": "high",
        "createdBy": "user-id"
      }
    ],
    "page": 1,
    "limit": 20,
    "total": 1,
    "meta": {
      "totalPages": 1,
      "hasNextPage": false,
      "hasPreviousPage": false
    }
  }
  ```

### `PATCH /admin/support/tickets/:id`
Admin triage endpoint for status, priority, assignment, and resolution notes.

- **Request body**:
  ```json
  {
    "status": "in_progress",
    "priority": "high",
    "assigneeId": "admin-or-agent-user-id",
    "resolutionNote": "Working with vendor on replacement."
  }
  ```

### `POST /admin/notifications/broadcast`
Broadcast a notification to users, vendors, or both audiences from the admin portal.

- **Request body**:
  ```json
  {
    "title": "Lunch service delay",
    "body": "Kiosk delivery windows are delayed by 15 minutes today.",
    "audience": "both",
    "type": "service_update",
    "metadata": { "source": "admin_web" }
  }
  ```
- **Response** `201 Created`:
  ```json
  {
    "message": "Notification sent to users and vendors",
    "audiences": ["user", "vendor"],
    "recipients": 24,
    "sent": 24,
    "failed": 0
  }
  ```

## Wallet

All wallet routes require an authenticated user token.

### `GET /wallet/balance`
- **Response** `200 OK`:
  ```json
  {
    "balance": 240.0,
    "currency": "INR"
  }
  ```

### `PATCH /wallet/topup`
- **Request body**:
  ```json
  {
    "amount": 100,
    "source": "upi",
    "status": "pending",
    "idempotencyKey": "optional-idempotency-key"
  }
  ```
- Security rules:
  - Non-admin callers can only create `pending` top-up requests.
  - Only admin-verified actions may mark top-ups `completed` or `failed`.
  - Admin settlement can target a specific user via `userId`.
- **Response** `200 OK`:
  ```json
  {
    "balance": 340,
    "currency": "INR",
    "transaction": {
      "id": "tx-id",
      "amount": 100,
      "transaction_type": "topup",
      "status": "completed"
    }
  }
  ```

### `GET /wallet/transactions`
Returns paginated wallet transaction history.

## Account Deletion

All account deletion routes require an authenticated user token.

### `DELETE /users/me`
Schedules account deletion after a 7-day cancellation window.

### `GET /users/me/deletion`
Returns current deletion-request state (or `null` if no request exists).

### `PATCH /users/me/deletion/cancel`
Cancels a pending scheduled deletion request.

## Growth & Retention

Authenticated user endpoints:

- `POST /referrals/generate`
- `GET /referrals/code/:code`
- `POST /referrals/redeem`
- `GET /loyalty/tier`
- `POST /loyalty/points`
- `GET /subscriptions`
- `POST /subscriptions/create`
- `GET /analytics/spending`
- `GET /analytics/vendors`
- `POST /vendors/:id/watch`
- `DELETE /vendors/:id/watch`
- `POST /orders/group`
- `PATCH /orders/:id/split`
- `POST /orders/:id/refund`
- `GET /refunds/me`

Admin-only mutation endpoints:
- `POST /loyalty/points`
- `POST /subscriptions/create`
- `PATCH /subscriptions/:id/renew`

### `GET /support/tickets`
Returns support tickets visible to the authenticated user:
- Admin users: all tickets
- Non-admin users: only tickets they created

### `GET /support/tickets/me`
Returns only tickets created by the authenticated user.

### `PATCH /support/tickets/:id`
Updates ticket status/details.

Rules:
- Admins can update `status`, `priority`, `assigneeId`, and `resolutionNote`.
- Ticket owners can close their own ticket (`status: "closed"`) and update `resolutionNote`.

## Public Discovery

### `GET /public/recommendations`
Returns backend-ranked food item recommendations for the home feed.

- Optional query params:
  - `limit`: number of items to return (default `12`, max `30`)

- **Response** `200 OK`:
  ```json
  [
    {
      "id": "menu-item-uuid",
      "name": "Masala Dosa",
      "description": "Crispy dosa with potato masala",
      "price": 120,
      "image_url": "https://...",
      "category": "Breakfast",
      "vendor": {
        "id": "vendor-uuid",
        "name": "Annapoorna Bhavan",
        "is_open": true
      },
      "recommendation": {
        "score": 0.87,
        "signals": {
          "popularity_orders": 24,
          "recent_orders": 9,
          "vendor_rating": 4.6,
          "vendor_open": true
        }
      }
    }
  ]
  ```

Implementation note:
- If recommendation dependencies are unavailable (for example, relation drift or missing supporting tables), the endpoint returns `200` with an empty array fallback.

All endpoints under `/auth` manage session handling.

Security hardening notes:
- Blocked or actively banned accounts are denied with `403 Forbidden` on authenticated session flows.
- Malformed `Authorization` header values (non-bearer or empty bearer token) are rejected with `401 Unauthorized`.
- Dedicated admin and vendor surfaces reject restored or newly created sessions when the resolved role does not match the app.

### `POST /auth/session`
Login an existing user or vendor.
- **Request Body**:
  ```json
  {
    "email": "<USER_EMAIL>",
    "password": "securepassword123"
  }
  ```
- **Response** `200 OK`:
  ```json
  {
    "user": {
      "id": "uuid",
      "email": "<USER_EMAIL>",
      "role": "user"
    },
    "session": { "access_token": "...", "expires_in": 3600 }
  }
  ```
- **Error Responses**:
  - `401 Unauthorized` for missing/invalid bearer format on protected follow-up flows.
  - `403 Forbidden` when account is blocked or currently banned.

### `POST /auth/register`
Register a new customer.
- **Request Body**:
  ```json
  {
    "email": "<USER_EMAIL>",
    "password": "securepassword123",
    "name": "Jane Doe"
  }
  ```
- **Response** `201 Created`:
  ```json
  { "message": "Registration successful", "user": { "id": "uuid" } }
  ```
- **Notes**:
  - On successful registration, backend dispatches a 6-digit email OTP through Brevo to the registered email address.
- **Error Responses**:
  - `400 ValidationError` when name/email/password are missing or password is shorter than 8 characters.
  - `409 Conflict` when the email is already registered.

### `POST /auth/password/forgot`
Request a 6-digit password reset PIN by email (Brevo).
- **Request Body**:
  ```json
  {
    "email": "<USER_EMAIL>"
  }
  ```
- **Response** `200 OK`:
  ```json
  {
    "message": "If the account exists, a 6-digit reset code has been sent."
  }
  ```
- **Notes**:
  - Response is intentionally generic to prevent account enumeration.
  - PIN expiration and retry thresholds are enforced server-side.

### `POST /auth/password/reset`
Reset account password using email + 6-digit PIN.
- **Request Body**:
  ```json
  {
    "email": "<USER_EMAIL>",
    "pin": "123456",
    "new_password": "newSecurePass123"
  }
  ```
- **Response** `200 OK`:
  ```json
  {
    "message": "Password updated successfully"
  }
  ```
- **Error Responses**:
  - `400 ValidationError` for invalid payload, invalid PIN, or expired PIN.
  - `429 TooManyRequests` when invalid PIN attempts exceed configured limit.

## Order Management

Routes protected by the `authenticate` middleware.

Protected route headers:
- Required: `Authorization: Bearer <JWT>`
- Optional observability: `X-Client-Request-Id: <id>`
- Optional device posture: `X-Device-Trust: <device-trust-id>`

Admin client posture behavior:
- Admin UI must visibly indicate session posture (`Trusted device` or `Untrusted device`) while authenticated.
- Untrusted posture should expose an in-context trust-confirmation control for operators before high-sensitivity workflows.

### `POST /orders`
Place a new food order.
- **Headers**: `Authorization: Bearer <JWT>`
- **Request Body**:
  ```json
  {
    "vendor_id": "uuid",
    "total_amount": 150.0,
    "promo_code": "SAVE10",
    "scheduled_for": "2026-03-19T18:30:00.000Z",
    "items": [
      {
        "id": "uuid",
        "quantity": 2,
        "price": 75.00
      }
    ]
  }
  ```
  Notes:
  - `items[]` accepts either legacy fields (`id`, `price`) or compatibility aliases (`menu_item_id`, `unit_price`).
  - `promo_code` and `scheduled_for` are optional.
  - `delivery_mode`, `delivery_building_id`, `delivery_room`, `delivery_zone_id`, and `quiet_mode` are optional for class delivery.
  - Response also includes delivery-to-class fields (delivery_mode, delivery_building_id, delivery_room, delivery_zone_id, quiet_mode, handoff_code, handoff_status, handoff_proof_url, class_start_at, class_end_at) when provided.
- **Response** `201 Created`:
  ```json
  {
    "id": "uuid",
    "user_id": "uuid",
    "vendor_id": "uuid",
    "total_amount": 150.0,
    "discount_amount": 15.0,
    "promo_code": "SAVE10",
    "scheduled_for": "2026-03-19T18:30:00.000Z",
    "status": "pending",
    "eta": {
      "min_minutes": 14,
      "max_minutes": 24,
      "confidence": "high",
      "updated_at": "2026-03-15T13:00:00.000Z",
      "note": "ETA range is a rolling estimate based on queue status and order age."
    }
  }
  ```

### `GET /orders/me`
Fetch orders for the authenticated user.
- **Headers**: `Authorization: Bearer <JWT>`
- **Response** `200 OK`:
  ```json
  [
    {
       "id": "uuid",
       "status": "preparing",
       "total_amount": 150.00,
       "discount_amount": 15.0,
       "promo_code": "SAVE10",
       "scheduled_for": "2026-03-19T18:30:00.000Z",
       "vendors": { "name": "Canteen A" },
       "eta": {
         "min_minutes": 6,
         "max_minutes": 14,
         "confidence": "medium"
       }
    }
  ]
  ```

### `PATCH /orders/:id/cancel`

Cancel an order before it reaches the kitchen.
- **Headers**: `Authorization: Bearer <JWT>`
- **Notes**:
  - Only orders in `pending` or `accepted` status can be cancelled by the customer.
- **Response** `200 OK`:
  ```json
  {
    "id": "uuid",
    "status": "cancelled",
    "eta": {
      "min_minutes": 0,
      "max_minutes": 0,
      "confidence": "low"
    }
  }
  ```

### `PATCH /orders/:id/status`
Update order status (Vendor only).
- **Headers**: `Authorization: Bearer <JWT>`
- **Request Body**:
  ```json
  { "status": "preparing" }
  ```
- **Lifecycle transition rules**:
  - `pending -> accepted | cancelled`
  - `accepted -> preparing | cancelled`
  - `preparing -> ready`
  - `ready -> out_for_delivery | completed`
  - `out_for_delivery -> completed`
  - Invalid transitions return `409 Conflict`.


### `GET /orders/slots`
Fetch available delivery windows for scheduling.
- **Headers**: `Authorization: Bearer <JWT>`
- **Response** `200 OK`:
  ```json
  {
    "days": 3,
    "slot_minutes": 30,
    "slots": [
      {
        "starts_at": "2026-03-19T18:00:00.000Z",
        "ends_at": "2026-03-19T18:30:00.000Z",
        "label": "06:00 PM - 06:30 PM",
        "day_label": "Wed, Mar 19"
      }
    ]
  }
  ```


## Notifications

### `GET /notifications`
Fetch notifications for the authenticated user/vendor/admin.
- **Headers**: `Authorization: Bearer <JWT>`
- When push credentials are configured, newly created notifications are also fanned out via FCM/APNS to registered device tokens.
- **Response** `200 OK`:
  ```json
  [
    {
      "id": "uuid",
      "title": "Order status updated",
      "body": "Order #1A2B3C4D is now PREPARING",
      "type": "order_status",
      "metadata": { "order_id": "uuid", "status": "preparing" },
      "is_read": false,
      "created_at": "2026-03-19T12:00:00.000Z"
    }
  ]
  ```

### `PATCH /notifications/:id/read`
Mark a notification as read.
- **Headers**: `Authorization: Bearer <JWT>`
- **Response** `200 OK`:
  ```json
  {
    "id": "uuid",
    "is_read": true
  }
  ```

### `POST /notifications/device`
Register a device token for push notifications.
- **Headers**: `Authorization: Bearer <JWT>`
- **Request Body**:
  ```json
  { "token": "device_token", "platform": "android" }
  ```
- **Response** `201 Created`:
  ```json
  { "id": "uuid", "token": "device_token" }
  ```

Implementation note:
- In deployments where device token persistence is denied by policy/RLS, this endpoint may return a noop success payload (`{ "success": true }`) to avoid blocking app flows.

### `DELETE /notifications/device`
Remove a device token.
- **Headers**: `Authorization: Bearer <JWT>`
- **Request Body**:
  ```json
  { "token": "device_token" }
  ```
- **Response** `200 OK`:
  ```json
  { "success": true }
  ```

## Promotions

### `GET /promos/active`
Fetch active promo codes for authenticated users.
- **Headers**: `Authorization: Bearer <JWT>`
- **Response** `200 OK`:
  ```json
  [
    {
      "id": "uuid",
      "code": "SAVE10",
      "discount_type": "percent",
      "discount_value": 10,
      "min_order_amount": 100,
      "is_active": true
    }
  ]
  ```

### `POST /promos/validate`
Validate a promo code against an order total.
- **Headers**: `Authorization: Bearer <JWT>`
- **Request Body**:
  ```json
  { "code": "SAVE10", "order_total": 200 }
  ```
- Compatibility: `order_amount` is also accepted as a legacy alias for `order_total`.
- **Response** `200 OK`:
  ```json
  {
    "valid": true,
    "promo_id": "uuid",
    "code": "SAVE10",
    "discount_type": "percent",
    "discount_value": 10,
    "discount_amount": 20,
    "final_amount": 180
  }
  ```
- **Invalid promo response** `200 OK`:
  ```json
  {
    "valid": false,
    "message": "Promo code not found",
    "code": "WELCOME10"
  }
  ```

### `GET /admin/promos`
Fetch all promo codes (Admin only).
- **Headers**: `Authorization: Bearer <JWT>`

### `POST /admin/promos`
Create a promo code (Admin only).
- **Headers**: `Authorization: Bearer <JWT>`
- **Request Body**:
  ```json
  {
    "code": "SAVE10",
    "discount_type": "percent",
    "discount_value": 10,
    "min_order_amount": 100,
    "usage_limit": 500
  }
  ```

### `PATCH /admin/promos/:id`
Update a promo code (Admin only).
- **Headers**: `Authorization: Bearer <JWT>`
- **Request Body**:
  ```json
  { "is_active": false }
  ```


## Campus Delivery

### `GET /public/buildings`
List active campus buildings.

### `GET /public/zones`
List active delivery zones.
- Optional query params:
  - `building_id`: filter zones by building


### `GET /admin/campus/buildings`
Admin list of campus buildings.
- **Headers**: `Authorization: Bearer <JWT>`

### `POST /admin/campus/buildings`
Create a campus building (Admin only).

### `PATCH /admin/campus/buildings/:id`
Update a campus building (Admin only).

### `GET /admin/campus/zones`
Admin list of delivery zones.

### `POST /admin/campus/zones`
Create a delivery zone (Admin only).

### `PATCH /admin/campus/zones/:id`
Update a delivery zone (Admin only).

### `GET /class-sessions`
List the authenticated user's class sessions.
- **Headers**: `Authorization: Bearer <JWT>`

### `POST /class-sessions`
Create a class session.
- **Headers**: `Authorization: Bearer <JWT>`
- **Request Body**:
  ```json
  { "building_id": "uuid", "room": "B-201", "starts_at": "2026-03-19T09:00:00.000Z", "ends_at": "2026-03-19T10:00:00.000Z" }
  ```

### `PATCH /class-sessions/:id`
Update a class session.

### `DELETE /class-sessions/:id`
Delete a class session.


### `PATCH /orders/:id/handoff`
Update class handoff status (Vendor only).
- **Headers**: `Authorization: Bearer <JWT>`
- **Request Body**:
  ```json
  { "status": "arrived_class", "proof_url": "https://..." }
  ```
  - `proof_url` is required when `status` is `delivered` or `failed`.
  - If the order has a `delivery_zone_id` with GeoJSON, handoff updates to `arrived_class` or `delivered` validate the latest courier location inside the zone.

## Vendor Operations

Requires vendor role.

### `GET /vendor-ops/profile`
Fetch authenticated vendor's profile.

### `GET /vendor-ops/orders`
Fetch orders for the authenticated vendor.

Implementation note:
- If optional joined relations are unavailable in a deployment schema, the endpoint falls back to plain order rows rather than returning `500`.

- **Response** `200 OK`:
  ```json
  [
    {
      "id": "uuid",
      "status": "preparing",
      "total_amount": 220.0,
      "discount_amount": 15.0,
      "promo_code": "SAVE10",
      "scheduled_for": "2026-03-19T18:30:00.000Z",
      "eta": {
        "min_minutes": 6,
        "max_minutes": 14,
        "confidence": "medium"
      },
      "pacing": {
        "elapsed_minutes": 9,
        "target_prep_minutes": 12,
        "recommended_prep_minutes": 12,
        "sla_risk": "medium",
        "pace_label": "watch",
        "note": "Pacing score blends elapsed queue time, order size, and current status."
      }
    }
  ]
  ```

### `GET /vendor-ops/orders/active`
Fetch active vendor queue only.
- **Headers**: `Authorization: Bearer <JWT>`
- Active statuses: `pending`, `accepted`, `preparing`, `ready`, `out_for_delivery`.

### `GET /vendor-ops/orders/:id`
Fetch full details for a single vendor order (includes `order_items`).
- **Headers**: `Authorization: Bearer <JWT>`
- Includes additional sections:
  - `customer` with masked contact and optional email/phone.
  - `payment` summary (`status`, `mode`, `amount`, `provider_ref`).
  - `delivery_partner.live_location` when courier coordinates are available.

### `POST /vendor-ops/orders/:id/accept`
Accept a pending order.
- **Headers**: `Authorization: Bearer <JWT>`

### `POST /vendor-ops/orders/:id/reject`
Reject/cancel a pending order.
- **Headers**: `Authorization: Bearer <JWT>`

### `POST /vendor-ops/orders/:id/status`
Advance order lifecycle from vendor operations surface.
- **Headers**: `Authorization: Bearer <JWT>`
- **Request Body**:
  ```json
  { "status": "ready" }
  ```
- Uses the same transition rules as `PATCH /orders/:id/status`.

### `GET /vendor-ops/orders/stream`
Subscribe to vendor order realtime events over Server-Sent Events (SSE).
- **Headers**: `Authorization: Bearer <JWT>`
- Event types include `stream_connected`, `order_created`, `order_status_changed`, `order_handoff_changed`.

### `GET /vendor-ops/store-controls`
Fetch operational store controls for the authenticated vendor.
- **Headers**: `Authorization: Bearer <JWT>`
- **Response**:
  - `controls.is_open`
  - `controls.auto_accept_orders`
  - `controls.preparation_time_avg`
  - `controls.busy_mode_enabled`
  - `controls.busy_mode_message`
  - `controls.holiday_until`

### `PATCH /vendor-ops/store-controls`
Update operational store controls for the authenticated vendor.
- **Headers**: `Authorization: Bearer <JWT>`
- **Request Body** (partial updates allowed):
  ```json
  {
    "is_open": true,
    "auto_accept_orders": false,
    "preparation_time_avg": 20,
    "busy_mode_enabled": true,
    "busy_mode_message": "High queue, expect +10 mins",
    "holiday_until": "2026-03-28T18:00:00.000Z"
  }
  ```

### `GET /vendor-ops/finance/earnings`
Fetch vendor earnings summary and per-period trend.
- **Headers**: `Authorization: Bearer <JWT>`

### `GET /vendor-ops/finance/payouts`
Fetch payout buckets (processing, completed, scheduled) for vendor finance operations.
- **Headers**: `Authorization: Bearer <JWT>`

### `GET /vendor-ops/finance/transactions`
Fetch transaction ledger rows enriched with payment and order metadata.
- **Headers**: `Authorization: Bearer <JWT>`

### `GET /vendor-ops/finance/tax-reports`
Fetch vendor tax report periods and export metadata.
- **Headers**: `Authorization: Bearer <JWT>`

### `GET /vendor-ops/analytics/sales`
Fetch sales analytics summary and time-series.
- **Headers**: `Authorization: Bearer <JWT>`

### `GET /vendor-ops/analytics/performance`
Fetch vendor order funnel performance metrics.
- **Headers**: `Authorization: Bearer <JWT>`

### `GET /vendor-ops/analytics/peak-hours`
Fetch hourly demand distribution for vendor orders.
- **Headers**: `Authorization: Bearer <JWT>`

### `GET /vendor-ops/analytics/top-items`
Fetch top-performing menu items by volume and sales.
- **Headers**: `Authorization: Bearer <JWT>`

### `GET /vendor-ops/staff/management`
Fetch vendor staff management roster.
- **Headers**: `Authorization: Bearer <JWT>`

### `POST /vendor-ops/staff/management`
Create a vendor staff member record.
- **Headers**: `Authorization: Bearer <JWT>`
- **Request Body**:
  ```json
  {
    "name": "Kitchen Lead",
    "role_key": "manager",
    "status": "active",
    "email": "<STAFF_EMAIL>",
    "phone": "<STAFF_PHONE>"
  }
  ```

### `PATCH /vendor-ops/staff/management/:staffId`
Update a vendor staff member record.
- **Headers**: `Authorization: Bearer <JWT>`
- **Request Body**: partial update for `name`, `role_key`, `status`, `email`, `phone`.

### `DELETE /vendor-ops/staff/management/:staffId`
Delete a vendor staff member record.
- **Headers**: `Authorization: Bearer <JWT>`

### `GET /vendor-ops/staff/invitations`
List vendor staff invitation records with onboarding status.
- **Headers**: `Authorization: Bearer <JWT>`

### `POST /vendor-ops/staff/invitations`
Create a staff invitation tied to real user identity by email.
- **Headers**: `Authorization: Bearer <JWT>`
- **Request Body**:
  ```json
  {
    "email": "<STAFF_EMAIL>",
    "role_key": "cashier",
    "expires_in_days": 7
  }
  ```

### `GET /vendor-ops/staff/roles`
Fetch vendor staff role catalog and assignment counts.
- **Headers**: `Authorization: Bearer <JWT>`

### `PATCH /vendor-ops/staff/roles`
Upsert vendor role definitions.
- **Headers**: `Authorization: Bearer <JWT>`
- **Request Body**:
  ```json
  {
    "roles": [
      {
        "key": "manager",
        "permissions": ["orders.manage", "menu.manage", "reports.view"]
      }
    ]
  }
  ```

### `GET /vendor-ops/reports/download`
Fetch downloadable report artifacts for the vendor.
- **Headers**: `Authorization: Bearer <JWT>`

### `GET /vendor-ops/reports/sales`
Fetch sales-focused report cards.
- **Headers**: `Authorization: Bearer <JWT>`

### `GET /vendor-ops/reports/orders`
Fetch order-focused operational reports.
- **Headers**: `Authorization: Bearer <JWT>`

### `GET /vendor-ops/preferences/language`
Fetch language preference options for the vendor app.
- **Headers**: `Authorization: Bearer <JWT>`

### `PATCH /vendor-ops/preferences/language`
Update selected language preference.
- **Headers**: `Authorization: Bearer <JWT>`
- **Request Body**:
  ```json
  {
    "current": "English"
  }
  ```

### `GET /vendor-ops/preferences/theme`
Fetch theme preference options for the vendor app.
- **Headers**: `Authorization: Bearer <JWT>`

### `PATCH /vendor-ops/preferences/theme`
Update theme preference settings.
- **Headers**: `Authorization: Bearer <JWT>`
- **Request Body**: provide one or both fields.
  ```json
  {
    "dark_mode": true,
    "high_contrast": false
  }
  ```

### `GET /vendor-ops/preferences/app`
Fetch app-level vendor preferences (notifications, receipt printing, compact mode).
- **Headers**: `Authorization: Bearer <JWT>`

### `PATCH /vendor-ops/preferences/app`
Update app-level vendor preferences.
- **Headers**: `Authorization: Bearer <JWT>`
- **Request Body**: provide one or more fields.
  ```json
  {
    "compact_cards": true,
    "silent_alerts": false,
    "notification_enabled": true,
    "auto_print_receipts": true
  }
  ```

### `POST /auth/staff/onboarding/accept`
Accept a staff invitation as the authenticated user identity.
- **Headers**: `Authorization: Bearer <JWT>`
- **Request Body**:
  ```json
  {
    "token": "invitation-token"
  }
  ```

### `GET /vendor-ops/stats`
Fetch vendor performance statistics.

## Menu Management

### `GET /vendor-ops/menu` (Vendor only)
Fetch the authenticated vendor menu snapshot with both grouped categories and a flattened items list.
- **Headers**: `Authorization: Bearer <JWT>`
- **Response Body**:
  ```json
  {
    "categories": [
      {
        "id": "uuid",
        "vendor_id": "uuid",
        "category_name": "Burgers",
        "sort_order": 1,
        "created_at": "2026-03-24T10:00:00.000Z",
        "updated_at": "2026-03-24T10:10:00.000Z",
        "menu_items": [
          {
            "id": "uuid",
            "menu_id": "uuid",
            "name": "Cheese Burger",
            "description": "Double patty",
            "price": 149,
            "is_available": true,
            "image_url": "https://...",
            "created_at": "2026-03-24T10:00:00.000Z",
            "updated_at": "2026-03-24T10:10:00.000Z"
          }
        ]
      }
    ],
    "items": [
      {
        "id": "uuid",
        "menu_id": "uuid",
        "name": "Cheese Burger",
        "description": "Double patty",
        "price": 149,
        "is_available": true,
        "image_url": "https://...",
        "created_at": "2026-03-24T10:00:00.000Z",
        "updated_at": "2026-03-24T10:10:00.000Z",
        "category": "Burgers",
        "category_name": "Burgers",
        "category_id": "uuid",
        "category_sort_order": 1,
        "vendor_id": "uuid"
      }
    ]
  }
  ```
- `image_url` accepts `https://` URLs and data URLs (`data:image/...;base64,...`) for app upload flows.

### `POST /vendor-ops/menu/upload-image` (Vendor only)
Upload a menu item image to secure storage and receive a public HTTPS URL.
- **Headers**: `Authorization: Bearer <JWT>`, `Content-Type: application/json`
- **Request Body**:
  ```json
  {
    "imageData": "base64-encoded-image-bytes",
    "mimeType": "image/jpeg|image/png|image/webp|image/gif"
  }
  ```
- **Response (201 Created)**:
  ```json
  {
    "url": "https://{project-id}.supabase.co/storage/v1/object/public/menu-items/vendor/{vendorId}/items/{fileName}",
    "path": "vendor/{vendorId}/items/{fileName}",
    "mimeType": "image/jpeg",
    "sizeBytes": 12345
  }
  ```
- **Error (400 Bad Request)**:
  ```json
  {
    "error": "validation_error",
    "message": "File too large. Maximum size: 5MB. Got: 6.50MB"
  }
  ```
- **Constraints**:
  - Maximum file size: 5 MB
  - Allowed MIME types: `image/jpeg`, `image/png`, `image/webp`, `image/gif`
  - Returns public HTTPS URL suitable for direct embedding in `image_url` fields
  - Files are cached for 1 year; use unique filenames for cache busting if needed

### `GET /menus/vendor/:vendorId`
Fetch menu items for a specific vendor.

### `POST /menus` (Vendor only)
Create a new menu.

### `PATCH /menus/:id` (Vendor only)
Update menu details.

### `DELETE /menus/:id` (Vendor only)
Remove a menu.

### `POST /menus/items` (Vendor only)
Add a new item to a menu.

### `PATCH /menus/items/:id` (Vendor only)
Update a menu item.

### `DELETE /menus/items/:id` (Vendor only)
Remove a menu item.

## Public Search & Discovery

### `GET /public/vendors`
List all active vendors.

### `GET /public/search`
Perform a global search across menu items and vendors.

## Payment Integration

Protected by `authenticate` + customer-user role enforcement.

### `POST /payments/create-order`
Initialize a Razorpay order using a previously created backend order (`order_id`).

### `POST /payments/verify`
Verify payment signature from Razorpay.

## Address Management

Protected by `authenticate` + customer-user role enforcement.

### `GET /addresses`
Fetch all saved addresses for the user.

### `POST /addresses`
Add a new address.

### `DELETE /addresses/:id`
Delete a specific address.

### `PATCH /addresses/:id/default`
Set an address as the default.

## Cart Sync

Protected by `authenticate` + customer-user role enforcement.

### `GET /cart`
Fetch the current authenticated user's backend-synced cart snapshot.

### `PATCH /cart`
Replace the authenticated user's cart with the provided `items` array payload.

## Customer Reviews

### `GET /reviews/vendor/:vendorId`
Fetch reviews for a specific vendor.

### `POST /reviews` (Authenticated User)
Submit a new review for an order.

## Delivery Tracking

Protected by `authenticate` middleware; write access is vendor/admin scoped.

### `GET /delivery/:orderId/location`
Fetch the current location of a delivery.

### `POST /delivery/location` (Vendor/Admin)
Update the delivery location.

## RBAC Parity Hardening

- Customer mutations now require a `user` role token and return `403 Forbidden` for vendor/admin principals:
  - `POST /orders`
  - `GET /orders/me`
  - `PATCH /orders/:id/cancel`
  - `GET|PATCH /cart`
  - `GET|POST|DELETE|PATCH /addresses`
  - `POST /payments/create-order`
  - `POST /payments/verify`
  - `POST /reviews`
- Delivery write access now matches the documented operational scope: `POST /delivery/location` requires vendor/admin role, while `GET /delivery/:orderId/location` remains authenticated.
- The contracts feed reflects this as registry version `2026.03.s11.4`, changelog count `28`, and feature-flag count `11`.

## Admin Management

Requires admin role.

### `GET /admin/stats`
Get global platform statistics.

### `GET /admin/audit/vendor-mutations`
Get filtered audit log rows for vendor staff and vendor preference mutation actions.

Implementation note:
- If `admin_logs` is unavailable in a deployment schema, the endpoint returns an empty paginated result (`logs: []`) instead of `500`.

### `GET /admin/charts`
Fetch analytical chart data.

### `GET /admin/finance/payouts/export`
Download payout summary as CSV.

### `GET /admin/vendors/pending`
List vendors awaiting approval.

### `PATCH /admin/vendors/:id/approve`
Approve a pending vendor account.

### `PATCH /admin/vendors/:id/reject`
Reject a pending vendor account.

### `POST /admin/vendors/approve-many`
Bulk approve multiple vendors in a single request.
- **Request Body**:
  ```json
  {
    "vendorIds": ["vendor-id-1", "vendor-id-2"]
  }
  ```
- **Response** `200 OK`:
  ```json
  {
    "successCount": 2,
    "errors": {}
  }
  ```

### `POST /admin/vendors/reject-many`
Bulk reject multiple vendors in a single request.
- **Request Body**:
  ```json
  {
    "vendorIds": ["vendor-id-1", "vendor-id-2"],
    "reason": "Compliance policy violation"
  }
  ```
- **Response** `200 OK`:
  ```json
  {
    "successCount": 2,
    "errors": {}
  }
  ```
- **Error Response** (partial failure) `200 OK`:
  ```json
  {
    "successCount": 1,
    "errors": {
      "vendor-id-2": "Vendor not found"
    }
  }
  ```

### `POST /admin/users/role`
Update a user's role (e.g., promote to admin).

### `POST /admin/users/block-many`
Bulk block or unblock users.
- **Request Body**:
  ```json
  {
    "userIds": ["user-id-1", "user-id-2"],
    "blocked": true,
    "reason": "Repeated abuse reports"
  }
  ```
- **Response** `200 OK`:
  ```json
  {
    "successCount": 2,
    "errors": {},
    "blocked": true
  }
  ```

### `POST /admin/users/role-many`
Bulk update user roles.
- **Request Body**:
  ```json
  {
    "userIds": ["user-id-1", "user-id-2"],
    "role": "vendor"
  }
  ```
- **Response** `200 OK`:
  ```json
  {
    "successCount": 2,
    "errors": {},
    "role": "vendor"
  }
  ```

### `POST /admin/vendors`
Directly create a vendor account.

---
*(Endpoints may require valid JWT in Authorization header)*

