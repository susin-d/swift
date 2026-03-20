import crypto from 'crypto';
import http2 from 'http2';
import https from 'https';
import { supabase } from './supabase';

type PushPayload = {
    userId: string;
    audience: 'user' | 'vendor' | 'admin';
    title: string;
    body: string;
    metadata?: Record<string, any> | null;
};

type DeviceToken = {
    token: string;
    platform: string;
};

const FCM_SERVER_KEY = process.env.FCM_SERVER_KEY;
const APNS_KEY_ID = process.env.APNS_KEY_ID;
const APNS_TEAM_ID = process.env.APNS_TEAM_ID;
const APNS_BUNDLE_ID = process.env.APNS_BUNDLE_ID;
const APNS_PRIVATE_KEY = process.env.APNS_PRIVATE_KEY;
const APNS_ENV = process.env.APNS_ENV || 'sandbox';

let cachedApnsJwt: { token: string; expiresAt: number } | null = null;

const base64Url = (input: Buffer) =>
    input
        .toString('base64')
        .replace(/\+/g, '-')
        .replace(/\//g, '_')
        .replace(/=+$/, '');

const createApnsJwt = () => {
    if (!APNS_KEY_ID || !APNS_TEAM_ID || !APNS_PRIVATE_KEY) return null;
    const now = Math.floor(Date.now() / 1000);
    if (cachedApnsJwt && cachedApnsJwt.expiresAt > now + 60) {
        return cachedApnsJwt.token;
    }

    const header = {
        alg: 'ES256',
        kid: APNS_KEY_ID,
    };
    const payload = {
        iss: APNS_TEAM_ID,
        iat: now,
    };
    const unsigned = `${base64Url(Buffer.from(JSON.stringify(header)))}.${base64Url(Buffer.from(JSON.stringify(payload)))}`;

    const key = crypto.createPrivateKey({
        key: APNS_PRIVATE_KEY.replace(/\\n/g, '\n'),
    });
    const signature = crypto.sign('sha256', Buffer.from(unsigned), key);
    const token = `${unsigned}.${base64Url(signature)}`;
    cachedApnsJwt = { token, expiresAt: now + 50 * 60 };
    return token;
};

const normalizeData = (metadata: Record<string, any> | null | undefined) => {
    if (!metadata) return undefined;
    return Object.entries(metadata).reduce<Record<string, string>>((acc, [key, value]) => {
        if (value === null || value === undefined) return acc;
        acc[key] = typeof value === 'string' ? value : JSON.stringify(value);
        return acc;
    }, {});
};

const postJson = (url: string, headers: Record<string, string>, body: Record<string, any>) =>
    new Promise<number>((resolve, reject) => {
        const data = JSON.stringify(body);
        const request = https.request(
            url,
            {
                method: 'POST',
                headers: {
                    ...headers,
                    'Content-Type': 'application/json',
                    'Content-Length': Buffer.byteLength(data).toString(),
                },
            },
            (response) => {
                response.on('data', () => undefined);
                response.on('end', () => resolve(response.statusCode ?? 0));
            },
        );

        request.on('error', reject);
        request.write(data);
        request.end();
    });

const sendFcm = async (token: string, payload: PushPayload) => {
    if (!FCM_SERVER_KEY) return false;
    const statusCode = await postJson(
        'https://fcm.googleapis.com/fcm/send',
        { Authorization: `key=${FCM_SERVER_KEY}` },
        {
            to: token,
            notification: {
                title: payload.title,
                body: payload.body,
            },
            data: normalizeData(payload.metadata),
        },
    );

    return statusCode >= 200 && statusCode < 300;
};

const sendApns = async (token: string, payload: PushPayload) => {
    if (!APNS_BUNDLE_ID) return false;
    const jwt = createApnsJwt();
    if (!jwt) return false;

    const host = APNS_ENV === 'production' ? 'api.push.apple.com' : 'api.sandbox.push.apple.com';
    const client = http2.connect(`https://${host}`);

    return new Promise<boolean>((resolve) => {
        const req = client.request({
            ':method': 'POST',
            ':path': `/3/device/${token}`,
            authorization: `bearer ${jwt}`,
            'apns-topic': APNS_BUNDLE_ID,
            'apns-push-type': 'alert',
        });

        req.setEncoding('utf8');
        req.on('response', (headers) => {
            const status = Number(headers[':status'] ?? 0);
            req.on('data', () => undefined);
            req.on('end', () => {
                client.close();
                resolve(status >= 200 && status < 300);
            });
        });

        req.on('error', () => {
            client.close();
            resolve(false);
        });

        req.end(
            JSON.stringify({
                aps: {
                    alert: {
                        title: payload.title,
                        body: payload.body,
                    },
                    sound: 'default',
                },
                data: normalizeData(payload.metadata),
            }),
        );
    });
};

export const sendPushNotification = async (payload: PushPayload) => {
    if (!FCM_SERVER_KEY && (!APNS_BUNDLE_ID || !APNS_KEY_ID || !APNS_TEAM_ID || !APNS_PRIVATE_KEY)) {
        return { sent: 0, skipped: 0 };
    }

    const { data, error } = await supabase
        .from('device_tokens')
        .select('token, platform')
        .eq('user_id', payload.userId)
        .eq('audience', payload.audience);

    if (error || !data) {
        return { sent: 0, skipped: 0 };
    }

    let sent = 0;
    let skipped = 0;

    for (const entry of data as DeviceToken[]) {
        let ok = false;
        if (entry.platform === 'ios') {
            ok = await sendApns(entry.token, payload);
            if (!ok && FCM_SERVER_KEY) {
                ok = await sendFcm(entry.token, payload);
            }
        } else {
            ok = await sendFcm(entry.token, payload);
        }

        if (ok) {
            sent += 1;
        } else {
            skipped += 1;
        }
    }

    return { sent, skipped };
};
