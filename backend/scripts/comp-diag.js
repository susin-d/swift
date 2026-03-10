require('dotenv').config({ path: '.env' });
const { createClient } = require('@supabase/supabase-js');
const https = require('https');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function testAll() {
    console.log('--- Comprehensive Auth Diagnostic ---');
    console.log('URL:', supabaseUrl);

    // 1. Raw Network Test
    console.log('\n1. Testing Raw HTTPS connection to Auth endpoint...');
    const url = new URL(supabaseUrl);
    const options = {
        hostname: url.hostname,
        port: 443,
        path: '/auth/v1/health',
        method: 'GET'
    };

    const netTest = new Promise((resolve) => {
        const req = https.request(options, (res) => {
            console.log('HTTPS Status:', res.statusCode);
            resolve(true);
        });
        req.on('error', (e) => {
            console.error('HTTPS Connection Failed:', e.message);
            resolve(false);
        });
        req.end();
    });
    await netTest;

    // 2. Refresh Token / Sign In
    console.log('\n2. Testing Sign-In...');
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
        email: 'admin@swift.com',
        password: 'admin@swift'
    });

    if (authError) {
        console.error('Sign-in failed:', authError);
        return;
    }
    console.log('Sign-in Success.');

    // 3. getUser Test
    console.log('\n3. Testing getUser(token)...');
    const token = authData.session.access_token;
    const { data: userData, error: userError } = await supabase.auth.getUser(token);
    if (userError) {
        console.error('getUser failed:', JSON.stringify(userError, null, 2));
    } else {
        console.log('getUser SUCCESS! User:', userData.user.email);
    }
}

testAll();
