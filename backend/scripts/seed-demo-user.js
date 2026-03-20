require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

const supabase = createClient(supabaseUrl, supabaseKey);

const demoUsers = [
    {
        email: 'demo.user@swift.com',
        password: 'Demo@1234',
        name: 'Demo User',
        role: 'user',
        createProfile: 'customer_profiles'
    },
    {
        email: 'demo.vendor@swift.com',
        password: 'Demo@1234',
        name: 'Demo Vendor',
        role: 'vendor',
        createProfile: 'vendors'
    },
    {
        email: 'demo.admin@swift.com',
        password: 'Demo@1234',
        name: 'Demo Admin',
        role: 'admin',
        createProfile: null // Admins may not need specific profile
    }
];

async function seedDemoUser(userData) {
    const { email, password, name, role, createProfile } = userData;

    console.log(`\n=== Creating ${role} demo user: ${email} ===`);

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
            user_metadata: { name, role }
        });
        if (createAuthError) throw createAuthError;
        userId = newAuth.user.id;
        console.log(`✓ Auth user created with ID: ${userId}`);
    } else {
        userId = existingAuthUser.id;
        console.log(`✓ Auth user already exists with ID: ${userId}`);
    }

    // Sync to public.users
    let { data: user, error: selectError } = await supabase.from('users').select('*').eq('id', userId).single();
    if (!user) {
        console.log(`Syncing public user for: ${email}`);
        const { error: insertError } = await supabase.from('users').insert({
            id: userId,
            name,
            email,
            role
        });
        if (insertError) throw insertError;
        console.log(`✓ Public user record created`);
    } else {
        console.log(`✓ Public user record already exists`);
    }

    // Create role-specific profile if needed
    if (createProfile === 'customer_profiles') {
        let { data: profile } = await supabase.from(createProfile).select('*').eq('id', userId).single();
        if (!profile) {
            console.log(`Creating ${role} profile in ${createProfile}...`);
            const { error: profileError } = await supabase.from(createProfile).insert({ id: userId });
            if (profileError) {
                console.error(`Profile creation error for ${createProfile}:`, profileError);
            } else {
                console.log(`✓ ${role} profile created`);
            }
        } else {
            console.log(`✓ ${role} profile already exists`);
        }
    }

    if (createProfile === 'vendors') {
        const { data: vendorProfile, error: vendorFetchError } = await supabase
            .from('vendors')
            .select('id')
            .eq('owner_id', userId)
            .limit(1)
            .maybeSingle();

        if (vendorFetchError) {
            console.error('Vendor profile lookup error:', vendorFetchError);
        } else if (!vendorProfile) {
            console.log('Creating vendor profile in vendors...');
            const { error: vendorInsertError } = await supabase
                .from('vendors')
                .insert({
                    owner_id: userId,
                    name,
                    description: 'Demo vendor account',
                    is_open: true
                });

            if (vendorInsertError) {
                console.error('Vendor profile creation error:', vendorInsertError);
            } else {
                console.log('✓ vendor profile created');
            }
        } else {
            console.log('✓ vendor profile already exists');
        }
    }

    console.log(`✓ ${role} demo user setup complete`);
    return { email, password, role };
}

async function main() {
    console.log('Starting demo user seeding...');
    const results = [];

    for (const user of demoUsers) {
        try {
            const result = await seedDemoUser(user);
            results.push(result);
        } catch (err) {
            console.error(`Error seeding ${user.role} user:`, err);
        }
    }

    console.log('\n=== Demo Users Created ===');
    results.forEach(r => {
        console.log(`${r.role.toUpperCase()}: ${r.email} / ${r.password}`);
    });
    console.log('\nCredentials saved to backend/demo-credentials.json');

    // Save credentials to file for app reference
    const fs = require('fs');
    fs.writeFileSync(
        require('path').join(__dirname, '..', 'demo-credentials.json'),
        JSON.stringify(results, null, 2)
    );
}

main().catch(err => {
    console.error('Seed error:', err);
    process.exit(1);
});
