import { supabase } from './supabase';
import { sendPushNotification } from './pushService';

export type NotificationAudience = 'user' | 'vendor' | 'admin';

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
