import { FastifyRequest, FastifyReply } from 'fastify';
import { supabase } from '../services/supabase';

export const getSpendingAnalytics = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;

    const { data: orders, error } = await supabase
        .from('orders')
        .select('id, total_amount, discount_amount, created_at, vendor_id, vendors(name)')
        .eq('user_id', user.sub)
        .eq('status', 'completed')
        .order('created_at', { ascending: false });

    if (error) throw error;

    const allOrders = orders ?? [];

    // Weekly aggregation (last 8 weeks)
    const weeklyMap = new Map<string, number>();
    // Monthly aggregation
    const monthlyMap = new Map<string, number>();
    // Per-vendor aggregation
    const vendorMap = new Map<string, { vendor_id: string; vendor_name: string; total: number; count: number }>();

    let totalSpent = 0;

    for (const order of allOrders) {
        const net = Number((order as any).total_amount ?? 0) - Number((order as any).discount_amount ?? 0);
        totalSpent += net;

        const date = new Date((order as any).created_at);

        // Monthly key
        const monthKey = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
        monthlyMap.set(monthKey, (monthlyMap.get(monthKey) ?? 0) + net);

        // Week key (ISO week — Sunday-anchored)
        const weekStart = new Date(date);
        weekStart.setDate(date.getDate() - date.getDay());
        const weekKey = weekStart.toISOString().split('T')[0];
        weeklyMap.set(weekKey, (weeklyMap.get(weekKey) ?? 0) + net);

        // Vendor
        const vendorId = (order as any).vendor_id;
        const vendorName = (order as any).vendors?.name ?? 'Unknown';
        if (!vendorMap.has(vendorId)) {
            vendorMap.set(vendorId, { vendor_id: vendorId, vendor_name: vendorName, total: 0, count: 0 });
        }
        const v = vendorMap.get(vendorId)!;
        v.total += net;
        v.count += 1;
    }

    const weekly = Array.from(weeklyMap.entries())
        .map(([week, total]) => ({ week, total: Math.round(total * 100) / 100 }))
        .sort((a, b) => a.week.localeCompare(b.week))
        .slice(-8);

    const monthly = Array.from(monthlyMap.entries())
        .map(([month, total]) => ({ month, total: Math.round(total * 100) / 100 }))
        .sort((a, b) => a.month.localeCompare(b.month));

    const top_vendors = Array.from(vendorMap.values())
        .sort((a, b) => b.total - a.total)
        .slice(0, 5)
        .map(v => ({ ...v, total: Math.round(v.total * 100) / 100 }));

    return reply.send({
        weekly,
        monthly,
        top_vendors,
        total_spent: Math.round(totalSpent * 100) / 100,
    });
};

export const getVendorBreakdown = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const { data: orders, error } = await supabase
        .from('orders')
        .select('total_amount, discount_amount, vendor_id, vendors(name), created_at')
        .eq('user_id', user.sub)
        .eq('status', 'completed');
    if (error) throw error;
    const vendorMap = new Map<string, { vendor_id: string; vendor_name: string; total: number; count: number; last_order: string }>();
    for (const order of orders ?? []) {
        const vendorId = (order as any).vendor_id;
        const vendorName = (order as any).vendors?.name ?? 'Unknown';
        const net = Number((order as any).total_amount ?? 0) - Number((order as any).discount_amount ?? 0);
        if (!vendorMap.has(vendorId)) {
            vendorMap.set(vendorId, { vendor_id: vendorId, vendor_name: vendorName, total: 0, count: 0, last_order: (order as any).created_at });
        }
        const v = vendorMap.get(vendorId)!;
        v.total += net;
        v.count += 1;
        if ((order as any).created_at > v.last_order) v.last_order = (order as any).created_at;
    }
    return reply.send({ vendors: Array.from(vendorMap.values()).sort((a, b) => b.total - a.total) });
};
