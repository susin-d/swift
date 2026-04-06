# Admin App Features (Current)

Canonical source: `PROJECT_DOCUMENTATION.md`

## Governance and Operations
- Dashboard summary and chart surfaces.
- Vendor moderation (single and bulk actions).
- User moderation and role controls (single and bulk actions).
- Order oversight and cancellation workflows.
- Audit log visibility.

## Finance and Contracts
- Finance summary and payout visibility.
- Promo CRUD connected to persisted backend entities.
- Contract registry/changelog/flags endpoints consumed for compatibility checks.

## Support Operations
- Support Inbox screen for ticket triage.
- Status actions (`in_progress`, `resolved`, `closed`).
- Support summary card and filter controls (status/priority).
- Admin support API integration via `/api/v1/admin/support/*`.

## Account Deletion Operations
- Admin endpoints to:
  - process due user deletion requests
  - list near-term deletion reminders
