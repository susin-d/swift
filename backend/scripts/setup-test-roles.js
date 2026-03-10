require('dotenv').config({ path: '.env' });
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function setupUsers() {
    const roles = [
        { email: 'admin@swift.com', password: 'admin@swift', role: 'admin', name: 'Global Admin' },
        { email: 'anna@bhawan.com', password: 'password123', role: 'vendor', name: 'ANNA' },
        { email: 'user@example.com', password: 'password123', role: 'user', name: 'Test User' }
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
