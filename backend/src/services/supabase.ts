import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

// ENSURE ENV IS LOADED BEFORE EXPORTING CLIENT
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const supabaseUrl = process.env.SUPABASE_URL || 'https://xyzcompany.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || 'public-anon-key';
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY || '';
const nodeEnv = process.env.NODE_ENV || 'development';

const isPlaceholderValue = (value: string) => {
    const normalized = value.trim().toLowerCase();
    return (
        normalized.length === 0 ||
        normalized === 'public-anon-key' ||
        normalized.includes('your-project-id') ||
        normalized.includes('your-service-role-key') ||
        normalized.includes('xyzcompany.supabase.co')
    );
};

if (nodeEnv === 'production') {
    if (isPlaceholderValue(supabaseUrl) || isPlaceholderValue(supabaseKey)) {
        throw new Error(
            'Invalid production Supabase configuration. Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in backend environment variables.'
        );
    }
}

console.log('Supabase Config (Internal):', {
    url: supabaseUrl,
    hasServiceRoleKey: !isPlaceholderValue(supabaseKey),
    nodeEnv,
});

export const supabase = createClient(supabaseUrl, supabaseKey, {
    auth: {
        autoRefreshToken: false,
        persistSession: false,
        detectSessionInUrl: false
    }
});

export const createSupabaseUserClient = (accessToken: string) => {
    if (isPlaceholderValue(supabaseAnonKey)) {
        throw new Error('SUPABASE_ANON_KEY is required for user-scoped Supabase clients');
    }

    return createClient(supabaseUrl, supabaseAnonKey, {
        global: {
            headers: {
                Authorization: `Bearer ${accessToken}`,
            },
        },
        auth: {
            autoRefreshToken: false,
            persistSession: false,
            detectSessionInUrl: false,
        },
    });
};
