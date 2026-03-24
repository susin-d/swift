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

## ❌ Missing Features

- **Promotion Management System**: Backend promo endpoints stubbed (GET/POST/PATCH `/api/v1/admin/promos`) with hardcoded empty responses; frontend UI exists but connects to non-functional backend
- **Request Rate Limiting**: No per-admin API rate limit enforcement; no quota management or throttling middleware
- **Admin Request Logging**: Endpoint call volume, response times, and error tracking not captured in database; only console error output
- **Health Monitoring Dashboard**: No backend uptime tracking, database health status, or service dependency monitoring
- **IP/Device Management**: No IP address logging on admin actions; no suspicious login detection or device trust tracking
- **Bulk Moderation Safety Controls**: No dry-run preview, approval-chain, or rollback workflow for high-impact bulk actions
- **Bulk User Moderation Audit Parity**: Batch user block/role operations currently return success/error results but do not persist per-user admin log entries at the same depth as single-entity moderation paths
- **Vendor SLA & Performance Tracking**: No prep time targets, delivery SLA compliance metrics, or vendor quality scoring
- **Payment & Refund Management**: Admin lacking capabilities to issue refunds, adjust order totals, or manage chargeback disputes
- **Data Retention & Compliance**: No configurable log retention policy; no GDPR-compliant data export or deletion workflows
- **Advanced Admin RBAC**: Only basic `admin` vs `super_admin` distinction; no granular permissions (e.g., vendor_moderator, finance_viewer, audit_reader)
- **Alert & Notification Rules**: No configurable thresholds (e.g., alert when pending vendors exceed N hours old) or escalation workflows
- **Scheduled Tasks**: No admin-triggered batch operations like weekly payout settlement or monthly reconciliation
- **Export Flexibility**: Only payout CSV available; no audit log export, order export, or user list export options
- **Activity Search & Analytics**: Audit logs filterable only by action type; no time range queries, target entity type queries, or impact analysis

## 🚀 Suggested Enhancements

- **API Rate Limiting & Quotas**: Implement per-admin request limits (e.g., 100 requests/min) with sliding window counters; expose quota headers in responses
- **Advanced Audit Context**: Expand audit log schema to include IP address, user agent, request ID correlation, and "before/after" state snapshots for sensitive updates
- **System Health Endpoint**: Expose `/api/v1/health/detailed` with Supabase connection status, auth service lag, request queue depth, and error rate percentile (p50/p95/p99) over 1h window
- **Vendor Scorecard**: Track and display prep time adherence, order accuracy (complaint rate), rating trend, and on-time delivery % per vendor
- **Batch Operations UI**: Allow multi-select vendors to bulk approve/reject, multi-select users to bulk block, or bulk update campus delivery zones
- **Admin Session Control**: Add endpoint to revoke active admin sessions, force re-authentication, and view login history with IP and device fingerprint
- **Financial Reconciliation Tools**: Admin dashboard showing settled payouts, pending payouts, disputed transactions, and ability to manually adjust vendor balances with audit trail
- **Configurable Alerts**: Rules engine allowing admins to define thresholds (e.g., "alert if any single order exceeds $X"), escalation recipients, and notification channels (email, in-app)
- **Data Export Compliance**: Unified export interface for audit logs, orders, users, and financials with date range and field selection; async generation for large datasets
- **Performance Dashboards**: Real-time metric visualizations—request latency heatmap, order lifecycle duration distribution, vendor queue aging, error rate by endpoint
- **Scheduled Task Management**: UI to configure daily payout settlement, weekly vendor compliance reports, monthly financial audits with execution logs and result summaries

## ⚠️ System Risks

- **No Request Rate Limiting**: Malicious admin or compromised token can flood API; no protection against enumeration or brute-force attacks on admin endpoints
- **Incomplete Audit Coverage**: Admin actions (vendor approval, user block) lack IP address and device context; cannot definitively correlate suspicious activity patterns
- **Unfinished Promo Feature Exposure**: Backend promo endpoints return empty stubs; clients may fail silently or cache stale responses; creates confusion about feature readiness
- **Limited Role Granularity**: All authenticated admins can invoke any admin endpoint (except settings, locked to `super_admin`); no department-level access control (e.g., finance-only, moderation-only)
- **Session Expiry Not Enforced in Admin**: Auth middleware validates token liveness but no admin-specific session timeout or re-authentication for sensitive operations
- **Bulk Moderation Without Preview**: Single-action UI prevents mass mistakes, but no scheduled/deferred action queue; admin errors (reject wrong vendor) cannot be queued for review
- **Database Query Scaling Risk**: Audit log queries load full result set then paginate in memory (potential memory spike); no query indexes noted for `admin_logs.created_at` or `.admin_id`
- **Analytics Blind Spot**: No monitoring of admin action error rates; failed vendor rejections, failed user blocks logged only to console, not persisted for audit
- **Bulk Action Traceability Gap**: Bulk user role/block operations need structured per-user audit inserts (actor, before/after, reason, request-id) to support forensic review and compliance audits
- **No Fraud Detection Signals**: Admin can block any user without restriction; no cross-check against transaction history, no hold-for-review pattern on bulk actions
- **Payout Export Data Integrity**: CSV export endpoint returns data snapshot without hash or signature; no detection of offline tampering; no audit trail of who exported and when
- **Settings Update Persistence Question**: `updateAdminSettings` endpoint enforces `super_admin` role but confirms receipt with request body echo, not persisted values; actual persistence logic unclear

## 🔗 Backend Gaps

- **Promo Workflow Incomplete**: Routes registered (`/api/v1/admin/promos` GET/POST/PATCH) return hardcoded stubs; no database integration, validation, or lifecycle enforcement
- **Audit Log Insertion Logic Fragmented**: Some admin actions logged in `adminController.ts` (vendor approval via legacy admin.controller), others not logged at all; inconsistent field mapping (`action_performed` vs `action`, missing `entity_id` mapping)
- **Settings Persistence Undefined**: `getAdminSettings` returns hardcoded values (commission_rate: 10, delivery_fee: 20); `updateAdminSettings` accepts body but no SQL UPDATE statement; client cannot actually persist configuration changes
- **Missing Admin Activity Alerting**: No background job or trigger to notify super_admin of bulk moderation, high-frequency actions, or policy violations (e.g., 10+ user blocks in 5 minutes)
- **Vendor Compliance Tracking Absent**: No SLA table or metric calculation; finance payouts aggregated on-demand without tracking prep KPIs, cancellation rates, or refund disputes per vendor
- **Order Cancellation Reason Not Linked to Vendor**: Cancel audit log stores reason but no notification sent to affected vendor; vendor cannot respond or appeal; no dispute workflow
- **Finance Export No Filtering**: Payout CSV export returns all completed orders globally; no date range filter, no per-vendor filter; large systems will generate massive exports
- **No Request Tracing**: Global error handler logs errors to console with `[API Error]` prefix but no correlation ID propagation; difficult to link admin UI error to backend log entry
- **Deleted Entities Not Soft-Deleted**: No `deleted_at` timestamp in schema; if admin or user records deleted, audit trail references become orphaned; no trash/recovery feature
- **Health Endpoint Minimal**: `/health` returns only `{ status: 'ok', timestamp }` without dependency checks (Supabase auth, database, external services); no practical diagnostic value for on-call admin
