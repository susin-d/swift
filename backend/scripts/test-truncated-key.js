require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_ANON_KEY;

if (!url || !key) {
    console.error('Missing SUPABASE_URL or SUPABASE_ANON_KEY in environment variables.');
    process.exit(1);
}

const supabase = createClient(url, key);

async function test() {
    console.log('Testing login with truncated ANON_KEY...');
    const { data, error } = await supabase.auth.signInWithPassword({
        email: 'admin@swift.com',
        password: 'admin@swift'
    });

    if (error) {
        console.error('Login Error:', error.message);
    } else {
        console.log('Login SUCCESSFUL with truncated key!');
    }
}

test();
