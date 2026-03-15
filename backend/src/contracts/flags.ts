export type ContractFeatureFlag = {
    key: string;
    enabled: boolean;
    description: string;
    rollout: 'global' | 'staged';
    consumers: Array<'user_app' | 'vendor_app' | 'admin_app' | 'shared'>;
};

export const CONTRACT_FEATURE_FLAGS: ContractFeatureFlag[] = [
    {
        key: 'security.blocked_session_enforcement.v1',
        enabled: true,
        description: 'Enforces blocked/banned account denial at auth middleware and propagates request-trace metadata for admin observability.',
        rollout: 'global',
        consumers: ['shared', 'user_app', 'vendor_app', 'admin_app']
    },
    {
        key: 'security.role_scope_enforcement.v1',
        enabled: true,
        description: 'Enforces dedicated role scopes for customer mutations, vendor operational updates, and vendor_app session restoration/login flows.',
        rollout: 'global',
        consumers: ['shared', 'user_app', 'vendor_app', 'admin_app']
    },
    {
        key: 'security.sensitive_action_reason.v1',
        enabled: true,
        description: 'Requires admin operators to provide an explicit reason for sensitive actions (block user, reject vendor, cancel order) before they are executed and recorded in the audit log.',
        rollout: 'global',
        consumers: ['admin_app']
    },
    {
        key: 'vendor.pacing_assist.v1',
        enabled: true,
        description: 'Enables pacing metadata on vendor order queue responses for prep-time assist and SLA risk surfaces.',
        rollout: 'global',
        consumers: ['shared', 'vendor_app']
    },
    {
        key: 'orders.eta_confidence.v1',
        enabled: true,
        description: 'Enables ETA confidence envelope on order create/list responses for checkout and tracking trust surfaces.',
        rollout: 'global',
        consumers: ['shared', 'user_app', 'vendor_app', 'admin_app']
    },
    {
        key: 'reliability.retry_backoff.v1',
        enabled: true,
        description: 'Enables bounded retry with incremental backoff for retryable API failures in app consumers.',
        rollout: 'global',
        consumers: ['user_app', 'vendor_app', 'admin_app']
    },
    {
        key: 'reliability.request_cancellation.v1',
        enabled: true,
        description: 'Enables in-flight request cancellation and GET dedupe for superseded client requests.',
        rollout: 'global',
        consumers: ['user_app', 'vendor_app', 'admin_app']
    },
    {
        key: 'contracts.feed_cache.v1',
        enabled: true,
        description: 'Enables short-lived contracts feed caching for registry/changelog/flags reads.',
        rollout: 'staged',
        consumers: ['user_app', 'vendor_app', 'admin_app']
    },
    {
        key: 'contracts.registry.expanded',
        enabled: true,
        description: 'Enables expanded endpoint coverage in contracts registry feed.',
        rollout: 'global',
        consumers: ['shared', 'user_app', 'vendor_app', 'admin_app']
    },
    {
        key: 'contracts.error_taxonomy.v2',
        enabled: true,
        description: 'Enforces standardized error taxonomy envelope in API responses.',
        rollout: 'global',
        consumers: ['shared', 'user_app', 'vendor_app', 'admin_app']
    },
    {
        key: 'contracts.consumer.assertions',
        enabled: true,
        description: 'Allows consumers to execute strict DTO assertions using registry metadata.',
        rollout: 'staged',
        consumers: ['user_app', 'vendor_app', 'admin_app']
    }
];
