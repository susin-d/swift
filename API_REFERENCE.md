# API Reference

This document outlines the core RESTful endpoints exposed by the Swift backend.

**Base URL**: `http://localhost:3000/api/v1`

## Contract Registry

Canonical source-of-truth endpoint for API request/response contracts consumed by backend, user_app, vendor_app, and admin_app.

### `GET /contracts/registry`
Returns versioned contract metadata for high-traffic endpoints and the shared error envelope.
- **Response** `200 OK`:
  ```json
  {
    "version": "2026.03.s8.3",
    "generatedAt": "2026-03-15T18:00:00.000Z",
    "totalEndpoints": 24,
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
    "version": "2026.03.s8.3",
    "count": 12,
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
    "version": "2026.03.s8.3",
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

### `GET /admin/users`
Returns paginated users and metadata.

### `GET /admin/audit`
Returns paginated admin audit logs and metadata. Each entry includes a `reason` field for sensitive actions.

### `GET /admin/vendors/pending`
Returns paginated pending vendors and metadata.


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
    "vendor_id": "uuid-string-here",
    "total_amount": 150.00,
    "items": [
      {
        "id": "menu-item-uuid",
        "quantity": 2,
        "price": 75.00
      }
    ]
  }
  ```
  Notes:
  - `items[]` accepts either legacy fields (`id`, `price`) or compatibility aliases (`menu_item_id`, `unit_price`).
- **Response** `201 Created`:
  ```json
  {
    "id": "uuid",
    "user_id": "uuid",
    "vendor_id": "uuid",
    "total_amount": 150.0,
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
       "vendors": { "name": "Canteen A" },
       "eta": {
         "min_minutes": 6,
         "max_minutes": 14,
         "confidence": "medium"
       }
    }
  ]
  ```

### `PATCH /orders/:id/status`
Update order status (Vendor only).
- **Headers**: `Authorization: Bearer <JWT>`
- **Request Body**:
  ```json
  { "status": "preparing" }
  ```

## Vendor Operations

Requires vendor role.

### `GET /vendor-ops/profile`
Fetch authenticated vendor's profile.

### `GET /vendor-ops/orders`
Fetch orders for the authenticated vendor.

- **Response** `200 OK`:
  ```json
  [
    {
      "id": "uuid",
      "status": "preparing",
      "total_amount": 220.0,
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
  - `GET|POST|DELETE|PATCH /addresses`
  - `POST /payments/create-order`
  - `POST /payments/verify`
  - `POST /reviews`
- Delivery write access now matches the documented operational scope: `POST /delivery/location` requires vendor/admin role, while `GET /delivery/:orderId/location` remains authenticated.
- The contracts feed reflects this as registry version `2026.03.s8.3`, changelog count `12`, and feature-flag count `11`.

## Admin Management

Requires admin role.

### `GET /admin/stats`
Get global platform statistics.

### `GET /admin/charts`
Fetch analytical chart data.

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

