import fs from 'fs';
import path from 'path';

const BASE_URL = process.env.API_BASE_URL?.trim() || 'http://localhost:3000/api/v1';
const LOG_FILE = path.join(__dirname, '..', 'api_test.log');
const vendorId = process.env.TEST_VENDOR_ID?.trim() || '';
const orderId = process.env.TEST_ORDER_ID?.trim() || '';
const loginEmail = process.env.TEST_LOGIN_EMAIL?.trim() || 'student@campus.edu';
const loginPassword = process.env.TEST_LOGIN_PASSWORD?.trim() || 'securepassword123';
const addressLine1 = process.env.TEST_ADDRESS_LINE1?.trim() || '123 Main St';
const addressCity = process.env.TEST_ADDRESS_CITY?.trim() || 'Campus';
const addressType = process.env.TEST_ADDRESS_TYPE?.trim() || 'home';

// Clear log file
fs.writeFileSync(LOG_FILE, `API Test Log - ${new Date().toISOString()}\n\n`);

function log(message: string) {
    console.log(message);
    fs.appendFileSync(LOG_FILE, message + '\n');
}

async function runTests() {
    log('Starting Comprehensive API Tests...');
    let passed = 0;
    let failed = 0;
    let authToken = '';

    if (!vendorId) {
        log('[INFO] TEST_VENDOR_ID is not set; vendor-scoped endpoints will be skipped.');
    }
    if (!orderId) {
        log('[INFO] TEST_ORDER_ID is not set; delivery-scoped endpoints will be skipped.');
    }

    const endpoints: Array<{
        method: string;
        path: string;
        body?: Record<string, unknown>;
        params?: string;
        protected?: boolean;
        isLogin?: boolean;
        requires?: Array<'vendorId' | 'orderId'>;
    }> = [
        // Auth
        { method: 'POST', path: '/auth/register', body: { email: `test_${Date.now()}@test.com`, password: 'Password123!', name: 'Test User' } },
        { method: 'POST', path: '/auth/session', body: { email: loginEmail, password: loginPassword }, isLogin: true },
        { method: 'GET', path: '/auth/me', protected: true },

        // Orders
        { method: 'POST', path: '/orders', protected: true, body: { vendor_id: vendorId, total_amount: 150.00, items: [{ id: 'item-1', quantity: 2, price: 75.00 }] }, requires: ['vendorId'] },
        { method: 'GET', path: '/orders/me', protected: true },

        // Vendor Ops
        { method: 'GET', path: '/vendor-ops/profile', protected: true },
        { method: 'GET', path: '/vendor-ops/orders', protected: true },
        { method: 'GET', path: '/vendor-ops/stats', protected: true },

        // Menus
        { method: 'GET', path: `/menus/vendor/${vendorId}`, requires: ['vendorId'] },
        { method: 'POST', path: '/menus', protected: true, body: { name: 'New Menu' } },

        // Public
        { method: 'GET', path: '/public/vendors' },
        { method: 'GET', path: '/public/search', params: 'q=burger' },

        // Payments
        { method: 'POST', path: '/payments/create-order', protected: true, body: { amount: 500 } },

        // Addresses
        { method: 'GET', path: '/addresses', protected: true },
        { method: 'POST', path: '/addresses', protected: true, body: { line1: addressLine1, city: addressCity, type: addressType } },

        // Reviews
        { method: 'GET', path: `/reviews/vendor/${vendorId}`, requires: ['vendorId'] },

        // Delivery
        { method: 'GET', path: `/delivery/${orderId}/location`, protected: true, requires: ['orderId'] },

        // Admin
        { method: 'GET', path: '/admin/stats', protected: true },
        { method: 'GET', path: '/admin/vendors/pending', protected: true },
    ];

    for (const ep of endpoints) {
        if (ep.requires?.includes('vendorId') && !vendorId) {
            log(`[SKIP] ${ep.method} ${ep.path} - TEST_VENDOR_ID not set`);
            continue;
        }
        if (ep.requires?.includes('orderId') && !orderId) {
            log(`[SKIP] ${ep.method} ${ep.path} - TEST_ORDER_ID not set`);
            continue;
        }

        const url = `${BASE_URL}${ep.path}${ep.params ? '?' + ep.params : ''}`;
        const headers: Record<string, string> = { 'Content-Type': 'application/json' };
        if (ep.protected && authToken) {
            headers['Authorization'] = `Bearer ${authToken}`;
        }

        try {
            const response = await fetch(url, {
                method: ep.method,
                headers,
                body: ep.body ? JSON.stringify(ep.body) : undefined
            });

            const status = response.status;
            let data: any = {};
            try {
                data = await response.json();
            } catch (e) {
                // If it's not JSON, we'll just get the text for debugging
                const text = await response.text().catch(() => '');
                data = { raw: text };
            }

            if (status >= 200 && status < 300) {
                log(`[PASS] ${ep.method} ${ep.path} - Status: ${status}`);
                passed++;
                if (ep.isLogin && data.session?.access_token) {
                    authToken = data.session.access_token;
                    log('  -> Auth token acquired');
                }
            } else {
                log(`[FAIL] ${ep.method} ${ep.path} - Status: ${status}`);
                log(`  -> Response Header: ${response.headers.get('content-type')}`);
                log(`  -> Error Data: ${JSON.stringify(data).substring(0, 500)}${JSON.stringify(data).length > 500 ? '...' : ''}`);
                failed++;
            }
        } catch (error: any) {
            log(`[FAIL] ${ep.method} ${ep.path} - Request failed: ${error.message}`);
            failed++;
        }
    }

    log(`\nTest Summary:`);
    log(`Total: ${passed + failed}`);
    log(`Passed: ${passed}`);
    log(`Failed: ${failed}`);
    log(`Full logs available at: ${LOG_FILE}`);
}

runTests().catch(err => {
    log(`CRITICAL ERROR: ${err.message}`);
    process.exit(1);
});
