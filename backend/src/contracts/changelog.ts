export type ContractChangeType = 'added' | 'updated' | 'deprecated' | 'removed';

export type ContractChange = {
    id: string;
    version: string;
    timestamp: string;
    changeType: ContractChangeType;
    endpointId: string;
    summary: string;
    consumers: Array<'user_app' | 'vendor_app' | 'admin_app' | 'shared'>;
};

export const CONTRACT_CHANGELOG: ContractChange[] = [
    {
        id: 'chg-2026-03-15-12',
        version: '2026.03.s8.3',
        timestamp: '2026-03-15T21:00:00.000Z',
        changeType: 'updated',
        endpointId: 'orders.create',
        summary: 'RBAC parity hardening now scopes customer mutations (orders, addresses, payments, reviews) to user-role tokens only, requires vendor/admin role for delivery location updates, and rejects non-vendor sessions during vendor_app restore/login.',
        consumers: ['shared', 'user_app', 'vendor_app', 'admin_app']
    },
    {
        id: 'chg-2026-03-15-11',
        version: '2026.03.s8.2',
        timestamp: '2026-03-15T20:00:00.000Z',
        changeType: 'added',
        endpointId: 'admin.user.block',
        summary: 'Sensitive admin actions (block user, reject vendor, cancel order) now require an explicit reason that is recorded in the audit log. Audit log response includes new reason field. Three new endpoint contracts registered: admin.user.block, admin.vendor.reject, admin.order.cancel.',
        consumers: ['admin_app']
    },
    {
        id: 'chg-2026-03-15-10',
        version: '2026.03.s8.1',
        timestamp: '2026-03-15T18:00:00.000Z',
        changeType: 'updated',
        endpointId: 'auth.session.create',
        summary: 'Auth middleware now enforces blocked/banned account denial with 403 and supports request-trace observability headers for admin consumers.',
        consumers: ['shared', 'user_app', 'vendor_app', 'admin_app']
    },
    {
        id: 'chg-2026-03-15-09',
        version: '2026.03.s6.1',
        timestamp: '2026-03-15T15:00:00.000Z',
        changeType: 'updated',
        endpointId: 'vendor.orders.list',
        summary: 'Vendor order queue now includes pacing metadata (elapsed/target/recommended prep minutes plus sla_risk and pace_label).',
        consumers: ['shared', 'vendor_app']
    },
    {
        id: 'chg-2026-03-15-07',
        version: '2026.03.s5.1',
        timestamp: '2026-03-15T13:00:00.000Z',
        changeType: 'updated',
        endpointId: 'orders.create',
        summary: 'Order create response now includes ETA confidence envelope (eta.min_minutes/max_minutes/confidence).',
        consumers: ['shared', 'user_app', 'vendor_app', 'admin_app']
    },
    {
        id: 'chg-2026-03-15-08',
        version: '2026.03.s5.1',
        timestamp: '2026-03-15T13:10:00.000Z',
        changeType: 'updated',
        endpointId: 'orders.my.list',
        summary: 'User order listing now includes ETA confidence envelope for trust-surface rendering in clients.',
        consumers: ['shared', 'user_app']
    },
    {
        id: 'chg-2026-03-15-04',
        version: '2026.03.s4.1',
        timestamp: '2026-03-15T11:00:00.000Z',
        changeType: 'updated',
        endpointId: 'admin.orders.list',
        summary: 'Standardized pagination metadata (meta.page/limit/total/totalPages/hasNextPage/hasPreviousPage) in admin list responses.',
        consumers: ['shared', 'admin_app']
    },
    {
        id: 'chg-2026-03-15-05',
        version: '2026.03.s4.1',
        timestamp: '2026-03-15T11:10:00.000Z',
        changeType: 'added',
        endpointId: 'admin.vendors.pending.list',
        summary: 'Added pending vendors paginated response contract metadata.',
        consumers: ['shared', 'admin_app']
    },
    {
        id: 'chg-2026-03-15-06',
        version: '2026.03.s4.1',
        timestamp: '2026-03-15T11:20:00.000Z',
        changeType: 'updated',
        endpointId: 'contracts.flags.get',
        summary: 'Introduced retry/backoff, request-cancellation, and contracts-feed caching rollout flags for app consumers.',
        consumers: ['shared', 'user_app', 'vendor_app', 'admin_app']
    },
    {
        id: 'chg-2026-03-15-01',
        version: '2026.03.s3.2',
        timestamp: '2026-03-15T09:00:00.000Z',
        changeType: 'added',
        endpointId: 'contracts.flags.get',
        summary: 'Added contracts feature-flags endpoint for staged rollout control.',
        consumers: ['shared', 'user_app', 'vendor_app', 'admin_app']
    },
    {
        id: 'chg-2026-03-15-02',
        version: '2026.03.s3.2',
        timestamp: '2026-03-15T09:15:00.000Z',
        changeType: 'added',
        endpointId: 'contracts.changelog.get',
        summary: 'Added changelog feed endpoint for consumer-side compatibility checks.',
        consumers: ['shared', 'user_app', 'vendor_app', 'admin_app']
    },
    {
        id: 'chg-2026-03-15-03',
        version: '2026.03.s3.2',
        timestamp: '2026-03-15T09:30:00.000Z',
        changeType: 'updated',
        endpointId: 'error.envelope.standard',
        summary: 'Standardized error taxonomy mapping across 400/401/403/404/409/500 envelopes.',
        consumers: ['shared', 'user_app', 'vendor_app', 'admin_app']
    }
];
