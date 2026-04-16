import { supabase } from '../../../src/services/supabase';
import { razorpay } from '../../../src/services/razorpay';

describe('Backend Services', () => {
    it('should initialize Supabase client', () => {
        expect(supabase).toBeDefined();
        expect(typeof supabase.from).toBe('function');
        expect(typeof supabase.auth).toBe('object');
    });

    it('should initialize Razorpay client', () => {
        expect(razorpay).toBeDefined();
        expect(typeof razorpay.orders).toBe('object');
        expect(typeof razorpay.payments).toBe('object');
    });
});
