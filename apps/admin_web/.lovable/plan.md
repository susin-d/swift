
# Swift Admin Portal — Full Implementation Plan

## Overview
Build a complete admin web portal for the Swift food delivery platform with mock data, covering landing page, authentication, and a full-featured dashboard with moderation, order management, finance, and audit capabilities.

## Pages & Routes

### 1. Landing Page (`/`)
- Hero section with Swift branding and admin portal tagline
- Feature highlights (moderation, analytics, finance, real-time monitoring)
- CTA button to login

### 2. Login Page (`/login`)
- Email + password form with validation
- Mock auth (hardcoded admin credentials) stored in React context
- Redirect to dashboard after login

### 3. Protected Dashboard Layout (`/_authenticated`)
- Collapsible sidebar with navigation sections: Overview, Users, Vendors, Orders, Finance, Support, Audit Log, Settings
- Top header with admin name, notifications bell, and logout
- Breadcrumb navigation

### 4. Dashboard Overview (`/_authenticated/dashboard`)
- KPI cards: Total Users, Active Vendors, Orders Today, Revenue (MTD)
- Recent orders table (last 10)
- Quick action buttons (approve vendor, review flagged order)
- Mini charts for orders/revenue trends (using Recharts)

### 5. User Management (`/_authenticated/users`)
- Searchable, sortable table of all users
- Status badges (active, blocked, pending deletion)
- Actions: view profile, block/unblock (with reason dialog), delete
- User detail sheet/dialog with order history

### 6. Vendor Management (`/_authenticated/vendors`)
- Vendor list with approval status (pending, approved, rejected, suspended)
- Approve/reject actions with mandatory reason capture (min 10 chars)
- Vendor detail view: menu items, ratings, revenue, order stats
- Payout status indicators

### 7. Order Management (`/_authenticated/orders`)
- Filterable order table (status, date range, vendor, user)
- Order statuses: placed, preparing, out for delivery, delivered, cancelled, refunded
- Order detail view with timeline, items, payment info
- Actions: cancel order, process refund (with reason dialog)

### 8. Finance & Payouts (`/_authenticated/finance`)
- Revenue overview cards (total, vendor payouts, platform commission)
- Payout health table per vendor (pending, completed, failed)
- Top vendors by revenue chart
- Transaction ledger with filters
- Wallet balance overview

### 9. Support Tickets (`/_authenticated/support`)
- Ticket list with status (open, in-progress, resolved, closed)
- Assignment and triage actions
- Ticket detail with conversation thread

### 10. Audit Log (`/_authenticated/audit`)
- Chronological log of all admin actions
- Filters by action type, admin user, date range
- Each entry shows: timestamp, admin, action, target, reason

### 11. Settings (`/_authenticated/settings`)
- Platform configuration (delivery radius, commission rate, OTP TTL)
- Toggle feature flags
- Review before save pattern

## Shared Components
- **ReasonCaptureDialog** — enforces 10-char minimum justification for destructive actions
- **DataTable** — reusable table with search, sort, pagination, and filters
- **KPI Card** — stat card with icon, value, trend indicator
- **StatusBadge** — colored badges for various entity statuses
- **Charts** — line/bar charts using Recharts for trends

## Design Direction
- Clean white-mode interface with strong typographic hierarchy
- Sidebar navigation with icon + text, collapsible to icon-only
- Cards with subtle shadows and borders for content sections
- Consistent use of shadcn/ui components (Table, Dialog, Sheet, Badge, Tabs, etc.)

## Mock Data
- All data generated as TypeScript constants with realistic sample entries
- ~20 users, ~10 vendors, ~50 orders, ~30 audit entries, ~15 support tickets
- Simulated stats and trends

## Auth Flow
- React context-based auth with mock credentials
- Protected routes via `_authenticated` layout with `beforeLoad` redirect
- Session persisted in memory (resets on refresh)
