require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');
const supabaseUrl = 'https://ncknhkowypkjvzleyaar.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5ja25oa293eXBranZ6bGV5YWFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MjkxNDUwNiwiZXhwIjoyMDg4NDkwNTA2fQ.8n3S8P-6n-8f-5u7W8G8W6P9v-5P_98f-5u7W8G8W6P9v-5P_98f-5u7W';
const supabase = createClient(supabaseUrl, supabaseKey);

async function check() {
    console.log('Checking Auth Admin API...');
    const { data, error } = await supabase.auth.admin.listUsers();
    if (error) {
        console.error('Auth Admin Error:', error);
    } else {
        console.log('Users found:', data.users.length);
    }

    console.log('Checking Vendors Table...');
    const { data: v, error: ve } = await supabase.from('vendors').select('*');
    if (ve) {
        console.error('Vendors Error:', ve);
    } else {
        console.log('Vendors found:', v.length);
    }
}
check();
