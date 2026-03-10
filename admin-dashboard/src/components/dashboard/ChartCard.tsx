import React from 'react';
import {
    BarChart,
    Bar,
    XAxis,
    YAxis,
    CartesianGrid,
    Tooltip,
    ResponsiveContainer,
    AreaChart,
    Area
} from 'recharts';

interface ChartCardProps {
    title: string;
    data: any[];
    isArea?: boolean;
}

const ChartCard: React.FC<ChartCardProps> = ({ title, data, isArea = false }) => (
    <div className="bg-white p-8 rounded-3xl border border-gray-100 shadow-sm">
        <div className="flex items-center justify-between mb-8">
            <h3 className="text-xl font-black tracking-tight underline decoration-teal-500 decoration-4">{title}</h3>
            <select className="bg-gray-50 border-none rounded-xl text-xs font-bold px-4 py-2 focus:ring-0">
                <option>Last 7 Days</option>
            </select>
        </div>
        <div className="h-80 w-full">
            <ResponsiveContainer width="100%" height="100%">
                {isArea ? (
                    <AreaChart data={data}>
                        <defs>
                            <linearGradient id="colorRev" x1="0" y1="0" x2="0" y2="1">
                                <stop offset="5%" stopColor="#0d9488" stopOpacity={0.1} />
                                <stop offset="95%" stopColor="#0d9488" stopOpacity={0} />
                            </linearGradient>
                        </defs>
                        <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f3f4f6" />
                        <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fill: '#9ca3af', fontSize: 10, fontWeight: 'bold' }} dy={10} />
                        <Tooltip contentStyle={{ borderRadius: '16px', border: 'none' }} />
                        <Area type="monotone" dataKey="revenue" stroke="#0d9488" strokeWidth={4} fillOpacity={1} fill="url(#colorRev)" />
                    </AreaChart>
                ) : (
                    <BarChart data={data}>
                        <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f3f4f6" />
                        <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fill: '#9ca3af', fontSize: 10, fontWeight: 'bold' }} dy={10} />
                        <YAxis axisLine={false} tickLine={false} tick={{ fill: '#9ca3af', fontSize: 10, fontWeight: 'bold' }} />
                        <Tooltip contentStyle={{ borderRadius: '16px', border: 'none' }} cursor={{ fill: '#f0fdfa' }} />
                        <Bar dataKey="orders" fill="#0d9488" radius={[6, 6, 0, 0]} barSize={40} />
                    </BarChart>
                )}
            </ResponsiveContainer>
        </div>
    </div>
);

export default ChartCard;
