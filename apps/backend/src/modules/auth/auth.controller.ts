import { FastifyRequest, FastifyReply } from 'fastify';
import { supabase } from '../../services/supabase';
import crypto from 'crypto';
import {
    buildSessionPayload,
    createAccessToken,
    hashPassword,
    verifyPassword,
} from '../../services/customAuth';

const OTP_TTL_MINUTES = Number(process.env.PASSWORD_RESET_OTP_TTL_MINUTES || 10);
const OTP_MAX_ATTEMPTS = Number(process.env.PASSWORD_RESET_OTP_MAX_ATTEMPTS || 5);
const FORGOT_PASSWORD_WINDOW_SECONDS = Number(process.env.FORGOT_PASSWORD_WINDOW_SECONDS || 300);
const FORGOT_PASSWORD_MAX_REQUESTS = Number(process.env.FORGOT_PASSWORD_MAX_REQUESTS || 5);
const FORGOT_PASSWORD_COOLDOWN_SECONDS = Number(process.env.FORGOT_PASSWORD_COOLDOWN_SECONDS || 900);

const normalizeEmail = (value: string) => value.trim().toLowerCase();

const hashOtp = (otp: string) => crypto.createHash('sha256').update(otp).digest('hex');

const generateSixDigitOtp = () => {
    const n = crypto.randomInt(0, 1000000);
    return n.toString().padStart(6, '0');
};

type OtpPurpose = 'password_reset' | 'registration';

type RateLimitBucket = {
    count: number;
    resetAtMs: number;
    blockedUntilMs: number;
};

const forgotPasswordRateMap = new Map<string, RateLimitBucket>();

const enforceForgotPasswordRateLimit = (request: FastifyRequest, email: string) => {
    const ip = String((request as any).ip || 'unknown');
    const now = Date.now();
    const key = `${ip}:${email}`;
    const windowMs = Math.max(1, FORGOT_PASSWORD_WINDOW_SECONDS) * 1000;
    const cooldownMs = Math.max(1, FORGOT_PASSWORD_COOLDOWN_SECONDS) * 1000;

    // Opportunistic cleanup to prevent unbounded growth.
    if (forgotPasswordRateMap.size > 2000) {
        for (const [bucketKey, bucketValue] of forgotPasswordRateMap.entries()) {
            if (bucketValue.resetAtMs < now && bucketValue.blockedUntilMs < now) {
                forgotPasswordRateMap.delete(bucketKey);
            }
        }
    }

    const existing = forgotPasswordRateMap.get(key);
    if (!existing || existing.resetAtMs < now) {
        forgotPasswordRateMap.set(key, {
            count: 1,
            resetAtMs: now + windowMs,
            blockedUntilMs: 0,
        });
        return;
    }

    if (existing.blockedUntilMs > now) {
        const err = new Error('Too many password reset requests. Try again later.') as any;
        err.statusCode = 429;
        throw err;
    }

    existing.count += 1;
    if (existing.count > Math.max(1, FORGOT_PASSWORD_MAX_REQUESTS)) {
        existing.blockedUntilMs = now + cooldownMs;
        const err = new Error('Too many password reset requests. Try again later.') as any;
        err.statusCode = 429;
        throw err;
    }
};

const sendOtpEmailViaBrevo = async (email: string, otp: string, purpose: OtpPurpose) => {
    const apiKey = process.env.BREVO_API_KEY;
    const senderEmail = process.env.BREVO_FROM_EMAIL;
    const senderName = process.env.BREVO_FROM_NAME || 'Swift Support';

    const isRegistrationOtp = purpose === 'registration';
    const subject = isRegistrationOtp ? 'Your Swift verification code' : 'Your Swift password reset code';
    const heading = isRegistrationOtp ? 'Verify your email' : 'Reset your password';
    const intro = isRegistrationOtp
        ? 'Use this 6-digit code to verify your Swift account:'
        : 'Use this 6-digit code to reset your Swift password:';
    const footer = isRegistrationOtp
        ? 'If you did not create this account, you can ignore this email.'
        : 'If you did not request this, you can ignore this email.';

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
            subject,
            htmlContent: `
                <div style="font-family:Arial,sans-serif;line-height:1.5;color:#1b1b1b;">
                  <h2 style="margin:0 0 12px 0;">${heading}</h2>
                  <p>${intro}</p>
                  <p style="font-size:28px;font-weight:700;letter-spacing:6px;margin:12px 0;">${otp}</p>
                  <p>This code expires in ${OTP_TTL_MINUTES} minutes.</p>
                  <p>${footer}</p>
                </div>
            `,
            textContent: `${heading}. Your 6-digit code is ${otp}. This code expires in ${OTP_TTL_MINUTES} minutes.`,
        }),
    });

    if (!response.ok) {
        const body = await response.text();
        throw new Error(`Brevo send failed (${response.status}): ${body}`);
    }
};

const issueOtpForEmail = async (email: string, userId: string, purpose: OtpPurpose) => {
    const otp = generateSixDigitOtp();
    const otpHash = hashOtp(otp);
    const expiresAt = new Date(Date.now() + OTP_TTL_MINUTES * 60 * 1000).toISOString();

    await supabase
        .from('password_reset_codes')
        .update({ consumed_at: new Date().toISOString() })
        .ilike('email', email)
        .is('consumed_at', null);

    const { error: insertError } = await supabase
        .from('password_reset_codes')
        .insert({
            user_id: userId,
            email,
            code_hash: otpHash,
            expires_at: expiresAt,
            attempts: 0,
        });

    if (insertError) {
        throw insertError;
    }

    await sendOtpEmailViaBrevo(email, otp, purpose);
};

export const loginHandler = async (request: FastifyRequest, reply: FastifyReply) => {
    const { email, password } = request.body as any;
    if (!email || !password) return reply.code(400).send({ error: 'Email and password required' });

    const normalizedEmail = normalizeEmail(email);

    const { data: account, error: accountError } = await supabase
        .from('auth_accounts')
        .select('user_id, email, password_hash, is_blocked')
        .ilike('email', normalizedEmail)
        .maybeSingle();

    if (accountError) {
        console.error('[loginHandler] Database error fetching account:', accountError);
        const err = new Error('Service temporarily unavailable') as any;
        err.statusCode = 503;
        throw err;
    }

    if (!account) {
        const err = new Error('Invalid login credentials') as any;
        err.statusCode = 401;
        throw err;
    }

    const isValid = await verifyPassword(password, String((account as any).password_hash || ''));
    if (!isValid) {
        const err = new Error('Invalid login credentials') as any;
        err.statusCode = 401;
        throw err;
    }

    if ((account as any).is_blocked) {
        const err = new Error('Account is blocked. Contact support.') as any;
        err.statusCode = 403;
        throw err;
    }

    const { data: profile, error: profileError } = await supabase
        .from('users')
        .select('id, email, role, name')
        .eq('id', (account as any).user_id)
        .maybeSingle();

    if (profileError) {
        console.error('[loginHandler] Database error fetching profile:', profileError);
        const err = new Error('Service temporarily unavailable') as any;
        err.statusCode = 503;
        throw err;
    }

    if (!profile) {
        const err = new Error('Invalid login credentials') as any;
        err.statusCode = 401;
        throw err;
    }

    const accessToken = createAccessToken({
        sub: profile.id,
        email: profile.email,
        role: (profile.role || 'user') as 'user' | 'vendor' | 'admin',
    });
    const session = buildSessionPayload(accessToken);

    return reply.send({
        user: {
            id: profile.id,
            email: profile.email,
            role: profile.role || 'user',
            name: profile.name,
        },
        session,
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

    const normalizedEmail = normalizeEmail(email);

    const { data: existingAccount } = await supabase
        .from('auth_accounts')
        .select('user_id')
        .ilike('email', normalizedEmail)
        .maybeSingle();

    if (existingAccount?.user_id) {
        const err = new Error('User already registered') as any;
        err.statusCode = 409;
        throw err;
    }

    const userId = crypto.randomUUID();
    const passwordHash = await hashPassword(password);

    const { error: userInsertError } = await supabase
        .from('users')
        .insert({
            id: userId,
            name,
            email: normalizedEmail,
            role: 'user',
        });

    if (userInsertError) {
        const err = new Error(userInsertError.message) as any;
        err.statusCode = 400;
        throw err;
    }

    const { error: accountInsertError } = await supabase
        .from('auth_accounts')
        .insert({
            user_id: userId,
            email: normalizedEmail,
            password_hash: passwordHash,
            is_blocked: false,
        });

    if (accountInsertError) {
        await supabase.from('users').delete().eq('id', userId);
        const message = String(accountInsertError.message || '').toLowerCase();
        const err = new Error(accountInsertError.message) as any;
        err.statusCode = message.includes('duplicate') ? 409 : 400;
        throw err;
    }

    const customerProfilesTable = supabase.from('customer_profiles') as any;
    const profileWrite = customerProfilesTable?.insert
        ? await customerProfilesTable.insert({ id: userId })
        : await customerProfilesTable.upsert({ id: userId }, { onConflict: 'id' });
    const profileError = profileWrite?.error ?? null;

    if (profileError) {
        console.error('Customer profile creation error:', profileError);
    }

    try {
        await issueOtpForEmail(normalizedEmail, userId, 'registration');
    } catch (otpError: any) {
        console.error(`Registration OTP dispatch failed for ${normalizedEmail}:`, otpError?.message || otpError);
    }

    return reply.code(201).send({
        message: 'Registration successful',
        user: {
            id: userId,
            email: normalizedEmail,
            role: 'user',
            name,
        },
    });
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
    enforceForgotPasswordRateLimit(request, normalizedEmail);

    const { data: userRecord } = await supabase
        .from('auth_accounts')
        .select('user_id, email')
        .ilike('email', normalizedEmail)
        .maybeSingle();

    // Always return a generic success response to avoid account enumeration.
    if (!(userRecord as any)?.user_id) {
        return reply.send({ message: 'If the account exists, a 6-digit reset code has been sent.' });
    }

    await issueOtpForEmail(normalizedEmail, (userRecord as any).user_id, 'password_reset');

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

    const nextPasswordHash = await hashPassword(new_password);

    const { error: updateAuthError } = await supabase
        .from('auth_accounts')
        .update({ password_hash: nextPasswordHash, updated_at: new Date().toISOString() })
        .eq('user_id', codeRow.user_id);

    if (updateAuthError) {
        throw updateAuthError;
    }

    await supabase.from('password_reset_codes').update({ consumed_at: new Date().toISOString() }).eq('id', codeRow.id);

    return reply.send({ message: 'Password updated successfully' });
};
