export type ContractSchemaField = {
    name: string;
    type: string;
    required: boolean;
    description: string;
};

export type ContractSchema = {
    description: string;
    fields: ContractSchemaField[];
};

export type ContractEndpoint = {
    id: string;
    method: 'GET' | 'POST' | 'PATCH' | 'DELETE';
    path: string;
    owner: 'backend' | 'user_app' | 'vendor_app' | 'admin_app' | 'shared';
    auth: 'public' | 'authenticated' | 'user' | 'admin' | 'vendor';
    request?: ContractSchema;
    response: ContractSchema;
};

export const CONTRACT_REGISTRY_VERSION = '2026.03.s11.2';

export const CONTRACT_ENDPOINTS: ContractEndpoint[] = [
    {
        id: 'auth.session.create',
        method: 'POST',
        path: '/api/v1/auth/session',
        owner: 'shared',
        auth: 'public',
        request: {
            description: 'Authenticate a user and create a session token payload.',
            fields: [
                { name: 'email', type: 'string', required: true, description: 'User email address.' },
                { name: 'password', type: 'string', required: true, description: 'User password.' }
            ]
        },
        response: {
            description: 'Authenticated user details and session object. Blocked or banned accounts are denied with 403 Forbidden.',
            fields: [
                { name: 'user.id', type: 'string(uuid)', required: true, description: 'Primary user identifier.' },
                { name: 'user.email', type: 'string', required: true, description: 'Authenticated email.' },
                { name: 'user.role', type: 'string', required: true, description: 'Resolved role from users table.' },
                { name: 'session.access_token', type: 'string', required: true, description: 'Supabase JWT token.' },
                { name: 'session.expires_in', type: 'number', required: true, description: 'Token expiration in seconds.' }
            ]
        }
    },
    {
        id: 'auth.me.get',
        method: 'GET',
        path: '/api/v1/auth/me',
        owner: 'shared',
        auth: 'authenticated',
        response: {
            description: 'Current user profile with role-aware profile payload. Blocked or banned accounts are denied with 403 Forbidden.',
            fields: [
                { name: 'user.id', type: 'string(uuid)', required: true, description: 'Primary user identifier.' },
                { name: 'user.email', type: 'string', required: false, description: 'Account email if present.' },
                { name: 'user.role', type: 'string', required: true, description: 'Resolved role.' },
                { name: 'user.profile', type: 'object', required: true, description: 'Role specific profile object.' }
            ]
        }
    },
    {
        id: 'orders.create',
        method: 'POST',
        path: '/api/v1/orders',
        owner: 'shared',
        auth: 'user',
        request: {
            description: 'Create an order with one or more line items.',
            fields: [
                { name: 'vendor_id', type: 'string(uuid)', required: true, description: 'Vendor receiving the order.' },
                { name: 'total_amount', type: 'number', required: true, description: 'Aggregate payable total.' },
                { name: 'promo_code', type: 'string', required: false, description: 'Optional promo code to apply.' },
                { name: 'scheduled_for', type: 'string(datetime)', required: false, description: 'Optional scheduled fulfillment timestamp.' },
                { name: 'delivery_mode', type: 'string', required: false, description: 'Delivery mode: standard|class.' },
                { name: 'delivery_building_id', type: 'string(uuid)', required: false, description: 'Campus building id for class delivery.' },
                { name: 'delivery_room', type: 'string', required: false, description: 'Room or classroom label.' },
                { name: 'delivery_zone_id', type: 'string(uuid)', required: false, description: 'Delivery zone id when provided.' },
                { name: 'quiet_mode', type: 'boolean', required: false, description: 'Quiet delivery preferences (no calls).'} ,
                { name: 'delivery_instructions', type: 'string', required: false, description: 'Delivery instructions for class handoff.' },
                { name: 'delivery_location_label', type: 'string', required: false, description: 'Delivery location label.' },
                { name: 'class_start_at', type: 'string(datetime)', required: false, description: 'Class start timestamp.' },
                { name: 'class_end_at', type: 'string(datetime)', required: false, description: 'Class end timestamp.' },
                { name: 'items', type: 'array<object>', required: true, description: 'Order line items with id/menu_item_id, quantity, and price/unit_price.' }
            ]
        },
        response: {
            description: 'Created order summary.',
            fields: [
                { name: 'id', type: 'string(uuid)', required: true, description: 'Order identifier.' },
                { name: 'user_id', type: 'string(uuid)', required: true, description: 'Customer ID.' },
                { name: 'vendor_id', type: 'string(uuid)', required: true, description: 'Vendor ID.' },
                { name: 'status', type: 'string', required: true, description: 'Order lifecycle status.' },
                { name: 'discount_amount', type: 'number', required: false, description: 'Applied promo discount amount.' },
                { name: 'promo_code', type: 'string', required: false, description: 'Applied promo code.' },
                { name: 'scheduled_for', type: 'string(datetime)', required: false, description: 'Scheduled fulfillment time.' },
                { name: 'delivery_mode', type: 'string', required: false, description: 'Delivery mode: standard|class.' },
                { name: 'delivery_building_id', type: 'string(uuid)', required: false, description: 'Campus building id for class delivery.' },
                { name: 'delivery_room', type: 'string', required: false, description: 'Room or classroom label.' },
                { name: 'delivery_zone_id', type: 'string(uuid)', required: false, description: 'Delivery zone id when provided.' },
                { name: 'quiet_mode', type: 'boolean', required: false, description: 'Quiet delivery preferences (no calls).'} ,
                { name: 'delivery_instructions', type: 'string', required: false, description: 'Delivery instructions for class handoff.' },
                { name: 'delivery_location_label', type: 'string', required: false, description: 'Delivery location label.' },
                { name: 'handoff_code', type: 'string', required: false, description: 'Generated handoff code for class delivery.' },
                { name: 'handoff_status', type: 'string', required: false, description: 'Handoff status state.' },
                { name: 'handoff_proof_url', type: 'string', required: false, description: 'Proof of delivery URL.' },
                { name: 'class_start_at', type: 'string(datetime)', required: false, description: 'Class start timestamp.' },
                { name: 'class_end_at', type: 'string(datetime)', required: false, description: 'Class end timestamp.' },
                { name: 'eta.min_minutes', type: 'number', required: true, description: 'Estimated lower-bound arrival/prep minutes remaining.' },
                { name: 'eta.max_minutes', type: 'number', required: true, description: 'Estimated upper-bound arrival/prep minutes remaining.' },
                { name: 'eta.confidence', type: 'string', required: true, description: 'Confidence grade: low|medium|high.' }
            ]
        }
    },
    {
        id: 'vendor.orders.list',
        method: 'GET',
        path: '/api/v1/vendor-ops/orders',
        owner: 'vendor_app',
        auth: 'vendor',
        response: {
            description: 'Vendor order queue with customer and item summary fields.',
            fields: [
                { name: '[].id', type: 'string(uuid)', required: true, description: 'Order identifier.' },
                { name: '[].status', type: 'string', required: true, description: 'Current order status.' },
                { name: '[].total_amount', type: 'number', required: true, description: 'Order total.' },
                { name: '[].discount_amount', type: 'number', required: false, description: 'Applied promo discount.' },
                { name: '[].promo_code', type: 'string', required: false, description: 'Applied promo code.' },
                { name: '[].scheduled_for', type: 'string(datetime)', required: false, description: 'Scheduled fulfillment time.' },
                { name: '[].delivery_mode', type: 'string', required: false, description: 'Delivery mode: standard|class.' },
                { name: '[].delivery_building_id', type: 'string(uuid)', required: false, description: 'Campus building id for class delivery.' },
                { name: '[].delivery_room', type: 'string', required: false, description: 'Room or classroom label.' },
                { name: '[].delivery_zone_id', type: 'string(uuid)', required: false, description: 'Delivery zone id when provided.' },
                { name: '[].quiet_mode', type: 'boolean', required: false, description: 'Quiet delivery preferences (no calls).'} ,
                { name: '[].delivery_instructions', type: 'string', required: false, description: 'Delivery instructions for class handoff.' },
                { name: '[].delivery_location_label', type: 'string', required: false, description: 'Delivery location label.' },
                { name: '[].handoff_code', type: 'string', required: false, description: 'Handoff code for class delivery.' },
                { name: '[].handoff_status', type: 'string', required: false, description: 'Handoff status state.' },
                { name: '[].handoff_proof_url', type: 'string', required: false, description: 'Proof of delivery URL.' },
                { name: '[].class_start_at', type: 'string(datetime)', required: false, description: 'Class start timestamp.' },
                { name: '[].class_end_at', type: 'string(datetime)', required: false, description: 'Class end timestamp.' },
                { name: '[].eta.min_minutes', type: 'number', required: true, description: 'Estimated lower-bound prep/delivery minutes remaining.' },
                { name: '[].eta.max_minutes', type: 'number', required: true, description: 'Estimated upper-bound prep/delivery minutes remaining.' },
                { name: '[].pacing.elapsed_minutes', type: 'number', required: true, description: 'Elapsed time since order creation in minutes.' },
                { name: '[].pacing.target_prep_minutes', type: 'number', required: true, description: 'Current prep target for this order.' },
                { name: '[].pacing.recommended_prep_minutes', type: 'number', required: true, description: 'Suggested prep duration based on order size and value.' },
                { name: '[].pacing.sla_risk', type: 'string', required: true, description: 'Pacing risk grade: low|medium|high.' },
                { name: '[].pacing.pace_label', type: 'string', required: true, description: 'Readable pacing label such as on_track/watch/urgent.' },
                { name: '[].items', type: 'array<object>', required: false, description: 'Line items when requested.' }
            ]
        }
    },
    {
        id: 'admin.stats.get',
        method: 'GET',
        path: '/api/v1/admin/stats',
        owner: 'admin_app',
        auth: 'admin',
        response: {
            description: 'Platform-level summary metrics used by admin dashboard widgets.',
            fields: [
                { name: 'users', type: 'number', required: true, description: 'Total customer count.' },
                { name: 'vendors', type: 'number', required: true, description: 'Total vendors count.' },
                { name: 'orders', type: 'number', required: true, description: 'Total orders count.' },
                { name: 'revenue', type: 'number', required: true, description: 'Total processed revenue.' }
            ]
        }
    },
    {
        id: 'auth.register.create',
        method: 'POST',
        path: '/api/v1/auth/register',
        owner: 'user_app',
        auth: 'public',
        request: {
            description: 'Register a new user account.',
            fields: [
                { name: 'email', type: 'string', required: true, description: 'User email address.' },
                { name: 'password', type: 'string', required: true, description: 'Account password.' },
                { name: 'name', type: 'string', required: true, description: 'Display name.' }
            ]
        },
        response: {
            description: 'Registration acknowledgement and user payload.',
            fields: [
                { name: 'message', type: 'string', required: true, description: 'Registration status.' },
                { name: 'user.id', type: 'string(uuid)', required: true, description: 'Registered user id.' }
            ]
        }
    },
    {
        id: 'orders.my.list',
        method: 'GET',
        path: '/api/v1/orders/me',
        owner: 'user_app',
        auth: 'user',
        response: {
            description: 'List orders for the current authenticated customer user.',
            fields: [
                { name: '[].id', type: 'string(uuid)', required: true, description: 'Order id.' },
                { name: '[].status', type: 'string', required: true, description: 'Order status.' },
                { name: '[].total_amount', type: 'number', required: true, description: 'Order total.' },
                { name: '[].discount_amount', type: 'number', required: false, description: 'Applied promo discount.' },
                { name: '[].promo_code', type: 'string', required: false, description: 'Applied promo code.' },
                { name: '[].scheduled_for', type: 'string(datetime)', required: false, description: 'Scheduled fulfillment time.' },
                { name: '[].delivery_mode', type: 'string', required: false, description: 'Delivery mode: standard|class.' },
                { name: '[].delivery_building_id', type: 'string(uuid)', required: false, description: 'Campus building id for class delivery.' },
                { name: '[].delivery_room', type: 'string', required: false, description: 'Room or classroom label.' },
                { name: '[].delivery_zone_id', type: 'string(uuid)', required: false, description: 'Delivery zone id when provided.' },
                { name: '[].quiet_mode', type: 'boolean', required: false, description: 'Quiet delivery preferences (no calls).'} ,
                { name: '[].delivery_instructions', type: 'string', required: false, description: 'Delivery instructions for class handoff.' },
                { name: '[].delivery_location_label', type: 'string', required: false, description: 'Delivery location label.' },
                { name: '[].handoff_code', type: 'string', required: false, description: 'Handoff code for class delivery.' },
                { name: '[].handoff_status', type: 'string', required: false, description: 'Handoff status state.' },
                { name: '[].handoff_proof_url', type: 'string', required: false, description: 'Proof of delivery URL.' },
                { name: '[].class_start_at', type: 'string(datetime)', required: false, description: 'Class start timestamp.' },
                { name: '[].class_end_at', type: 'string(datetime)', required: false, description: 'Class end timestamp.' },
                { name: '[].eta.min_minutes', type: 'number', required: true, description: 'Estimated lower-bound minutes remaining.' },
                { name: '[].eta.max_minutes', type: 'number', required: true, description: 'Estimated upper-bound minutes remaining.' },
                { name: '[].eta.confidence', type: 'string', required: true, description: 'Confidence grade for ETA estimate.' }
            ]
        }
    },
    {
        id: 'orders.cancel',
        method: 'PATCH',
        path: '/api/v1/orders/:id/cancel',
        owner: 'user_app',
        auth: 'user',
        response: {
            description: 'Cancel an order before preparation begins.',
            fields: [
                { name: 'id', type: 'string(uuid)', required: true, description: 'Order id.' },
                { name: 'status', type: 'string', required: true, description: 'Updated status (cancelled).' },
                { name: 'eta.min_minutes', type: 'number', required: true, description: 'Lower-bound minutes remaining.' },
                { name: 'eta.max_minutes', type: 'number', required: true, description: 'Upper-bound minutes remaining.' },
                { name: 'eta.confidence', type: 'string', required: true, description: 'Confidence grade for ETA estimate.' }
            ]
        }
    },
    {
        id: 'menus.vendor.list',
        method: 'GET',
        path: '/api/v1/menus/vendor/:vendorId',
        owner: 'shared',
        auth: 'public',
        response: {
            description: 'Vendor menu categories and nested menu items.',
            fields: [
                { name: '[].id', type: 'string(uuid)', required: true, description: 'Menu category id.' },
                { name: '[].category_name', type: 'string', required: true, description: 'Category name.' },
                { name: '[].menu_items', type: 'array<object>', required: true, description: 'Items under category.' }
            ]
        }
    },
    {
        id: 'public.vendors.list',
        method: 'GET',
        path: '/api/v1/public/vendors',
        owner: 'user_app',
        auth: 'public',
        response: {
            description: 'List publicly visible vendors.',
            fields: [
                { name: '[].id', type: 'string(uuid)', required: true, description: 'Vendor id.' },
                { name: '[].name', type: 'string', required: true, description: 'Vendor display name.' },
                { name: '[].is_open', type: 'boolean', required: false, description: 'Current open status.' }
            ]
        }
    },
    {
        id: 'public.search.global',
        method: 'GET',
        path: '/api/v1/public/search',
        owner: 'user_app',
        auth: 'public',
        response: {
            description: 'Global search payload across menus and vendors.',
            fields: [
                { name: '[].id', type: 'string(uuid)', required: true, description: 'Menu item id.' },
                { name: '[].name', type: 'string', required: true, description: 'Menu item name.' },
                { name: '[].description', type: 'string', required: false, description: 'Menu item description.' },
                { name: '[].price', type: 'number', required: true, description: 'Menu item price.' },
                { name: '[].vendor.id', type: 'string(uuid)', required: false, description: 'Vendor id.' },
                { name: '[].vendor.name', type: 'string', required: false, description: 'Vendor name.' }
            ]
        }
    },
    {
        id: 'vendor.profile.get',
        method: 'GET',
        path: '/api/v1/vendor-ops/profile',
        owner: 'vendor_app',
        auth: 'vendor',
        response: {
            description: 'Current vendor profile payload.',
            fields: [
                { name: 'id', type: 'string(uuid)', required: true, description: 'Vendor id.' },
                { name: 'name', type: 'string', required: true, description: 'Vendor name.' },
                { name: 'owner_id', type: 'string(uuid)', required: true, description: 'Owner id.' }
            ]
        }
    },
    {
        id: 'vendor.stats.get',
        method: 'GET',
        path: '/api/v1/vendor-ops/stats',
        owner: 'vendor_app',
        auth: 'vendor',
        response: {
            description: 'Vendor dashboard metrics payload.',
            fields: [
                { name: 'total_orders', type: 'number', required: true, description: 'Total orders count.' },
                { name: 'pending_orders', type: 'number', required: true, description: 'Pending orders count.' },
                { name: 'revenue', type: 'number', required: true, description: 'Revenue sum.' }
            ]
        }
    },
    {
        id: 'addresses.list',
        method: 'GET',
        path: '/api/v1/addresses',
        owner: 'user_app',
        auth: 'user',
        response: {
            description: 'Customer saved addresses list.',
            fields: [
                { name: '[].id', type: 'string(uuid)', required: true, description: 'Address id.' },
                { name: '[].label', type: 'string', required: true, description: 'Address label.' },
                { name: '[].address_line', type: 'string', required: true, description: 'Address body.' }
            ]
        }
    },
    {
        id: 'payments.create_order',
        method: 'POST',
        path: '/api/v1/payments/create-order',
        owner: 'user_app',
        auth: 'user',
        request: {
            description: 'Create Razorpay order request.',
            fields: [
                { name: 'amount', type: 'number', required: true, description: 'Amount in paise.' }
            ]
        },
        response: {
            description: 'Payment order payload.',
            fields: [
                { name: 'id', type: 'string', required: true, description: 'Razorpay order id.' },
                { name: 'amount', type: 'number', required: true, description: 'Order amount.' }
            ]
        }
    },
    {
        id: 'admin.order.cancel',
        method: 'PATCH',
        path: '/api/v1/admin/orders/:id/cancel',
        owner: 'admin_app',
        auth: 'admin',
        request: {
            description: 'Cancel an order on behalf of the platform. A reason is required and recorded in the audit log.',
            fields: [
                { name: 'reason', type: 'string', required: true, description: 'Justification for the cancellation (min 10 characters).' }
            ]
        },
        response: {
            description: 'Cancellation confirmation message.',
            fields: [
                { name: 'message', type: 'string', required: true, description: 'Success message.' }
            ]
        }
    },
    {
        id: 'admin.finance.payouts.export',
        method: 'GET',
        path: '/api/v1/admin/finance/payouts/export',
        owner: 'admin_app',
        auth: 'admin',
        response: {
            description: 'CSV export payload for vendor payouts.',
            fields: [
                { name: 'csv', type: 'string', required: true, description: 'CSV text body.' }
            ]
        }
    },
    {
        id: 'admin.orders.list',
        method: 'GET',
        path: '/api/v1/admin/orders',
        owner: 'admin_app',
        auth: 'admin',
        response: {
            description: 'Admin paginated order listing.',
            fields: [
                { name: 'orders', type: 'array<object>', required: true, description: 'Order collection.' },
                { name: 'page', type: 'number', required: true, description: 'Page number.' },
                { name: 'limit', type: 'number', required: true, description: 'Page size used for query.' },
                { name: 'total', type: 'number', required: true, description: 'Total records.' },
                { name: 'meta.page', type: 'number', required: true, description: 'Current page number.' },
                { name: 'meta.limit', type: 'number', required: true, description: 'Current page size.' },
                { name: 'meta.total', type: 'number', required: true, description: 'Total matching records.' },
                { name: 'meta.totalPages', type: 'number', required: true, description: 'Total page count.' },
                { name: 'meta.hasNextPage', type: 'boolean', required: true, description: 'Whether next page exists.' },
                { name: 'meta.hasPreviousPage', type: 'boolean', required: true, description: 'Whether previous page exists.' }
            ]
        }
    },
    {
        id: 'admin.vendor.reject',
        method: 'PATCH',
        path: '/api/v1/admin/vendors/:id/reject',
        owner: 'admin_app',
        auth: 'admin',
        request: {
            description: 'Reject a pending vendor application. A reason is required and recorded in the audit log.',
            fields: [
                { name: 'reason', type: 'string', required: true, description: 'Justification for the rejection (min 10 characters).' }
            ]
        },
        response: {
            description: 'Rejection confirmation message.',
            fields: [
                { name: 'message', type: 'string', required: true, description: 'Success message.' }
            ]
        }
    },
    {
        id: 'admin.vendors.pending.list',
        method: 'GET',
        path: '/api/v1/admin/vendors/pending',
        owner: 'admin_app',
        auth: 'admin',
        response: {
            description: 'Admin paginated pending vendor approvals list.',
            fields: [
                { name: 'vendors', type: 'array<object>', required: true, description: 'Pending vendors collection.' },
                { name: 'page', type: 'number', required: true, description: 'Page number.' },
                { name: 'limit', type: 'number', required: true, description: 'Page size used for query.' },
                { name: 'total', type: 'number', required: true, description: 'Total records.' },
                { name: 'meta.page', type: 'number', required: true, description: 'Current page number.' },
                { name: 'meta.limit', type: 'number', required: true, description: 'Current page size.' },
                { name: 'meta.total', type: 'number', required: true, description: 'Total matching records.' },
                { name: 'meta.totalPages', type: 'number', required: true, description: 'Total page count.' },
                { name: 'meta.hasNextPage', type: 'boolean', required: true, description: 'Whether next page exists.' },
                { name: 'meta.hasPreviousPage', type: 'boolean', required: true, description: 'Whether previous page exists.' }
            ]
        }
    },
    {
        id: 'admin.user.block',
        method: 'PATCH',
        path: '/api/v1/admin/users/:id/block',
        owner: 'admin_app',
        auth: 'admin',
        request: {
            description: 'Block or unblock a user account. When blocking, a reason is required and recorded in the audit log.',
            fields: [
                { name: 'blocked', type: 'boolean', required: true, description: 'True to block, false to unblock.' },
                { name: 'reason', type: 'string', required: false, description: 'Required when blocked=true. Justification for the block (min 10 characters).' }
            ]
        },
        response: {
            description: 'Block status confirmation message.',
            fields: [
                { name: 'message', type: 'string', required: true, description: 'Success message.' }
            ]
        }
    },
    {
        id: 'admin.users.list',
        method: 'GET',
        path: '/api/v1/admin/users',
        owner: 'admin_app',
        auth: 'admin',
        response: {
            description: 'Admin paginated user listing.',
            fields: [
                { name: 'users', type: 'array<object>', required: true, description: 'Users collection.' },
                { name: 'page', type: 'number', required: true, description: 'Page number.' },
                { name: 'limit', type: 'number', required: true, description: 'Page size used for query.' },
                { name: 'total', type: 'number', required: true, description: 'Total records.' },
                { name: 'meta.page', type: 'number', required: true, description: 'Current page number.' },
                { name: 'meta.limit', type: 'number', required: true, description: 'Current page size.' },
                { name: 'meta.total', type: 'number', required: true, description: 'Total matching records.' },
                { name: 'meta.totalPages', type: 'number', required: true, description: 'Total page count.' },
                { name: 'meta.hasNextPage', type: 'boolean', required: true, description: 'Whether next page exists.' },
                { name: 'meta.hasPreviousPage', type: 'boolean', required: true, description: 'Whether previous page exists.' }
            ]
        }
    },
    {
        id: 'admin.audit.list',
        method: 'GET',
        path: '/api/v1/admin/audit',
        owner: 'admin_app',
        auth: 'admin',
        response: {
            description: 'Admin audit log feed. Each entry now includes a reason field for sensitive actions.',
            fields: [
                { name: 'logs', type: 'array<object>', required: true, description: 'Audit rows.' },
                { name: 'page', type: 'number', required: true, description: 'Page number.' },
                { name: 'limit', type: 'number', required: true, description: 'Page size used for query.' },
                { name: 'total', type: 'number', required: true, description: 'Total records.' },
                { name: 'meta.page', type: 'number', required: true, description: 'Current page number.' },
                { name: 'meta.limit', type: 'number', required: true, description: 'Current page size.' },
                { name: 'meta.total', type: 'number', required: true, description: 'Total matching records.' },
                { name: 'meta.totalPages', type: 'number', required: true, description: 'Total page count.' },
                { name: 'meta.hasNextPage', type: 'boolean', required: true, description: 'Whether next page exists.' },
                { name: 'meta.hasPreviousPage', type: 'boolean', required: true, description: 'Whether previous page exists.' }
            ]
        }
    },
    {
        id: 'orders.slots.get',
        method: 'GET',
        path: '/api/v1/orders/slots',
        owner: 'user_app',
        auth: 'user',
        response: {
            description: 'Available delivery time slots for scheduled orders.',
            fields: [
                { name: 'days', type: 'number', required: true, description: 'Days of slots returned.' },
                { name: 'slot_minutes', type: 'number', required: true, description: 'Slot size in minutes.' },
                { name: 'slots', type: 'array<object>', required: true, description: 'Slot list with start/end timestamps.' }
            ]
        }
    },
    {
        id: 'orders.handoff.update',
        method: 'PATCH',
        path: '/api/v1/orders/:id/handoff',
        owner: 'vendor_app',
        auth: 'vendor',
        request: {
            description: 'Update handoff status for class delivery. Proof URL is required for delivered/failed states and may be geofence-validated.',
            fields: [
                { name: 'status', type: 'string', required: true, description: 'Handoff status: pending|arrived_building|arrived_class|delivered|failed.' },
                { name: 'proof_url', type: 'string', required: false, description: 'Proof URL (required for delivered/failed).' }
            ]
        },
        response: {
            description: 'Updated order record with handoff status.',
            fields: [
                { name: 'id', type: 'string(uuid)', required: true, description: 'Order id.' },
                { name: 'handoff_status', type: 'string', required: true, description: 'Updated handoff status.' }
            ]
        }
    },
    {
        id: 'notifications.list',
        method: 'GET',
        path: '/api/v1/notifications',
        owner: 'shared',
        auth: 'authenticated',
        response: {
            description: 'Notification feed for the authenticated principal.',
            fields: [
                { name: '[].id', type: 'string(uuid)', required: true, description: 'Notification id.' },
                { name: '[].title', type: 'string', required: true, description: 'Notification title.' },
                { name: '[].body', type: 'string', required: true, description: 'Notification body.' },
                { name: '[].type', type: 'string', required: false, description: 'Notification type tag.' },
                { name: '[].metadata', type: 'object', required: false, description: 'Metadata payload.' },
                { name: '[].is_read', type: 'boolean', required: true, description: 'Read state.' }
            ]
        }
    },
    {
        id: 'notifications.read',
        method: 'PATCH',
        path: '/api/v1/notifications/:id/read',
        owner: 'shared',
        auth: 'authenticated',
        response: {
            description: 'Mark notification as read.',
            fields: [
                { name: 'id', type: 'string(uuid)', required: true, description: 'Notification id.' },
                { name: 'is_read', type: 'boolean', required: true, description: 'Updated read flag.' }
            ]
        }
    },
    {
        id: 'notifications.device.register',
        method: 'POST',
        path: '/api/v1/notifications/device',
        owner: 'shared',
        auth: 'authenticated',
        request: {
            description: 'Register a device token for push delivery.',
            fields: [
                { name: 'token', type: 'string', required: true, description: 'Device token string.' },
                { name: 'platform', type: 'string', required: false, description: 'Platform label.' }
            ]
        },
        response: {
            description: 'Device token registration record.',
            fields: [
                { name: 'id', type: 'string(uuid)', required: true, description: 'Device token id.' },
                { name: 'token', type: 'string', required: true, description: 'Registered token.' }
            ]
        }
    },
    {
        id: 'notifications.device.remove',
        method: 'DELETE',
        path: '/api/v1/notifications/device',
        owner: 'shared',
        auth: 'authenticated',
        request: {
            description: 'Remove a device token.',
            fields: [
                { name: 'token', type: 'string', required: true, description: 'Device token string.' }
            ]
        },
        response: {
            description: 'Removal acknowledgement.',
            fields: [
                { name: 'success', type: 'boolean', required: true, description: 'Removal success flag.' }
            ]
        }
    },
    {
        id: 'promos.active.list',
        method: 'GET',
        path: '/api/v1/promos/active',
        owner: 'user_app',
        auth: 'user',
        response: {
            description: 'Active promo codes available to users.',
            fields: [
                { name: '[].id', type: 'string(uuid)', required: true, description: 'Promo id.' },
                { name: '[].code', type: 'string', required: true, description: 'Promo code.' },
                { name: '[].discount_type', type: 'string', required: true, description: 'Discount type.' },
                { name: '[].discount_value', type: 'number', required: true, description: 'Discount value.' }
            ]
        }
    },
    {
        id: 'promos.validate',
        method: 'POST',
        path: '/api/v1/promos/validate',
        owner: 'user_app',
        auth: 'user',
        request: {
            description: 'Validate promo code against order total.',
            fields: [
                { name: 'code', type: 'string', required: true, description: 'Promo code.' },
                { name: 'order_total', type: 'number', required: true, description: 'Current order total.' }
            ]
        },
        response: {
            description: 'Validated promo response.',
            fields: [
                { name: 'promo_id', type: 'string(uuid)', required: true, description: 'Promo id.' },
                { name: 'discount_amount', type: 'number', required: true, description: 'Discount amount.' },
                { name: 'final_amount', type: 'number', required: true, description: 'Total after discount.' }
            ]
        }
    },
    {
        id: 'admin.promos.list',
        method: 'GET',
        path: '/api/v1/admin/promos',
        owner: 'admin_app',
        auth: 'admin',
        response: {
            description: 'Admin promo listing.',
            fields: [
                { name: '[]', type: 'array<object>', required: true, description: 'Promo records.' }
            ]
        }
    },
    {
        id: 'admin.promos.create',
        method: 'POST',
        path: '/api/v1/admin/promos',
        owner: 'admin_app',
        auth: 'admin',
        request: {
            description: 'Create a promo code.',
            fields: [
                { name: 'code', type: 'string', required: true, description: 'Promo code.' },
                { name: 'discount_type', type: 'string', required: true, description: 'Discount type.' },
                { name: 'discount_value', type: 'number', required: true, description: 'Discount value.' }
            ]
        },
        response: {
            description: 'Promo record.',
            fields: [
                { name: 'id', type: 'string(uuid)', required: true, description: 'Promo id.' },
                { name: 'code', type: 'string', required: true, description: 'Promo code.' }
            ]
        }
    },
    {
        id: 'admin.promos.update',
        method: 'PATCH',
        path: '/api/v1/admin/promos/:id',
        owner: 'admin_app',
        auth: 'admin',
        response: {
            description: 'Updated promo record.',
            fields: [
                { name: 'id', type: 'string(uuid)', required: true, description: 'Promo id.' },
                { name: 'is_active', type: 'boolean', required: false, description: 'Active state.' }
            ]
        }
    },
    {
        id: 'campus.buildings.public',
        method: 'GET',
        path: '/api/v1/public/buildings',
        owner: 'user_app',
        auth: 'public',
        response: {
            description: 'Public list of active campus buildings.',
            fields: [
                { name: '[].id', type: 'string(uuid)', required: true, description: 'Building id.' },
                { name: '[].name', type: 'string', required: true, description: 'Building name.' },
                { name: '[].latitude', type: 'number', required: false, description: 'Latitude.' },
                { name: '[].longitude', type: 'number', required: false, description: 'Longitude.' }
            ]
        }
    },
    {
        id: 'campus.zones.public',
        method: 'GET',
        path: '/api/v1/public/zones',
        owner: 'user_app',
        auth: 'public',
        response: {
            description: 'Public list of active delivery zones.',
            fields: [
                { name: '[].id', type: 'string(uuid)', required: true, description: 'Zone id.' },
                { name: '[].name', type: 'string', required: true, description: 'Zone name.' },
                { name: '[].building_id', type: 'string(uuid)', required: false, description: 'Associated building.' }
            ]
        }
    },
    {
        id: 'class.sessions.list',
        method: 'GET',
        path: '/api/v1/class-sessions',
        owner: 'user_app',
        auth: 'user',
        response: {
            description: 'List of saved class sessions for a user.',
            fields: [
                { name: '[].id', type: 'string(uuid)', required: true, description: 'Session id.' },
                { name: '[].building_id', type: 'string(uuid)', required: true, description: 'Building id.' },
                { name: '[].room', type: 'string', required: true, description: 'Room label.' },
                { name: '[].starts_at', type: 'string(datetime)', required: false, description: 'Start time.' },
                { name: '[].ends_at', type: 'string(datetime)', required: false, description: 'End time.' }
            ]
        }
    },
    {
        id: 'class.sessions.create',
        method: 'POST',
        path: '/api/v1/class-sessions',
        owner: 'user_app',
        auth: 'user',
        request: {
            description: 'Create a class session.',
            fields: [
                { name: 'building_id', type: 'string(uuid)', required: true, description: 'Building id.' },
                { name: 'room', type: 'string', required: true, description: 'Room label.' },
                { name: 'starts_at', type: 'string(datetime)', required: false, description: 'Start time.' },
                { name: 'ends_at', type: 'string(datetime)', required: false, description: 'End time.' }
            ]
        },
        response: {
            description: 'Created class session.',
            fields: [
                { name: 'id', type: 'string(uuid)', required: true, description: 'Session id.' }
            ]
        }
    },
    {
        id: 'admin.campus.buildings.list',
        method: 'GET',
        path: '/api/v1/admin/campus/buildings',
        owner: 'admin_app',
        auth: 'admin',
        response: {
            description: 'Admin list of campus buildings.',
            fields: [
                { name: '[]', type: 'array<object>', required: true, description: 'Building records.' }
            ]
        }
    },
    {
        id: 'admin.campus.zones.list',
        method: 'GET',
        path: '/api/v1/admin/campus/zones',
        owner: 'admin_app',
        auth: 'admin',
        response: {
            description: 'Admin list of delivery zones.',
            fields: [
                { name: '[]', type: 'array<object>', required: true, description: 'Zone records.' }
            ]
        }
    },
    {
        id: 'contracts.registry.get',
        method: 'GET',
        path: '/api/v1/contracts/registry',
        owner: 'shared',
        auth: 'public',
        response: {
            description: 'Canonical contract registry payload.',
            fields: [
                { name: 'version', type: 'string', required: true, description: 'Registry version.' },
                { name: 'endpoints', type: 'array<object>', required: true, description: 'Endpoint contract list.' }
            ]
        }
    },
    {
        id: 'contracts.changelog.get',
        method: 'GET',
        path: '/api/v1/contracts/changelog',
        owner: 'shared',
        auth: 'public',
        response: {
            description: 'Versioned contract changelog feed.',
            fields: [
                { name: 'version', type: 'string', required: true, description: 'Current contract version.' },
                { name: 'changes', type: 'array<object>', required: true, description: 'Chronological contract change list.' }
            ]
        }
    },
    {
        id: 'contracts.flags.get',
        method: 'GET',
        path: '/api/v1/contracts/flags',
        owner: 'shared',
        auth: 'public',
        response: {
            description: 'Feature flags for staged contract adoption.',
            fields: [
                { name: 'flags', type: 'array<object>', required: true, description: 'Contract feature flags.' }
            ]
        }
    }
];

export const CONTRACT_ERROR_ENVELOPE = {
    description: 'Standardized error envelope for non-2xx responses.',
    fields: [
        { name: 'error', type: 'string', required: true, description: 'Machine-readable error type.' },
        { name: 'message', type: 'string', required: true, description: 'Human-readable message.' }
    ]
};
