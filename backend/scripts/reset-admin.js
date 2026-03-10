require('dotenv').config({ path: '.env' });
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function resetAdmin() {
    const email = 'admin@swift.com';
    const newPassword = 'admin@swift';

    console.log(`Resetting password for ${email}...`);

    // 1. Find user by email
    const { data: { users }, error: listError } = await supabase.auth.admin.listUsers();
    if (listError) {
        console.error('Error listing users:', listError);
        return;
    }

    const admin = users.find(u => u.email === email);
    if (!admin) {
        console.error('Admin user not found. Please run create-admin.js first.');
        return;
    }

    // 2. Update password
    const { data, error } = await supabase.auth.admin.updateUserById(admin.id, {
        password: newPassword
    });

    if (error) {
        console.error('Error updating password:', error.message);
        return;
    }

    console.log('Password successfully reset to: ' + newPassword);

    // 3. Verify login (with a regular client using the SERVICE_ROLE_KEY as a bypass for testing)
    // Actually, to test "regular" login we should use the ANON_KEY, but it's corrupted.
    // However, SERVICE_ROLE_KEY can also be used with signInWithPassword.

    console.log('Verifying login with new credentials...');
    const { data: loginData, error: loginError } = await supabase.auth.signInWithPassword({
        email,
        password: newPassword
    });

    if (loginError) {
        console.error('Final Verification Failed:', loginError.message);
    } else {
        console.log('Final Verification SUCCESSFUL!');
        console.log('User ID:', loginData.user.id);
        console.log('Role:', loginData.user.user_metadata.role);
    }
}

resetAdmin();
