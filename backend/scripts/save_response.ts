import fs from 'node:fs';
import path from 'node:path';

const BASE_URL = 'http://localhost:3000';

const ROLES = [
    {
        role: 'admin',
        email: 'admin@swift.com',
        password: 'admin@swift',
        outputFile: 'admin_responses.txt'
    },
    {
        role: 'vendor',
        email: 'anna@bhawan.com',
        password: 'password123',
        outputFile: 'vendor_responses.txt'
    },
    {
        role: 'user',
        email: 'user@example.com',
        password: 'password123',
        outputFile: 'user_responses.txt'
    }
];

let JWT_TOKEN = '';

async function login(credentials: any) {
    console.log(`\nLogging in as ${credentials.role} (${credentials.email})...`);
    JWT_TOKEN = '';
    try {
        const response = await fetch(`${BASE_URL}/api/v1/auth/session`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email: credentials.email, password: credentials.password })
        });
        const data: any = await response.json();
        if (data.session && data.session.access_token) {
            JWT_TOKEN = data.session.access_token;
            console.log(`Login successful for ${credentials.role}.`);
        } else {
            console.error(`Login failed for ${credentials.role}:`, data.error || 'Session not found');
        }
    } catch (error) {
        console.error(`Login request failed for ${credentials.role}:`, error);
    }
}

const ENDPOINTS = [
    { name: 'Health', path: '/health', method: 'GET' },
    // Auth Routes
    { name: 'Register (Mock)', path: '/api/v1/auth/register', method: 'POST', body: { email: 'test@example.com', password: 'password123', name: 'Test User' } },
    { name: 'Login (Mock)', path: '/api/v1/auth/session', method: 'POST', body: { email: 'test@example.com', password: 'password123' } },
    { name: 'My Profile', path: '/api/v1/auth/me', method: 'GET', auth: true },
    // Menu Routes
    { name: 'Vendor Menus', path: '/api/v1/menus/vendor/1', method: 'GET' }, // Assuming vendor ID 1 exists
    { name: 'Create Menu', path: '/api/v1/menus', method: 'POST', auth: true, body: { name: 'Breakfast Menu' } },
    { name: 'Create Menu Item', path: '/api/v1/menus/items', method: 'POST', auth: true, body: { menuId: 1, name: 'Idli', price: 50 } },
    // Admin Routes
    { name: 'Admin Stats', path: '/api/v1/admin/stats', method: 'GET', auth: true },
    { name: 'Admin Charts', path: '/api/v1/admin/charts', method: 'GET', auth: true },
    { name: 'Pending Vendors', path: '/api/v1/admin/vendors/pending', method: 'GET', auth: true },
    // Order Routes
    { name: 'Create Order', path: '/api/v1/orders', method: 'POST', auth: true, body: { items: [{ itemId: 1, quantity: 2 }] } },
    { name: 'My Orders', path: '/api/v1/orders/me', method: 'GET', auth: true },
    // Payment Routes
    { name: 'Create Payment Order', path: '/api/v1/payments/create-order', method: 'POST', auth: true, body: { amount: 100 } },
    // Vendor Ops
    { name: 'Vendor Profile', path: '/api/v1/vendor-ops/profile', method: 'GET', auth: true },
    { name: 'Vendor Menu (Ops)', path: '/api/v1/vendor-ops/menu', method: 'GET', auth: true },
    // Security / RBAC Tests
    {
        name: 'Register: Attempt Admin Role',
        path: '/api/v1/auth/register',
        method: 'POST',
        body: { email: `security_test_${Date.now()}@test.com`, password: 'password123', name: 'Hacker', role: 'admin' }
    },
    {
        name: 'Admin: Promote User to Vendor',
        path: '/api/v1/admin/users/role',
        method: 'POST',
        auth: true,
        body: { userId: 'will-be-patched-in-script', role: 'vendor' }
    },
    {
        name: 'Admin: Create New Vendor Account',
        path: '/api/v1/admin/vendors',
        method: 'POST',
        auth: true,
        body: { email: `vendor_new_${Date.now()}@test.com`, password: 'password123', name: 'Elite Eats', description: 'Premium dining experience' }
    },
    {
        name: 'Delivery: Update Location',
        path: '/api/v1/delivery/location',
        method: 'POST',
        auth: true,
        body: { order_id: 'will-be-patched', lat: 12.9716, lng: 77.5946 }
    },
    {
        name: 'Delivery: Get Location',
        path: '/api/v1/delivery/will-be-patched/location',
        method: 'GET',
        auth: true
    },
    {
        name: 'Menu: Update Category',
        path: '/api/v1/menus/will-be-patched',
        method: 'PATCH',
        auth: true,
        body: { category_name: 'Premium Starters', sort_order: 1 }
    },
    {
        name: 'Menu: Update Item Availability',
        path: '/api/v1/menus/items/will-be-patched',
        method: 'PATCH',
        auth: true,
        body: { is_available: false }
    },
    {
        name: 'Menu: Delete Item',
        path: '/api/v1/menus/items/will-be-patched',
        method: 'DELETE',
        auth: true
    },
    {
        name: 'Public: List Vendors',
        path: '/api/v1/public/vendors',
        method: 'GET',
        auth: false
    },
    {
        name: 'Vendor: Get Orders',
        path: '/api/v1/vendor-ops/orders',
        method: 'GET',
        auth: true
    },
    {
        name: 'Vendor: Get Stats',
        path: '/api/v1/vendor-ops/stats',
        method: 'GET',
        auth: true
    },
    {
        name: 'Auth: Update Profile',
        path: '/api/v1/auth/me',
        method: 'PATCH',
        auth: true,
        body: { name: 'Updated Name', phone: '9876543210', address: 'Hostel 5, Room 202' }
    },
    {
        name: 'Review: Submit Rating',
        path: '/api/v1/reviews',
        method: 'POST',
        auth: true,
        body: { order_id: 'will-be-patched', rating: 5, comment: 'Amazing food!' }
    },
    {
        name: 'Review: Get Vendor Reviews',
        path: '/api/v1/reviews/vendor/will-be-patched',
        method: 'GET',
        auth: false
    },
    {
        name: 'Public: Global Search',
        path: '/api/v1/public/search?q=pizza',
        method: 'GET',
        auth: false
    },
    {
        name: 'Address: Get My Addresses',
        path: '/api/v1/addresses',
        method: 'GET',
        auth: true
    },
    {
        name: 'Address: Add New Address',
        path: '/api/v1/addresses',
        method: 'POST',
        auth: true,
        body: { label: 'Hostel 1', address_line: 'Room 101, Ground Floor', is_default: true }
    },
];

async function fetchResponse(endpoint: any) {
    const url = `${BASE_URL}${endpoint.path}`;
    const headers: Record<string, string> = {
        'Content-Type': 'application/json'
    };

    if (endpoint.auth && JWT_TOKEN) {
        headers['Authorization'] = `Bearer ${JWT_TOKEN}`;
    }

    try {
        console.log(`Fetching ${endpoint.name} [${endpoint.method}] from ${url}...`);
        const options: RequestInit = {
            method: endpoint.method,
            headers
        };

        if (endpoint.body && (endpoint.method === 'POST' || endpoint.method === 'PATCH')) {
            options.body = JSON.stringify(endpoint.body);
        }

        const response = await fetch(url, options);
        let data;
        const contentType = response.headers.get('content-type');
        if (contentType && contentType.includes('application/json')) {
            data = await response.json();
        } else {
            data = await response.text();
        }

        return {
            name: endpoint.name,
            method: endpoint.method,
            path: endpoint.path,
            status: response.status,
            data
        };
    } catch (error) {
        return {
            name: endpoint.name,
            path: endpoint.path,
            error: error instanceof Error ? error.message : String(error)
        };
    }
}

async function main() {
    for (const roleConfig of ROLES) {
        const outputPath = path.join(__dirname, '..', roleConfig.outputFile);
        const results = [];

        await login(roleConfig);

        let lastCreatedUserId = '';
        for (const endpoint of ENDPOINTS) {
            // Patch userId if needed
            if (endpoint.name === 'Admin: Promote User to Vendor' && lastCreatedUserId && endpoint.body) {
                endpoint.body.userId = lastCreatedUserId;
            }

            const result = await fetchResponse(endpoint);
            results.push(result);

            // Capture ID if this was the secure registration test
            if (endpoint.name === 'Register: Attempt Admin Role' && result.status === 201) {
                lastCreatedUserId = result.data.user?.id;
            }
        }

        const content = JSON.stringify(results, null, 2);
        fs.writeFileSync(outputPath, content);
        console.log(`Responses for ${roleConfig.role} saved to ${outputPath}`);
    }
}

main();
