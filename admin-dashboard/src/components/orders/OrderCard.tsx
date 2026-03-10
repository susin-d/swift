import React, { useState, useEffect } from 'react';
import { Clock, CheckCircle2, XCircle, AlertTriangle } from 'lucide-react';

interface OrderCardProps {
    order: any;
    onUpdateStatus: (orderId: string, status: string) => void;
}

const OrderCard: React.FC<OrderCardProps> = ({ order, onUpdateStatus }) => {
    const [elapsedMinutes, setElapsedMinutes] = useState(0);

    useEffect(() => {
        const calculateElapsed = () => {
            const created = new Date(order.created_at).getTime();
            const now = new Date().getTime();
            setElapsedMinutes(Math.floor((now - created) / 60000));
        };

        calculateElapsed();
        const interval = setInterval(calculateElapsed, 10000);
        return () => clearInterval(interval);
    }, [order.created_at]);

    const isUrgent = elapsedMinutes >= 20;
    const isDelayed = elapsedMinutes >= 10 && elapsedMinutes < 20;

    const borderColor = isUrgent ? 'border-red-500' : isDelayed ? 'border-amber-500' : 'border-gray-100';
    const accentColor = isUrgent ? 'bg-red-500' : isDelayed ? 'bg-amber-500' : 'bg-teal-500';

    return (
        <div className={`bg-white p-8 rounded-[40px] border-2 transition-all duration-500 relative overflow-hidden group shadow-sm hover:shadow-2xl ${borderColor} ${isUrgent ? 'animate-pulse' : ''}`}>
            <div className={`absolute top-0 left-0 w-3 h-full ${accentColor}`}></div>

            <div className="flex justify-between items-start mb-6">
                <div>
                    <h3 className="font-black text-2xl text-gray-900 tracking-tighter">#{order.id.slice(0, 6).toUpperCase()}</h3>
                    <div className="flex items-center gap-2 mt-1">
                        <Clock size={14} className={isUrgent ? 'text-red-500' : 'text-gray-400'} />
                        <span className={`text-sm font-black uppercase tracking-widest ${isUrgent ? 'text-red-600' : 'text-gray-500'}`}>
                            {elapsedMinutes}m elapsed
                        </span>
                    </div>
                </div>
                <div className="flex flex-col items-end gap-2">
                    <span className={`px-4 py-1.5 rounded-2xl text-[10px] font-black uppercase tracking-widest ${order.status === 'pending' ? 'bg-amber-100 text-amber-700' :
                        order.status === 'preparing' ? 'bg-teal-100 text-teal-700' :
                            'bg-green-100 text-green-700'
                        }`}>
                        {order.status}
                    </span>
                    {isUrgent && (
                        <span className="flex items-center gap-1 text-[10px] font-black text-red-600 uppercase tracking-widest animate-bounce">
                            <AlertTriangle size={12} /> High Priority
                        </span>
                    )}
                </div>
            </div>

            <div className="space-y-4 mb-8 bg-gray-50 p-6 rounded-3xl border border-gray-100 shadow-inner">
                {order.order_items?.map((item: any) => (
                    <div key={item.id} className="flex justify-between items-center">
                        <div className="flex items-center gap-4">
                            <span className="w-8 h-8 bg-white rounded-xl flex items-center justify-center font-black text-gray-900 shadow-sm border border-gray-100">
                                {item.quantity}
                            </span>
                            <span className="text-gray-900 font-black text-lg tracking-tight">
                                {item.menu_items?.name}
                            </span>
                        </div>
                    </div>
                ))}
            </div>

            <div className="flex items-center justify-between mt-auto pt-4 border-t border-gray-50">
                <div className="flex gap-3 w-full">
                    {order.status === 'pending' && (
                        <button
                            onClick={() => onUpdateStatus(order.id, 'preparing')}
                            className="flex-1 py-5 bg-teal-600 text-white rounded-2xl font-black text-xs uppercase tracking-widest shadow-xl shadow-teal-600/30 hover:bg-teal-700 transition-all flex items-center justify-center gap-3"
                        >
                            <CheckCircle2 size={20} /> Start Prep
                        </button>
                    )}
                    {order.status === 'preparing' && (
                        <button
                            onClick={() => onUpdateStatus(order.id, 'ready')}
                            className="flex-1 py-5 bg-green-600 text-white rounded-2xl font-black text-xs uppercase tracking-widest shadow-xl shadow-green-600/30 hover:bg-green-700 transition-all flex items-center justify-center gap-3"
                        >
                            <CheckCircle2 size={20} /> Mark Ready
                        </button>
                    )}
                    <button className="p-5 bg-gray-50 text-gray-400 rounded-2xl hover:bg-red-100 hover:text-red-500 transition-all">
                        <XCircle size={24} />
                    </button>
                </div>
            </div>
        </div>
    );
};

export default OrderCard;
