import { FastifyRequest, FastifyReply } from 'fastify';
import { supabase } from '../../services/supabase';

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
    const usersTable = supabase.from('users') as any;
    let userError: any = null;
    if (usersTable?.insert) {
        const inserted = await usersTable.insert({
            id: data.user.id,
            name,
            email,
            role: 'user'
        });
        userError = inserted?.error ?? null;
    } else {
        const upserted = await usersTable.upsert({
            id: data.user.id,
            name,
            email,
            role: 'user'
        }, { onConflict: 'id' });
        userError = upserted?.error ?? null;
    }

    if (userError) {
        const err = new Error(userError.message) as any;
        err.statusCode = 400;
        throw err;
    }

    // 2. Ensure customer profile exists (idempotent)
    const customerProfilesTable = supabase.from('customer_profiles') as any;
    const profileWrite = customerProfilesTable?.insert
        ? await customerProfilesTable.insert({ id: data.user.id })
        : await customerProfilesTable.upsert({ id: data.user.id }, { onConflict: 'id' });
    const profileError = profileWrite?.error ?? null;

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

export const acceptStaffOnboardingInviteHandler = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const { token } = request.body as { token?: string };

    if (!token || typeof token !== 'string') {
        const err = new Error('token is required') as any;
        err.statusCode = 400;
        throw err;
    }

    const { data: invitation, error: invitationError } = await supabase
        .from('vendor_staff_invitations')
        .select('*')
        .eq('invite_token', token)
        .maybeSingle();

    if (invitationError) throw invitationError;
    if (!invitation) {
        const err = new Error('Invitation not found') as any;
        err.statusCode = 404;
        throw err;
    }

    if (invitation.status !== 'pending') {
        const err = new Error('Invitation is no longer valid') as any;
        err.statusCode = 400;
        throw err;
    }

    const expiresAt = invitation.expires_at ? new Date(invitation.expires_at).getTime() : 0;
    if (expiresAt > 0 && expiresAt < Date.now()) {
        const err = new Error('Invitation has expired') as any;
        err.statusCode = 400;
        throw err;
    }

    const invitedUserId = invitation.invited_user_id as string | null;
    const invitedEmail = (invitation.email || '').toString().toLowerCase();
    const requesterEmail = (user.email || '').toString().toLowerCase();

    if (invitedUserId && invitedUserId !== user.sub) {
        const err = new Error('Invitation does not belong to this user') as any;
        err.statusCode = 403;
        throw err;
    }

    if (!invitedUserId && invitedEmail && requesterEmail && invitedEmail !== requesterEmail) {
        const err = new Error('Invitation email does not match authenticated user') as any;
        err.statusCode = 403;
        throw err;
    }

    const now = new Date().toISOString();

    const { data: existingStaff } = await supabase
        .from('vendor_staff_members')
        .select('id')
        .eq('vendor_id', invitation.vendor_id)
        .eq('user_id', user.sub)
        .maybeSingle();

    if (existingStaff?.id) {
        const { error: updateStaffError } = await supabase
            .from('vendor_staff_members')
            .update({
                role_key: invitation.role_key,
                status: 'active',
                email: user.email || invitation.email,
                updated_at: now,
            })
            .eq('id', existingStaff.id);

        if (updateStaffError) throw updateStaffError;
    } else {
        const { error: createStaffError } = await supabase
            .from('vendor_staff_members')
            .insert({
                vendor_id: invitation.vendor_id,
                user_id: user.sub,
                name: user.email?.split('@')[0] || 'Staff Member',
                role_key: invitation.role_key,
                status: 'active',
                email: user.email || invitation.email,
                updated_at: now,
            });

        if (createStaffError) throw createStaffError;
    }

    const { error: markAcceptedError } = await supabase
        .from('vendor_staff_invitations')
        .update({
            invited_user_id: user.sub,
            status: 'accepted',
            accepted_at: now,
            updated_at: now,
        })
        .eq('id', invitation.id);

    if (markAcceptedError) throw markAcceptedError;

    await supabase.from('admin_logs').insert({
        admin_id: user.sub,
        action_performed: 'vendor.staff.invitation.accept',
        target_id: invitation.id,
        reason: `Staff onboarding accepted for vendor ${invitation.vendor_id}`,
    });

    return reply.send({
        onboarding: {
            invitation_id: invitation.id,
            vendor_id: invitation.vendor_id,
            role_key: invitation.role_key,
            status: 'accepted',
        },
    });
};
