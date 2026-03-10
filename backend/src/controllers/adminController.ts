import { FastifyRequest, FastifyReply } from 'fastify';
import { supabase } from '../services/supabase';

export const getGlobalStats = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
        const { count: userCount } = await supabase.from('users').select('*', { count: 'exact', head: true });
        const { count: vendorCount } = await supabase.from('vendors').select('*', { count: 'exact', head: true });
        const { count: orderCount } = await supabase.from('orders').select('*', { count: 'exact', head: true });

        // Calculate GMV (Gross Merchandise Value) from completed orders
        const { data: orders } = await supabase
            .from('orders')
            .select('total_amount')
            .eq('status', 'completed');

        const gmv = orders?.reduce((sum, order) => sum + Number(order.total_amount), 0) || 0;

        return reply.send({
            stats: {
                users: userCount || 0,
                vendors: vendorCount || 0,
                orders: orderCount || 0,
                gmv: gmv
            }
        });
    } catch (err: any) {
        console.error('getGlobalStats error:', err);
        throw err;
    }
};

export const getChartData = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
        // Fetch last 7 days of data
        const { data: orders, error } = await supabase
            .from('orders')
            .select('created_at, total_amount, status')
            .gte('created_at', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString())
            .order('created_at', { ascending: true });

        if (error) throw error;

        // Group by day of week
        const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        const chartData = days.map(day => ({ name: day, orders: 0, revenue: 0 }));

        orders?.forEach(order => {
            const dayName = days[new Date(order.created_at).getDay()];
            const dayObj = chartData.find(d => d.name === dayName);
            if (dayObj) {
                dayObj.orders += 1;
                if (order.status === 'completed') {
                    dayObj.revenue += Number(order.total_amount);
                }
            }
        });

        // Rotate so current day is at the end
        const todayIdx = new Date().getDay();
        const rotatedData = [
            ...chartData.slice(todayIdx + 1),
            ...chartData.slice(0, todayIdx + 1)
        ];

        return reply.send({ chartData: rotatedData });
    } catch (err: any) {
        console.error('getChartData error:', err);
        throw err;
    }
};

export const getPendingVendors = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
        // Falling back to all vendors since 'status' column is missing in DB
        // TODO: Add 'status' column to 'vendors' table to enable verification flow
        const { data, error } = await supabase
            .from('vendors')
            .select('*, owner:users(name, email)')
            .order('created_at', { ascending: false });

        if (error) throw error;

        return reply.send({ vendors: data });
    } catch (err: any) {
        console.error('getPendingVendors error:', err);
        throw err; // Caught by global error handler
    }
};

export const approveVendor = async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as { id: string };

    try {
        // This will fail since 'status' column is missing, but it will be caught safely now
        const { error } = await supabase
            .from('vendors')
            .update({ status: 'approved' } as any)
            .eq('id', id);

        if (error) throw error;

        return reply.send({ message: `Vendor ${id} approved successfully` });
    } catch (err: any) {
        console.error('approveVendor error:', err);
        throw err; // Caught by global error handler
    }
};
export const updateUserRole = async (request: FastifyRequest, reply: FastifyReply) => {
    const { userId, role } = request.body as { userId: string, role: string };

    if (!['user', 'vendor', 'admin'].includes(role)) {
        const err = new Error('Invalid role specified') as any;
        err.statusCode = 400;
        throw err;
    }

    try {
        // Update public.users table
        const { error: profileError } = await supabase
            .from('users')
            .update({ role })
            .eq('id', userId);

        if (profileError) throw profileError;

        // Update auth.users metadata for consistency
        const { error: authError } = await supabase.auth.admin.updateUserById(
            userId,
            { user_metadata: { role } }
        );

        if (authError) {
            console.error('Auth metadata sync failed (non-fatal):', authError);
            // We still proceed since public.users is the source of truth for our app RBAC
        }

        return reply.send({ message: `User ${userId} role updated to ${role} successfully` });
    } catch (err: any) {
        console.error('updateUserRole error:', err);
        throw err;
    }
};
export const createVendorAccount = async (request: FastifyRequest, reply: FastifyReply) => {
    const { email, password, name, description, image_url } = request.body as any;

    if (!email || !password || !name) {
        const err = new Error('Email, password, and name are required') as any;
        err.statusCode = 400;
        throw err;
    }

    try {
        // 1. Create Supabase Auth User
        const { data: authData, error: authError } = await supabase.auth.admin.createUser({
            email,
            password,
            email_confirm: true,
            user_metadata: { name, role: 'vendor' }
        });

        if (authError) throw authError;

        const userId = authData.user.id;

        // 2. Create public.users record
        const { error: userError } = await supabase
            .from('users')
            .insert({
                id: userId,
                name,
                email,
                role: 'vendor'
            });

        if (userError) throw userError;

        // 3. Create public.vendors record
        const { data: vendorData, error: vendorError } = await supabase
            .from('vendors')
            .insert({
                owner_id: userId,
                name,
                description,
                image_url,
                is_open: true
            })
            .select()
            .single();

        if (vendorError) throw vendorError;

        return reply.code(201).send({
            message: 'Vendor account created successfully',
            vendor: vendorData,
            userId: userId
        });
    } catch (err: any) {
        console.error('createVendorAccount error:', err);
        throw err;
    }
};
