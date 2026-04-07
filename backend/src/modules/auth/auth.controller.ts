import { FastifyRequest, FastifyReply } from 'fastify';
import { supabase } from '../../services/supabase';
import crypto from 'crypto';

const OTP_TTL_MINUTES = Number(process.env.PASSWORD_RESET_OTP_TTL_MINUTES || 10);
const OTP_MAX_ATTEMPTS = Number(process.env.PASSWORD_RESET_OTP_MAX_ATTEMPTS || 5);

const normalizeEmail = (value: string) => value.trim().toLowerCase();

const hashOtp = (otp: string) => crypto.createHash('sha256').update(otp).digest('hex');

const generateSixDigitOtp = () => {
    const n = crypto.randomInt(0, 1000000);
    return n.toString().padStart(6, '0');
};

const sendPasswordResetEmailViaBrevo = async (email: string, otp: string) => {
    const apiKey = process.env.BREVO_API_KEY;
    const senderEmail = process.env.BREVO_FROM_EMAIL;
    const senderName = process.env.BREVO_FROM_NAME || 'Swift Support';

    if (!apiKey || !senderEmail) {
        throw new Error('Brevo configuration missing: BREVO_API_KEY and BREVO_FROM_EMAIL are required');
    }

    const response = await fetch('https://api.brevo.com/v3/smtp/email', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'api-key': apiKey,
        },
        body: JSON.stringify({
            sender: { email: senderEmail, name: senderName },
            to: [{ email }],
            subject: 'Your Swift password reset code',
            htmlContent: `
                <div style="font-family:Arial,sans-serif;line-height:1.5;color:#1b1b1b;">
                  <h2 style="margin:0 0 12px 0;">Reset your password</h2>
                  <p>Use this 6-digit code to reset your Swift password:</p>
                  <p style="font-size:28px;font-weight:700;letter-spacing:6px;margin:12px 0;">${otp}</p>
                  <p>This code expires in ${OTP_TTL_MINUTES} minutes.</p>
                  <p>If you did not request this, you can ignore this email.</p>
                </div>
            `,
            textContent: `Reset your Swift password. Your 6-digit code is ${otp}. This code expires in ${OTP_TTL_MINUTES} minutes.`,
        }),
    });

    if (!response.ok) {
        const body = await response.text();
        throw new Error(`Brevo send failed (${response.status}): ${body}`);
    }
};

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

export const forgotPasswordHandler = async (request: FastifyRequest, reply: FastifyReply) => {
    const { email } = request.body as { email?: string };

    if (!email || typeof email !== 'string') {
        const err = new Error('email is required') as any;
        err.statusCode = 400;
        throw err;
    }

    const normalizedEmail = normalizeEmail(email);

    const { data: userRecord } = await supabase
        .from('users')
        .select('id, email')
        .ilike('email', normalizedEmail)
        .maybeSingle();

    // Always return a generic success response to avoid account enumeration.
    if (!userRecord?.id) {
        return reply.send({ message: 'If the account exists, a 6-digit reset code has been sent.' });
    }

    const otp = generateSixDigitOtp();
    const otpHash = hashOtp(otp);
    const expiresAt = new Date(Date.now() + OTP_TTL_MINUTES * 60 * 1000).toISOString();

    await supabase
        .from('password_reset_codes')
        .update({ consumed_at: new Date().toISOString() })
        .ilike('email', normalizedEmail)
        .is('consumed_at', null);

    const { error: insertError } = await supabase
        .from('password_reset_codes')
        .insert({
            user_id: userRecord.id,
            email: normalizedEmail,
            code_hash: otpHash,
            expires_at: expiresAt,
            attempts: 0,
        });

    if (insertError) {
        throw insertError;
    }

    await sendPasswordResetEmailViaBrevo(normalizedEmail, otp);

    return reply.send({ message: 'If the account exists, a 6-digit reset code has been sent.' });
};

export const resetPasswordWithOtpHandler = async (request: FastifyRequest, reply: FastifyReply) => {
    const { email, pin, new_password } = request.body as {
        email?: string;
        pin?: string;
        new_password?: string;
    };

    if (!email || !pin || !new_password) {
        const err = new Error('email, pin, and new_password are required') as any;
        err.statusCode = 400;
        throw err;
    }

    if (!/^\d{6}$/.test(pin)) {
        const err = new Error('pin must be a 6-digit numeric code') as any;
        err.statusCode = 400;
        throw err;
    }

    if (new_password.length < 8) {
        const err = new Error('Password must be at least 8 characters') as any;
        err.statusCode = 400;
        throw err;
    }

    const normalizedEmail = normalizeEmail(email);

    const { data: codeRow, error: codeError } = await supabase
        .from('password_reset_codes')
        .select('id, user_id, code_hash, expires_at, attempts, consumed_at')
        .ilike('email', normalizedEmail)
        .is('consumed_at', null)
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle();

    if (codeError) {
        throw codeError;
    }

    if (!codeRow) {
        const err = new Error('Invalid or expired reset code') as any;
        err.statusCode = 400;
        throw err;
    }

    const isExpired = new Date(codeRow.expires_at).getTime() < Date.now();
    if (isExpired) {
        await supabase.from('password_reset_codes').update({ consumed_at: new Date().toISOString() }).eq('id', codeRow.id);
        const err = new Error('Invalid or expired reset code') as any;
        err.statusCode = 400;
        throw err;
    }

    if ((codeRow.attempts || 0) >= OTP_MAX_ATTEMPTS) {
        await supabase.from('password_reset_codes').update({ consumed_at: new Date().toISOString() }).eq('id', codeRow.id);
        const err = new Error('Too many invalid attempts. Request a new code.') as any;
        err.statusCode = 429;
        throw err;
    }

    const providedHash = hashOtp(pin);
    if (providedHash !== codeRow.code_hash) {
        await supabase.from('password_reset_codes').update({ attempts: (codeRow.attempts || 0) + 1 }).eq('id', codeRow.id);
        const err = new Error('Invalid or expired reset code') as any;
        err.statusCode = 400;
        throw err;
    }

    const { error: updateAuthError } = await supabase.auth.admin.updateUserById(codeRow.user_id, {
        password: new_password,
    });

    if (updateAuthError) {
        throw updateAuthError;
    }

    await supabase.from('password_reset_codes').update({ consumed_at: new Date().toISOString() }).eq('id', codeRow.id);

    return reply.send({ message: 'Password updated successfully' });
};
