# Developer & Contribution Guide

Welcome to the internal engineering guide for the Swift Platform.

## System Architecture Philosophy

This platform uses a **highly decoupled micro-architecture**.
- The **Backend** is entirely stateless. Sessions are managed via JWTs.
- The **Database** (Supabase) is the true source of truth and enforces security via PostgREST Row Level Security (RLS). Never trust the backend blindly; enforce rules at the database level!
- **Realtime** is handled by Supabase channels, not custom Socket.io servers. This drastically reduces the load on our Node servers.

## UI/UX Engineering Rules

When building components in React or Flutter, adhere to the **Teal Design System**:
- `Primary`: `#0D9488`
- `Accent`: `#CCFBF1`

1. **No custom CSS files**. Use Tailwind utility classes in React (`vendor-dashboard` and `admin-dashboard`).
2. **Component Reusability**. If a button or card design is used twice, extract it into `src/components/`.
3. Flutter widgets should strictly utilize the definitions declared in `/lib/theme/app_theme.dart`. Do not hardcode HEX colors in individual Flutter screens.

## Branching Strategy

We follow a simplified Git-Flow:
- `main`: Production-ready code. Commits here automatically deploy to Vercel/DigitalOcean.
- `staging`: Feature aggregation branch.
- `feature/*`: Your daily work branches (e.g., `feature/vendor-analytics-graphs`).

## Setting up Realtime Connections
When integrating Supabase Realtime in the frontend apps, remember to subscribe to the specific `order_id` or `vendor_id`:

```javascript
// React Example for Vendor Dashboard
supabase
  .channel('custom-filter-channel')
  .on(
    'postgres_changes',
    { event: 'INSERT', schema: 'public', table: 'orders', filter: `vendor_id=eq.${myVendorId}` },
    (payload) => {
      console.log('New order received!', payload)
      // trigger alert sound
    }
  )
  .subscribe()
```
