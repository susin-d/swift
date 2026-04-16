jest.mock('../../../src/services/notificationService', () => ({
    broadcastNotification: jest.fn(),
}));

import { broadcastNotification } from '../../../src/services/notificationService';
import { sendBroadcastNotification } from '../../../src/controllers/adminNotificationController';

describe('adminNotificationController', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    it('broadcasts notifications to the selected audience', async () => {
        (broadcastNotification as jest.Mock).mockResolvedValue({
            audiences: ['user', 'vendor'],
            recipients: 8,
            sent: 8,
            failed: 0,
        });

        const reply: any = { code: jest.fn().mockReturnThis(), send: jest.fn() };
        const request: any = {
            body: {
                title: 'Service update',
                body: 'Lunch service is running 10 minutes late.',
                audience: 'both',
                type: 'service_update',
                metadata: { source: 'admin_web' },
            },
        };

        await sendBroadcastNotification(request, reply);

        expect(broadcastNotification).toHaveBeenCalledWith({
            title: 'Service update',
            body: 'Lunch service is running 10 minutes late.',
            audience: 'both',
            type: 'service_update',
            metadata: { source: 'admin_web' },
        });
        expect(reply.code).toHaveBeenCalledWith(201);
        expect(reply.send).toHaveBeenCalledWith({
            message: 'Notification sent to users and vendors',
            audiences: ['user', 'vendor'],
            recipients: 8,
            sent: 8,
            failed: 0,
        });
    });

    it('rejects empty notification content', async () => {
        const reply: any = { code: jest.fn().mockReturnThis(), send: jest.fn() };

        await expect(
            sendBroadcastNotification({ body: { title: ' ', body: ' ' } } as any, reply),
        ).rejects.toMatchObject({ statusCode: 400, message: 'Title and body are required' });
    });
});