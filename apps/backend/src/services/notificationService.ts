import { supabase } from './supabase';
import { sendPushNotification } from './pushService';

export type NotificationAudience = 'user' | 'vendor' | 'admin';
export type BroadcastAudience = 'user' | 'vendor' | 'both';

type BroadcastNotificationInput = {
    audience?: BroadcastAudience;
    type?: string;
    title: string;
    body: string;
    metadata?: Record<string, any> | null;
};

export const resolveAudience = (role?: string): NotificationAudience => {
    if (role === 'vendor') return 'vendor';
    if (role === 'admin') return 'admin';
    return 'user';
};

export const createNotification = async ({
    userId,
    audience = 'user',
    type = 'general',
    title,
    body,
    metadata = null,
}: {
    userId: string;
    audience?: NotificationAudience;
    type?: string;
    title: string;
    body: string;
    metadata?: Record<string, any> | null;
}) => {
    const { data, error } = await supabase
        .from('notifications')
        .insert({
            user_id: userId,
            audience,
            type,
            title,
            body,
            metadata,
        })
        .select()
        .single();

    if (error) throw error;

    try {
        await sendPushNotification({
            userId,
            audience,
            title,
            body,
            metadata,
        });
    } catch (pushError) {
        console.warn('Push notification failed', pushError);
    }

    return data;
};

const resolveBroadcastAudiences = (audience: BroadcastAudience = 'both'): Array<'user' | 'vendor'> => {
    if (audience === 'user' || audience === 'vendor') {
        return [audience];
    }

    return ['user', 'vendor'];
};

const listRecipientIdsForAudience = async (audience: 'user' | 'vendor') => {
    const { data, error } = await supabase
        .from('users')
        .select('id')
        .eq('role', audience);

    if (error) throw error;

    return (data || [])
        .map((row: any) => row?.id?.toString?.() || '')
        .filter((id: string) => id.length > 0);
};

export const broadcastNotification = async ({
    audience = 'both',
    type = 'general',
    title,
    body,
    metadata = null,
}: BroadcastNotificationInput) => {
    const audiences = resolveBroadcastAudiences(audience);
    const recipients: Array<{ userId: string; audience: 'user' | 'vendor' }> = [];

    for (const targetAudience of audiences) {
        const recipientIds = await listRecipientIdsForAudience(targetAudience);
        for (const userId of recipientIds) {
            recipients.push({ userId, audience: targetAudience });
        }
    }

    const results = await Promise.allSettled(
        recipients.map((recipient) =>
            createNotification({
                userId: recipient.userId,
                audience: recipient.audience,
                type,
                title,
                body,
                metadata,
            }),
        ),
    );

    const sent = results.filter((result) => result.status === 'fulfilled').length;
    const failed = results.length - sent;

    return {
        audiences,
        recipients: results.length,
        sent,
        failed,
    };
};
