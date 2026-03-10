require('dotenv').config({ path: '.env' });
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function testGetUser() {
    console.log('--- Supabase getUser Test ---');

    // 1. Get a token
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
        email: 'admin@swift.com',
        password: 'admin@swift'
    });

    if (authError) {
        console.error('Sign-in failed:', authError.message);
        return;
    }

    const token = authData.session.access_token;
    console.log('Token acquired. Header:', JSON.stringify(JSON.parse(Buffer.from(token.split('.')[0], 'base64').toString())));

    // 2. Call getUser
    try {
        console.log('Calling supabase.auth.getUser...');
        const { data, error } = await supabase.auth.getUser(token);
        if (error) {
            console.error('getUser Error:', error);
        } else {
            console.log('getUser Success! User:', data.user.email);
        }
    } catch (err) {
        console.error('getUser Threw:', err);
    }
}

testGetUser();
