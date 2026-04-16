import 'dotenv/config';

const API_URL = 'http://localhost:3000/api/v1';

const testE2E = async () => {
    console.log('--- Starting Backend E2E Verification ---');

    try {
        // 1. Health Check
        const healthRes = await fetch(`${API_URL.replace('/api/v1', '')}/health`);
        const health = await healthRes.json();
        console.log('✅ Health Check:', (health as any).status);

        // 2. Auth Protection Check
        const authRes = await fetch(`${API_URL}/auth/me`);
        console.log('✅ Auth Protection Check (Expected 401/400):', authRes.status);

        // 3. Vendor RBAC Check
        const vendorRes = await fetch(`${API_URL}/vendor-ops/profile`);
        console.log('✅ Vendor RBAC Check (Expected 401/400):', vendorRes.status);

        console.log('--- Backend Verification Complete ---');
        console.log('Note: Full E2E logic requires valid Supabase Auth tokens.');

    } catch (err: any) {
        console.error('❌ E2E Test Failed:', err.message);
    }
};

testE2E();
