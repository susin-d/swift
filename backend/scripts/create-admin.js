require('dotenv').config({ path: '.env' });
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
    console.error('Error: Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env');
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey, {
    auth: {
        autoRefreshToken: false,
        persistSession: false
    }
});

async function createAdmin() {
    const email = 'admin@swift.com';
    const password = 'admin@swift';

    console.log(`Attempting to create admin user: ${email}`);

    // 1. Create the auth user
    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        user_metadata: { role: 'admin' }
    });

    if (authError) {
        if (authError.message.includes('User already registered')) {
            console.log('User already exists in Auth. Proceeding to update public.users...');

            // Get existing user id
            const { data: userData } = await supabase.from('users').select('id').eq('email', email).single();
            if (userData) {
                await updatePublicUser(userData.id, email);
            } else {
                // If in auth but not public, we need to find the ID by email in auth
                // Note: auth.admin doesn't have a simple "getByEmail", so we list users
                const { data: { users }, error: listError } = await supabase.auth.admin.listUsers();
                const existingUser = users.find(u => u.email === email);
                if (existingUser) {
                    await updatePublicUser(existingUser.id, email);
                }
            }
        } else {
            console.error('Error creating auth user:', authError.message);
            return;
        }
    } else {
        console.log('Auth user created successfully.');
        await updatePublicUser(authData.user.id, email);
    }
}

async function updatePublicUser(id, email) {
    // 2. Insert/Update into public.users
    const { error: publicError } = await supabase
        .from('users')
        .upsert({
            id,
            email,
            name: 'Global Admin',
            role: 'admin'
        }, { onConflict: 'id' });

    if (publicError) {
        console.error('Error updating public.users table:', publicError.message);
    } else {
        console.log('Successfully created/verified admin in public.users table.');
    }
}

createAdmin();
