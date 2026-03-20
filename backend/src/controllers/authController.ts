import { FastifyRequest, FastifyReply } from 'fastify';
import { supabase } from '../services/supabase';

export const loginHandler = async (request: FastifyRequest, reply: FastifyReply) => {
    const { email, password } = request.body as any;
    if (!email || !password) return reply.code(400).send({ error: 'Email and password required' });

    const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
    });

    if (error) {
        const err = new Error(error.message) as any;
        err.statusCode = 401;
        throw err;
    }

    // Get user role from public.users table
    const { data: profile } = await supabase
        .from('users')
        .select('role')
        .eq('id', data.user.id)
        .single();

    return reply.send({
        user: {
            id: data.user.id,
            email: data.user.email,
            role: profile?.role || 'user'
        },
        session: data.session
    });
};

export const getMeHandler = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;

    if (!user) {
        const err = new Error('User context missing') as any;
        err.statusCode = 500;
        throw err;
    }

    // Fetch base user profile
    const { data: baseUser, error } = await supabase
        .from('users')
        .select('*')
        .eq('id', user.sub)
        .single();

    if (error || !baseUser) {
        // Log for monitoring but don't fail with 404
        console.warn(`[getMeHandler] Profile not found in database for user ${user.sub}. Returning default.`);

        return reply.send({
            user: {
                id: user.sub,
                email: user.email,
                role: user.role || 'user',
                name: user.email?.split('@')[0] || 'User',
                profile: {}
            }
        });
    }

    // Fetch role-specific details
    let profileDetails = {};
    if (baseUser.role === 'admin') {
        const { data } = await supabase.from('admin_profiles').select('*').eq('id', user.sub).single();
        profileDetails = data || {};
    } else if (baseUser.role === 'vendor') {
        const { data } = await supabase.from('vendors').select('*').eq('owner_id', user.sub).single();
        profileDetails = data || {};
    } else {
        const { data } = await supabase.from('customer_profiles').select('*').eq('id', user.sub).single();
        profileDetails = data || {};
    }

    return reply.send({
        user: {
            ...baseUser,
            profile: profileDetails
        }
    });
};

export const registerHandler = async (request: FastifyRequest, reply: FastifyReply) => {
    const { email, password, name } = request.body as any;

    if (!email || !password || !name) {
        const err = new Error('Name, email, and password are required') as any;
        err.statusCode = 400;
        throw err;
    }

    if (typeof password !== 'string' || password.length < 8) {
        const err = new Error('Password must be at least 8 characters') as any;
        err.statusCode = 400;
        throw err;
    }

    const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
            data: { name, role: 'user' } // Force default role to user
        }
    });

    if (error) {
        const message = (error.message || '').toLowerCase();
        const err = new Error(error.message) as any;
        err.statusCode = message.includes('already registered') ? 409 : 400;
        throw err;
    }

    if (!data.user) {
        const err = new Error('Unable to complete registration') as any;
        err.statusCode = 500;
        throw err;
    }

    const identities = (data.user as any).identities as Array<unknown> | undefined;
    if (Array.isArray(identities) && identities.length === 0) {
        const err = new Error('User already registered') as any;
        err.statusCode = 409;
        throw err;
    }

    // 1. Sync to public.users (idempotent)
    const { error: userError } = await supabase
        .from('users')
        .upsert({
            id: data.user.id,
            name,
            email,
            role: 'user'
        }, { onConflict: 'id' });

    if (userError) {
        const err = new Error(userError.message) as any;
        err.statusCode = 400;
        throw err;
    }

    // 2. Ensure customer profile exists (idempotent)
    const { error: profileError } = await supabase
        .from('customer_profiles')
        .upsert({ id: data.user.id }, { onConflict: 'id' });

    if (profileError) {
        console.error('Customer profile creation error:', profileError);
    }

    return reply.code(201).send({ message: 'Registration successful', user: data.user });
};

export const updateMeHandler = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const { name, phone, address } = request.body as any;

    if (!name && !phone && !address) {
        const err = new Error('At least one field (name, phone, address) is required') as any;
        err.statusCode = 400;
        throw err;
    }

    // 1. Update base user record if name is provided
    if (name) {
        const { error: userError } = await supabase
            .from('users')
            .update({ name, updated_at: new Date().toISOString() })
            .eq('id', user.sub);

        if (userError) throw userError;
    }

    // 2. Update role-specific profile
    const { data: userRecord, error: fetchError } = await supabase
        .from('users')
        .select('role')
        .eq('id', user.sub)
        .single();

    if (fetchError) throw fetchError;

    let profileTable = '';
    if (userRecord.role === 'admin') profileTable = 'admin_profiles';
    else if (userRecord.role === 'user') profileTable = 'customer_profiles';

    if (profileTable && (phone || address)) {
        const updateData: any = {};
        if (phone) updateData.phone = phone;
        if (address) updateData.address = address;

        const { error: profileError } = await supabase
            .from(profileTable)
            .update({ ...updateData, updated_at: new Date().toISOString() })
            .eq('id', user.sub);

        if (profileError) throw profileError;
    }

    return reply.send({ message: 'Profile updated successfully' });
};

