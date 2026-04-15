import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

export type AuthTokenPayload = {
    sub: string;
    email: string;
    role: 'user' | 'vendor' | 'admin';
};

const accessSecret = process.env.JWT_ACCESS_SECRET || process.env.JWT_SECRET;
if (!accessSecret || accessSecret.trim().length === 0) {
    throw new Error('JWT_ACCESS_SECRET (or JWT_SECRET) must be set.');
}
if (process.env.NODE_ENV === 'production' && accessSecret.trim().length < 32) {
    throw new Error('JWT_ACCESS_SECRET (or JWT_SECRET) must be at least 32 characters in production.');
}
const accessTtlMinutes = Number(process.env.ACCESS_TOKEN_TTL_MIN || 60);
const saltRounds = Number(process.env.PASSWORD_HASH_ROUNDS || 12);

export const hashPassword = async (password: string) => {
    return bcrypt.hash(password, saltRounds);
};

export const verifyPassword = async (password: string, passwordHash: string) => {
    return bcrypt.compare(password, passwordHash);
};

export const createAccessToken = (payload: AuthTokenPayload) => {
    return jwt.sign(payload, accessSecret, {
        expiresIn: `${accessTtlMinutes}m`,
    });
};

export const verifyAccessToken = (token: string): AuthTokenPayload => {
    const decoded = jwt.verify(token, accessSecret) as jwt.JwtPayload;
    const role = String(decoded.role || 'user') as 'user' | 'vendor' | 'admin';

    return {
        sub: String(decoded.sub || ''),
        email: String(decoded.email || ''),
        role,
    };
};

export const buildSessionPayload = (accessToken: string) => ({
    access_token: accessToken,
    token_type: 'bearer',
    expires_in: accessTtlMinutes * 60,
});
