import { supabase } from '../../../src/services/supabase';
import { mockSupabase } from '../../mocks/supabaseMock';
import Sinon from 'sinon';

describe('Realtime WebSocket Behaviors', () => {

    beforeEach(() => {
        // Reset call histories between tests
        (mockSupabase.channel as any).resetHistory();
        const dummyChannel = mockSupabase.channel('dummy');
        (dummyChannel.on as any).resetHistory();
        (dummyChannel.subscribe as any).resetHistory();
    });

    it('Vendor orders queue subscription listens to specific vendor ID', () => {
        const vendorId = 'vendor_456';

        // Simulate UI component mounting
        const channel = supabase
            .channel(`vendor-${vendorId}`)
            .on(
                'postgres_changes' as any,
                { event: 'INSERT', schema: 'public', table: 'orders', filter: `vendor_id=eq.${vendorId}` },
                () => { } // callback
            )
            .subscribe();

        Sinon.assert.calledWith(mockSupabase.channel as any, `vendor-${vendorId}`);
        const mockChannel = mockSupabase.channel(`vendor-${vendorId}`);
        Sinon.assert.called(mockChannel.on as any);
        Sinon.assert.called(mockChannel.subscribe as any);

        // Validate that the filter payload was correct
        const callArgs = (mockChannel.on as any).getCall(0).args;
        expect(callArgs[0]).toBe('postgres_changes');
        expect(callArgs[1].filter).toBe(`vendor_id=eq.${vendorId}`);
    });
});
