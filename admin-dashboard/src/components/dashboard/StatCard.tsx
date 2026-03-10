import React from 'react';
import { ArrowUpRight } from 'lucide-react';

interface StatCardProps {
    title: string;
    value: string | number;
    icon: React.ReactNode;
    trend?: string;
    isDark?: boolean;
}

const StatCard: React.FC<StatCardProps> = ({ title, value, icon, trend, isDark = false }) => (
    <div className={`${isDark ? 'bg-gray-900 text-white shadow-teal-900/20' : 'bg-white text-gray-900 border-gray-100 shadow-sm'} p-8 rounded-3xl border shadow-sm hover:shadow-xl hover:-translate-y-1 transition-all group overflow-hidden relative`}>
        {!isDark && <div className="absolute -right-4 -top-4 w-24 h-24 bg-teal-50 rounded-full blur-3xl group-hover:bg-teal-100 transition-all"></div>}
        <div className="flex justify-between items-start mb-6 relative z-10">
            <div className={`p-3 ${isDark ? 'bg-teal-600' : 'bg-teal-50 text-teal-600'} rounded-2xl`}>
                {icon}
            </div>
            {trend && (
                <span className="flex items-center gap-1 text-green-500 text-xs font-black">
                    <ArrowUpRight size={14} /> {trend}
                </span>
            )}
        </div>
        <h3 className={`${isDark ? 'text-gray-400' : 'text-gray-400'} font-bold text-sm mb-1 uppercase tracking-tight relative z-10`}>{title}</h3>
        <p className="text-4xl font-black relative z-10">{value}</p>
    </div>
);

export default StatCard;
