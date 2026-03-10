require('dotenv').config({ path: '.env' });
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function checkUser() {
    const { data: { users }, error } = await supabase.auth.admin.listUsers();
    if (error) {
        console.error('Error listing users:', error);
        return;
    }

    const admin = users.find(u => u.email === 'admin@swift.com');
    if (admin) {
        console.log('User found in Auth:');
        console.log('ID:', admin.id);
        console.log('Email:', admin.email);
        console.log('Confirmed At:', admin.email_confirmed_at);
        console.log('Metadata:', admin.user_metadata);
    } else {
        console.log('User NOT found in Auth.');
    }

    // Check public users table too
    const { data: publicUser, error: publicError } = await supabase.from('users').select('*').eq('email', 'admin@swift.com').single();
    if (publicError) {
        console.log('Not found in public.users table or error:', publicError.message);
    } else {
        console.log('Found in public.users table:', publicUser);
    }
}

checkUser();
