import Razorpay from 'razorpay';
import 'dotenv/config';

export const razorpay = new Razorpay({
    key_id: (process.env.RAZORPAY_KEY_ID || '').trim(),
    key_secret: (process.env.RAZORPAY_KEY_SECRET || '').trim(),
});
