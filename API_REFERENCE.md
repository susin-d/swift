# API Reference

This document outlines the core RESTful endpoints exposed by the Swift backend.

**Base URL**: `http://localhost:3000/api/v1`

## Authentication

All endpoints under `/auth` manage session handling.

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
    "token": "eyJhbG... (JWT)",
    "message": "Successfully logged in"
  }
  ```

## Order Management

Routes protected by the `authenticate` middleware.

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
        "item_id": "uuid-string",
        "quantity": 2,
        "special_instructions": "No onions please"
      }
    ]
  }
  ```
- **Response** `201 Created`:
  ```json
  {
    "message": "Order created",
    "orderId": "ord_1684343111"
  }
  ```

### `GET /orders`
Fetch orders for the authenticated user/vendor. Supabase RLS inherently filters this data.
- **Headers**: `Authorization: Bearer <JWT>`
- **Response** `200 OK`:
  ```json
  {
    "orders": [
      {
         "id": "uuid",
         "status": "preparing",
         "total_amount": 150.00
      }
    ]
  }
  ```

## Vendor Operations
Available to users holding the `<vendor>` role claim in their JWT.

### `PATCH /vendor-ops/orders/:id/status`
Update the preparation stage of an order (e.g. pending -> accepted -> preparing -> ready).
- **Headers**: `Authorization: Bearer <JWT>`
- **Request Body**:
  ```json
  {
    "status": "ready"
  }
  ```

*(Additional endpoints for menus and payments will follow this structure)*
