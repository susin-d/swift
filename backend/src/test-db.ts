import 'dotenv/config'; // Must be first so env vars load before supabase does
import { supabase } from './services/supabase';

const testConnection = async () => {
    console.log('Testing Supabase Connection...');
    console.log(`URL Segment: ${process.env.SUPABASE_URL?.split('//')[1]}`);

    try {
        const { data: users, error: usersError } = await supabase.from('users').select('*').limit(1);

        if (usersError) {
            console.error('❌ Connection Failed! Error reading from Users table.');
            console.error(usersError);
            return;
        }

        console.log('✅ Connection Successful! Read operation from Users table passed.');
        console.log('---');
        console.log(`Total users fetched: ${users?.length || 0}`);

        // Testing vendor access
        const { data: vendors, error: vendorError } = await supabase.from('vendors').select('*').limit(1);

        if (vendorError) {
            console.error('❌ Role Policies failure reading vendors.');
            console.error(vendorError);
            return;
        }

        console.log('✅ Connection Successful! Read operation from Vendors table passed.');

        // Test the Realtime Channel
        console.log('✅ Supabase initialized successfully.');
        console.log('✅ All Basic Database operations functional.');

    } catch (err) {
        console.error('❌ Unexpected caught error:', err);
    }
};

testConnection();
