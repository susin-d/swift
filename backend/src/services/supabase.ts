import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

// ENSURE ENV IS LOADED BEFORE EXPORTING CLIENT
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const supabaseUrl = process.env.SUPABASE_URL || 'https://xyzcompany.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || 'public-anon-key';

console.log('Supabase Config (Internal):', {
    url: supabaseUrl,
    keyPrefix: supabaseKey.substring(0, 10) + '...',
    isServiceRole: supabaseKey.includes('service_role') || supabaseKey.length > 100
});

export const supabase = createClient(supabaseUrl, supabaseKey, {
    auth: {
        autoRefreshToken: false,
        persistSession: false,
        detectSessionInUrl: false
    }
});
