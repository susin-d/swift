require('dotenv').config({ path: '.env' });
const { createClient } = require('@supabase/supabase-js');
const path = require('path');

require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseKey) {
    console.error(
        'Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY. ' +
        'Set them before running this verification helper.'
    );
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function verifyVendorStatusColumn() {
    console.log('Checking whether the vendors.status column is present...');

    const { error } = await supabase.from('vendors').select('status').limit(1);

    if (!error) {
        console.log('The vendors.status column is present.');
        return;
    }

    console.error(
        'The vendors.status column is not available yet. ' +
        'Apply the matching Supabase migration in supabase/migrations or update supabase/schema.sql.'
    );
    process.exitCode = 1;
}

verifyVendorStatusColumn().catch((err) => {
    console.error(`Verification failed: ${err.message}`);
    process.exit(1);
});
