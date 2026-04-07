require('dotenv').config({ path: '.env' });
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function setupUsers() {
    const defaultPassword = process.env.DEFAULT_TEST_PASSWORD || 'ChangeMeBeforeUse!123';
    const roles = [
        {
            email: process.env.ADMIN_EMAIL || 'admin@example.com',
            password: process.env.ADMIN_PASSWORD || defaultPassword,
            role: 'admin',
            name: process.env.ADMIN_NAME || 'Global Admin'
        },
        {
            email: process.env.TEST_VENDOR_EMAIL || 'vendor@example.com',
            password: process.env.TEST_VENDOR_PASSWORD || defaultPassword,
            role: 'vendor',
            name: process.env.TEST_VENDOR_NAME || 'Test Vendor'
        },
        {
            email: process.env.TEST_USER_EMAIL || 'user@example.com',
            password: process.env.TEST_USER_PASSWORD || defaultPassword,
            role: 'user',
            name: process.env.TEST_USER_NAME || 'Test User'
        }
    ];

    for (const u of roles) {
        console.log(`Setting up user: ${u.email}`);
        const { data: authUser, error: authError } = await supabase.auth.admin.createUser({
            email: u.email,
            password: u.password,
            email_confirm: true,
            user_metadata: { role: u.role, name: u.name }
        });

        let userId;
        if (authError) {
            if (authError.message.includes('already registered')) {
                const { data: { users } } = await supabase.auth.admin.listUsers();
                userId = users.find(user => user.email === u.email).id;
                console.log(`User ${u.email} already exists in Auth.`);
            } else {
                console.error(`Error creating auth user ${u.email}:`, authError.message);
                continue;
            }
        } else {
            userId = authUser.user.id;
            console.log(`Auth user ${u.email} created.`);
        }

        const { error: publicError } = await supabase.from('users').upsert({
            id: userId,
            email: u.email,
            name: u.name,
            role: u.role
        }, { onConflict: 'id' });

        if (publicError) {
            console.error(`Error syncing ${u.email} to public.users:`, publicError.message);
        } else {
            console.log(`Public user ${u.email} synced.`);
        }
    }
}

setupUsers();
