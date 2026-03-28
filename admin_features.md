# Admin Panel Features

## ✅ Existing Features

- **Vendor Moderation**: Approve/reject pending vendors with required audit reasons (`GET /api/v1/admin/vendors/pending`, `PATCH /api/v1/admin/vendors/:id/approve`, `PATCH /api/v1/admin/vendors/:id/reject`)
- **Bulk Vendor Moderation**: Batch approve/reject selected vendors (`POST /api/v1/admin/vendors/approve-many`, `POST /api/v1/admin/vendors/reject-many`) with partial-failure reporting
- **Dashboard Snapshot**: Real-time system overview—total users, vendors, active orders, completed orders, total revenue, and pending vendor count
- **Revenue Analytics**: Daily, weekly, monthly, and total revenue breakdown with 7-day historical chart data
- **Order Management**: List all orders (filterable by status: pending/accepted/preparing/ready/completed/cancelled), view order details, cancel orders with reason requirement
- **User Management**: List all platform users with pagination, block/unblock users with audit justification, role assignment (user/vendor/admin)
- **Bulk User Moderation**: Batch block/unblock users and batch role updates (`POST /api/v1/admin/users/block-many`, `POST /api/v1/admin/users/role-many`) with per-entity error results
- **Finance/Payouts**: Aggregated revenue per vendor from completed orders, payout status tracking, CSV export capability for payouts
- **Campus Configuration**: Manage delivery buildings and geographic delivery zones with GeoJSON boundary support
- **Audit Logs**: Searchable activity log tracking admin actions (vendor status updates, order cancellations, user blocks, role changes) with admin identity, timestamp, and reason fields
- **System Settings**: Commission rate and delivery fee configuration (read/write endpoints present but limited field coverage)
- **Session Management**: Block/banned user detection at auth middleware level (`is_blocked`, `banned_until` fields enforced)
- **Critical Queue Metric**: Dashboard displays pending vendors + calculated portion of active orders as operational priority indicator

