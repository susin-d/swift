import React from 'react';
import OrderCard from '../components/orders/OrderCard';
import EmptyState from '../components/common/EmptyState';
import { ClipboardList } from 'lucide-react';

interface OrdersProps {
    orders: any[];
    handleUpdateStatus: (id: string, status: string) => void;
}

const Orders: React.FC<OrdersProps> = ({ orders, handleUpdateStatus }) => {
    return (
        <div className="p-10 space-y-8">
            <div className="flex items-center justify-between">
                <div>
                    <h2 className="text-3xl font-black text-gray-900 tracking-tight">Live Order Board</h2>
                    <p className="text-gray-500 font-bold mt-1">Manage and track active student orders</p>
                </div>
                <div className="flex gap-4">
                    <div className="bg-white px-6 py-3 rounded-2xl border border-gray-100 shadow-sm flex items-center gap-3">
                        <div className="w-2 h-2 rounded-full bg-amber-500 animate-pulse"></div>
                        <span className="text-xs font-black uppercase tracking-widest text-gray-400">
                            {orders.filter(o => o.status === 'pending').length} Pending
                        </span>
                    </div>
                    <div className="bg-white px-6 py-3 rounded-2xl border border-gray-100 shadow-sm flex items-center gap-3">
                        <div className="w-2 h-2 rounded-full bg-teal-500 animate-pulse"></div>
                        <span className="text-xs font-black uppercase tracking-widest text-gray-400">
                            {orders.filter(o => o.status === 'preparing').length} Preparing
                        </span>
                    </div>
                </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-8">
                {orders.map(order => (
                    <OrderCard key={order.id} order={order} onUpdateStatus={handleUpdateStatus} />
                ))}
                {orders.length === 0 && (
                    <EmptyState icon={<ClipboardList size={48} />} message="No active orders at the moment" />
                )}
            </div>
        </div>
    );
};

export default Orders;
