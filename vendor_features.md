# Vendor App Features

## ✅ Existing Features

- **Dashboard Screen** - Real-time order queue with rush mode toggle, status filtering (all/accepted/preparing/ready/completed/hold), queue sorting (ready-first/newest/highest-value), prep time suggestions, live GPS location tracking for delivery orders, order details sheet, pacing visualization with SLA risk indicators
- **Menu Management Screen** - Create/edit/delete menu categories, add/edit/delete menu items, toggle item availability status, refresh UI with pull-to-refresh
- **Order Status Updates** - `PATCH /orders/:id/status` integration for vendors to mark orders as preparing/ready/completed
- **Class Delivery Handoff** - `PATCH /orders/:id/handoff` endpoint support for delivery-to-class scenarios with status tracking
- **Vendor Profile Screen** - Edit store name, description, image URL, toggle open/closed status
- **Notifications Screen** - View push notifications with metadata
- **Authentication** - Email/password login with session management
- **Delivery Location Tracking** - `POST /delivery/location` for real-time GPS updates during order delivery

