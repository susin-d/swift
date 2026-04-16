require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkSchema() {
    const { data, error } = await supabase.rpc('get_check_constraint', { t: 'payments', c: 'payments_status_check' });
    console.log('Check constraint:', data);

    const { data: cols, error: colErr } = await supabase.from('payments').select('*').limit(1);
    console.log('Columns:', cols ? Object.keys(cols[0] || {}) : 'No data');
}

checkSchema().catch(console.error);
