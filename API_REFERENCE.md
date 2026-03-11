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
    "user": {
      "id": "uuid",
      "email": "user@campus.edu",
      "role": "user"
    },
    "session": { "access_token": "...", "expires_in": 3600 }
  }
  ```

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
- **Response** `201 Created`:
  ```json
  {
    "id": "uuid",
    "user_id": "uuid",
    "vendor_id": "uuid",
    "total_amount": 150.0,
    "status": "pending"
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
       "vendors": { "name": "Canteen A" }
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

Protected by `authenticate` middleware.

### `POST /payments/create-order`
Initialize a Razorpay order.

### `POST /payments/verify`
Verify payment signature from Razorpay.

## Address Management

Protected by `authenticate` middleware.

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

### `POST /reviews` (Authenticated)
Submit a new review for an order.

## Delivery Tracking

Protected by `authenticate` middleware.

### `GET /delivery/:orderId/location`
Fetch the current location of a delivery.

### `POST /delivery/location` (Vendor/Admin)
Update the delivery location.

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
