require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

const supabase = createClient(supabaseUrl, supabaseKey);

async function seedDemoUser() {
    const email = 'demo@user.com';
    const password = 'password123';
    const name = 'Demo User';

    console.log(`Checking if demo user exists: ${email}`);

    const { data: authUserResult, error: authError } = await supabase.auth.admin.listUsers();
    if (authError) {
        console.error('Error listing users:', authError);
        throw authError;
    }

    let existingAuthUser = authUserResult.users.find(u => u.email === email);
    let userId;

    if (!existingAuthUser) {
        console.log(`Creating auth user: ${email}`);
        const { data: newAuth, error: createAuthError } = await supabase.auth.admin.createUser({
            email,
            password,
            email_confirm: true,
            user_metadata: { name, role: 'user' }
        });
        if (createAuthError) throw createAuthError;
        userId = newAuth.user.id;
    } else {
        userId = existingAuthUser.id;
        console.log(`Auth user already exists with ID: ${userId}`);
    }

    // Sync to public.users
    let { data: user, error: selectError } = await supabase.from('users').select('*').eq('id', userId).single();
    if (!user) {
        console.log(`Syncing public user for: ${email}`);
        const { error: insertError } = await supabase.from('users').insert({
            id: userId,
            name,
            email,
            role: 'user'
        });
        if (insertError) throw insertError;
    } else {
        console.log('Public user record already exists.');
    }

    // Create customer profile
    let { data: profile, error: profileSelectError } = await supabase.from('customer_profiles').select('*').eq('id', userId).single();
    if (!profile) {
        console.log(`Creating customer profile for: ${email}`);
        const { error: profileError } = await supabase.from('customer_profiles').insert({ id: userId });
        if (profileError) {
            console.error('Customer profile creation error:', profileError);
        }
    } else {
        console.log('Customer profile already exists.');
    }

    console.log('Demo user seeding completed successfully.');
}

seedDemoUser().catch(err => {
    console.error('Seed error:', err);
    process.exit(1);
});
