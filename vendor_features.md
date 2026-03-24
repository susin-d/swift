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

## ❌ Missing Features

- **Vendor Analytics Dashboard** - No revenue trends, item popularity metrics, peak hour analysis, completion time trends, or performance KPIs
- **Order History & Filtering** - No past order archive, only live orders visible; no advanced filtering (date range, customer, order value)
- **Customer Feedback View** - No access to customer reviews/ratings of vendor or menu items
- **Inventory Management** - No inventory tracking, stock levels, or low-stock alerts
- **Batch Menu Operations** - No bulk price updates, bulk availability toggles, or category-level operations
- **Account & Finance** - No account balance view, payout history, settlement records, or bank account management
- **Operational Hours Management** - No shift management, special hours scheduling, or holiday configurations
- **Campus Delivery Configuration** - No UI to assign vendor to delivery buildings/zones or set delivery availability by zone
- **Customer Communication** - No direct messaging, announcements, or broadcast capability beyond order status notifications
- **Handoff Documentation** - No photo/proof upload UI for class handoff validation (endpoint exists but app lacks capture UI)
- **Menu Image Uploads** - Menu items cannot have images uploaded directly; only external URLs supported
- **Compliance & Verification** - No vendor verification status, license documentation, or compliance checklist view

## 🚀 Suggested Enhancements

- **Add Analytics Screen** - Display 7-day revenue trend, top 5 items by orders, average completion time, peak hours heatmap, customer satisfaction rate; add endpoint `GET /vendor-ops/analytics` if missing
- **Create Order Archive Screen** - Full-text search, filter by status/date/customer/amount, bulk status export; enable filtering vendor orders via `GET /vendor-ops/orders?status=completed&since=2026-01-01`
- **Build Menu Performance Metrics** - Show item-level: order count, revenue contribution, avg rating, availability %; suggest items to remove or reprice based on 30-day performance
- **Implement Inventory Tracking** - Add stock quantity field to menu items, low-stock alerts (e.g., < 5 units), bulk restock UI; backend endpoint `PATCH /menus/items/:id` extended with `stock_quantity`
- **Add Shift/Hours Manager** - Set daily operating hours, block unavailable time slots, configure delivery zones by building; add endpoints `GET/POST /vendor-ops/shifts` and `GET/POST /vendor-ops/delivery-zones`
- **Create Payout Dashboard** - Display pending balance, completed settlements, payment history; add endpoints `GET /vendor-ops/payouts` and `GET /vendor-ops/payouts/:id`
- **Build Customer Feedback Hub** - Display vendor ratings, category breakdowns, recent reviews with customer names; add endpoint `GET /vendor-ops/reviews?limit=50&sort=recent`
- **Implement Photo Proof Capture** - Add camera/gallery picker for class handoff photo proof in `OrderDetailsSheet`; validate geolocation against delivery zone before submission
- **Add ETA Proactive Updates** - Allow vendor to manually update order ETA with reason; extend `PATCH /orders/:id/status` or create `PATCH /orders/:id/eta` with `new_eta_minutes` and `reason`
- **Bulk Menu Editor** - Modal for multi-item price changes, availability toggles by category; add endpoint `PATCH /menus/bulk` accepting array of item updates
- **Customer Chat UI** - Basic 1:1 messaging for order issues (replaces current notification-only model); requires new `POST /messages` and `GET /messages/:orderId` endpoints
- **Compliance Checklist** - Display vendor license status, health inspection dates, verification badges; add endpoint `GET /vendor-ops/compliance` returning status enum and document links

## ⚠️ Workflow Issues

- **Unclear Order Status Lifecycle** - No documented state machine showing valid transitions (e.g., can "hold" -> "preparing" or must restart?); recommend updating `API_REFERENCE.md` with status flow diagram
- **Delivery Handoff Proof Missing** - Endpoint `PATCH /orders/:id/handoff` accepts `proof_url` but app lacks photo capture UI; users must pre-upload proof elsewhere and paste URL
- **Location Tracking Accuracy** - 8-second timeout for GPS may timeout on poor signal; no retry logic or cached location fallback shown in dashboard
- **Pacing Recommendations Static** - Dashboard shows `recommended_prep_minutes` from API but no UI to override prep target per order or save as vendor preference
- **Menu Images URL-Only** - No image upload endpoint; vendors must host images externally (limits adoption for non-technical operators)
- **Live Order Queue Manual Refresh** - Dashboard displays orders but no polling interval visible; unclear if real-time or requires manual refresh between status checks
- **Category Closing Unavailable** - No way to mark category as temporarily unavailable during prep break; only per-item availability toggle exists
- **Audit Trail Missing** - No log of menu changes, order status edits, or profile updates visible to vendor; recommend `GET /vendor-ops/audit` endpoint

## 🔗 API Gaps

- **Missing Vendor Stats Endpoint Details** - `GET /vendor-ops/stats` exists in routes but API_REFERENCE.md only lists response as `{ total_orders, pending_orders, revenue }`; lacks `completed_orders`, `avg_completion_time`, `customer_rating`, `ytd_revenue`
- **No Vendor Reviews API** - No endpoint for vendor to fetch customer reviews; consider adding `GET /vendor-ops/reviews` with pagination
- **No Analytics Endpoint** - No `GET /vendor-ops/analytics` for time-series revenue, item popularity, peak hours; must be built
- **No Inventory API** - Menu items lack `stock_quantity`, `last_restocked`, `reorder_threshold` fields; requires schema migration and CRUD endpoints
- **No Shift/Hours Management API** - No endpoints for `POST /vendor-ops/shifts`, `PATCH /vendor-ops/shifts/:id`, `DELETE /vendor-ops/shifts/:id`
- **No Delivery Zone Assignment API** - Vendor cannot self-assign to buildings/zones; no `GET/POST /vendor-ops/delivery-zones` endpoints
- **No Bulk Menu Updates** - Cannot batch-update prices/availability; no `PATCH /menus/bulk` endpoint
- **No Payout/Settlement API** - No `GET /vendor-ops/payouts`, `GET /vendor-ops/payouts/:id`, or settlement history endpoints
- **No Compliance/Verification API** - No `GET /vendor-ops/compliance` showing license, health inspection, verification status
- **No ETA Update Endpoint** - Vendors cannot proactively update order ETA; `GET /vendor-ops/orders` returns server-calculated ETA only
- **No Customer Messaging API** - Only notifications (one-way); no `POST /messages`, `GET /messages/:orderId` for bidirectional communication
- **No Audit Log API** - No `GET /vendor-ops/audit` to show vendor action history (menu edits, status changes, profile updates)
- **Handoff Proof Pre-Upload Required** - `PATCH /orders/:id/handoff` expects `proof_url` but no dedicated image upload endpoint; likely requires integration with external storage
