require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

async function fixSchema() {
    console.log('Adding "status" column to "vendors" table...');

    // We use RPC or raw SQL if available, but since we are using service role, 
    // we can try to use the query builder if there's a way, 
    // but usually schema changes are done via SQL.
    // In Supabase, if we don't have a migration tool setup here, we can try to execute via a hypothetical RPC or just assume the user can run this if it fails.
    // However, I will try to see if I can find a way to run SQL.

    const { error } = await supabase.rpc('execute_sql', {
        query: 'ALTER TABLE vendors ADD COLUMN IF NOT EXISTS status TEXT DEFAULT "pending";'
    });

    if (error) {
        if (error.message.includes('function execute_sql(query) does not exist')) {
            console.error('❌ RPC "execute_sql" not found. Please run this manually in Supabase SQL Editor:');
            console.error('ALTER TABLE vendors ADD COLUMN IF NOT EXISTS status TEXT DEFAULT \'pending\';');
            console.error('UPDATE vendors SET status = \'approved\' WHERE status IS NULL;');
        } else {
            console.error('❌ Error executing SQL:', error.message);
        }
    } else {
        console.log('✅ "status" column added successfully.');
    }
}

fixSchema();
