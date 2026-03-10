require('dotenv').config({ path: '.env' });
const { createClient } = require('@supabase/supabase-js');
const http = require('http');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function testMe() {
    console.log('--- Auth/Me Diagnostic Script (v2) ---');

    // 1. Get a fresh token for admin@swift.com
    console.log('Signing in to get token...');
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
        email: 'admin@swift.com',
        password: 'admin@swift'
    });

    if (authError) {
        console.error('Sign-in failed:', authError.message);
        return;
    }

    const token = authData.session.access_token;
    console.log('Token acquired. Decoding token...');

    try {
        const segments = token.split('.');
        if (segments.length === 3) {
            console.log('Token Header:', Buffer.from(segments[0], 'base64').toString());
            console.log('Token Payload:', Buffer.from(segments[1], 'base64').toString());
        } else {
            console.log('Token segment count unexpected:', segments.length);
        }
    } catch (err) {
        console.error('Failed to decode token segments:', err.message);
    }

    console.log('Calling /me...');

    const options = {
        hostname: 'localhost',
        port: 3000,
        path: '/api/v1/auth/me',
        method: 'GET',
        headers: {
            'Authorization': `Bearer ${token}`
        }
    };

    const req = http.request(options, (res) => {
        let body = '';
        res.on('data', (chunk) => body += chunk);
        res.on('end', () => {
            console.log('Response Status:', res.statusCode);
            console.log('Response Body:', body);
        });
    });

    req.on('error', (err) => {
        console.error('Request Error:', err.message);
    });

    req.end();
}

testMe();
