require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseKey) {
    console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in environment variables.');
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function check() {
    console.log('Checking Auth Admin API...');
    const { data, error } = await supabase.auth.admin.listUsers();
    if (error) {
        console.error('Auth Admin Error:', error);
    } else {
        console.log('Users found:', data.users.length);
    }

    console.log('Checking Vendors Table...');
    const { data: v, error: ve } = await supabase.from('vendors').select('*');
    if (ve) {
        console.error('Vendors Error:', ve);
    } else {
        console.log('Vendors found:', v.length);
    }
}
check();
