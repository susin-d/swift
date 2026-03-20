# API Reference

This document outlines the core RESTful endpoints exposed by the Swift backend.

**Base URL (Production)**: `https://swift-campus.vercel.app/api/v1`

**Base URL (Local Development)**: `http://localhost:3000/api/v1`

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
    "version": "2026.03.s11.3",
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
    "version": "2026.03.s11.3",
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
    "version": "2026.03.s11.3",
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


## Sensitive Action Safeguards (Sprint 8.2)

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

Security hardening notes (Sprint 8):
- Blocked or actively banned accounts are denied with `403 Forbidden` on authenticated session flows.
- Malformed `Authorization` header values (non-bearer or empty bearer token) are rejected with `401 Unauthorized`.
- Dedicated admin and vendor surfaces reject restored or newly created sessions when the resolved role does not match the app.

### `POST /auth/session`
Login an existing user or vendor.
- **Request Body**:
  ```json
  {
    "email": "user@campus.edu",
    "password": "securepassword123"
  }
  ```
- **Response** `200 OK`:
  ```json
  {
    "user": {
      "id": "uuid",
      "email": "user@campus.edu",
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
    "email": "student@campus.edu",
    "password": "securepassword123",
    "name": "Jane Doe"
  }
  ```
- **Response** `201 Created`:
  ```json
  { "message": "Registration successful", "user": { "id": "uuid" } }
  ```
- **Error Responses**:
  - `400 ValidationError` when name/email/password are missing or password is shorter than 8 characters.
  - `409 Conflict` when the email is already registered.

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

### `GET /vendor-ops/stats`
Fetch vendor performance statistics.

## Menu Management

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
Initialize a Razorpay order.

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

## RBAC Parity Hardening (Sprint 8.3)

- Customer mutations now require a `user` role token and return `403 Forbidden` for vendor/admin principals:
  - `POST /orders`
  - `GET /orders/me`
  - `PATCH /orders/:id/cancel`
  - `GET|POST|DELETE|PATCH /addresses`
  - `POST /payments/create-order`
  - `POST /payments/verify`
  - `POST /reviews`
- Delivery write access now matches the documented operational scope: `POST /delivery/location` requires vendor/admin role, while `GET /delivery/:orderId/location` remains authenticated.
- The contracts feed reflects this as registry version `2026.03.s11.1`, changelog count `26`, and feature-flag count `11`.

## Admin Management

Requires admin role.

### `GET /admin/stats`
Get global platform statistics.

### `GET /admin/charts`
Fetch analytical chart data.

### `GET /admin/finance/payouts/export`
Download payout summary as CSV.

### `GET /admin/vendors/pending`
List vendors awaiting approval.

### `PATCH /admin/vendors/:id/approve`
Approve a pending vendor account.

### `POST /admin/users/role`
Update a user's role (e.g., promote to admin).

### `POST /admin/vendors`
Directly create a vendor account.

---
*(Endpoints may require valid JWT in Authorization header)*

