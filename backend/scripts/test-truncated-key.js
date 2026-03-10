require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const url = process.env.SUPABASE_URL;
// Truncated key theory: the real signature part is the first 43 chars approx.
// Original signature part: 9iQ0Z_74l-p8_mB8G8W6P9v-5P_98f-5u7W8G8W6P9v-5P_98f-5u7W
// Truncated: 9iQ0Z_74l-p8_mB8G8W6P9v-5P_98f-5u7W
const key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5ja25oa293eXBranZ6bGV5YWFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI5MTQ1MDYsImV4cCI6MjA4ODQ5MDUwNn0.9iQ0Z_74l-p8_mB8G8W6P9v-5P_98f-5u7W';

const supabase = createClient(url, key);

async function test() {
    console.log('Testing login with truncated ANON_KEY...');
    const { data, error } = await supabase.auth.signInWithPassword({
        email: 'admin@swift.com',
        password: 'admin@swift'
    });

    if (error) {
        console.error('Login Error:', error.message);
    } else {
        console.log('Login SUCCESSFUL with truncated key!');
    }
}

test();
