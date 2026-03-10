require('dotenv').config({ path: '.env' });
const { createClient } = require('@supabase/supabase-js');
const http = require('http');
const path = require('path');

// Ensure env is loaded before client creation
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

async function testAdminAPI() {
    console.log('--- Testing Admin Real-Data APIs ---');

    // 1. Get Token
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
        email: 'admin@swift.com',
        password: 'admin@swift'
    });
    if (authError) {
        console.error('Sign-in failed:', authError.message);
        return;
    }
    const token = authData.session.access_token;
    console.log('Auth Successful.');

    const callAPI = (path) => new Promise((resolve) => {
        const options = {
            hostname: 'localhost',
            port: 3000,
            path: `/api/v1/admin${path}`,
            method: 'GET',
            headers: { 'Authorization': `Bearer ${token}` }
        };
        const req = http.request(options, (res) => {
            let body = '';
            res.on('data', chunk => body += chunk);
            res.on('end', () => resolve({ status: res.statusCode, data: JSON.parse(body) }));
        });
        req.on('error', err => resolve({ status: 500, error: err.message }));
        req.end();
    });

    // 2. Test Stats
    console.log('\nTesting /admin/stats...');
    const statsRes = await callAPI('/stats');
    console.log('Status:', statsRes.status);
    console.log('Data:', JSON.stringify(statsRes.data, null, 2));

    // 3. Test Charts
    console.log('\nTesting /admin/charts...');
    const chartsRes = await callAPI('/charts');
    console.log('Status:', chartsRes.status);
    console.log('Data (first 2):', JSON.stringify(chartsRes.data.chartData?.slice(0, 2), null, 2));

    // 4. Test Pending Vendors
    console.log('\nTesting /admin/vendors/pending...');
    const vendorsRes = await callAPI('/vendors/pending');
    console.log('Status:', vendorsRes.status);
    console.log('Count:', vendorsRes.data.vendors?.length);
}

testAdminAPI();
