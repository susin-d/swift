import React from 'react';
import { TrendingUp, DollarSign, Users, ShoppingCart, ArrowUpRight, ArrowDownRight } from 'lucide-react';
import {
    AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
    BarChart, Bar, Legend, PieChart, Pie, Cell
} from 'recharts';
import StatCard from '../components/dashboard/StatCard';
import { useAuth } from '../context/AuthContext';

const COLORS = ['#0d9488', '#0f766e', '#115e59', '#134e4a', '#14b8a6'];

const data = [
    { name: 'Mon', revenue: 4000, orders: 240, users: 2400 },
    { name: 'Tue', revenue: 3000, orders: 139, users: 2210 },
    { name: 'Wed', revenue: 2000, orders: 980, users: 2290 },
    { name: 'Thu', revenue: 2780, orders: 390, users: 2000 },
    { name: 'Fri', revenue: 1890, orders: 480, users: 2181 },
    { name: 'Sat', revenue: 2390, orders: 380, users: 2500 },
    { name: 'Sun', revenue: 3490, orders: 430, users: 2100 },
];

const pieData = [
    { name: 'South Campus', value: 400 },
    { name: 'North Campus', value: 300 },
    { name: 'East Wing', value: 300 },
    { name: 'West Block', value: 200 },
];

const Analytics: React.FC = () => {
    const { user } = useAuth();
    const isAdmin = user?.role === 'admin';

    return (
        <div className="p-10 space-y-10 pb-20">
            <div className="flex items-center justify-between">
                <div>
                    <h2 className="text-3xl font-black text-gray-900 tracking-tight">Financial Intelligence</h2>
                    <p className="text-gray-500 font-bold mt-1">Deep insights into campus commerce and trends</p>
                </div>
                <div className="flex gap-4">
                    <select className="bg-white border-gray-100 rounded-2xl text-xs font-black uppercase tracking-widest px-6 py-4 shadow-sm focus:ring-teal-500">
                        <option>Last 30 Days</option>
                        <option>Last 90 Days</option>
                        <option>All Time</option>
                    </select>
                    <button className="px-8 py-4 bg-gray-900 text-white rounded-2xl font-black shadow-xl hover:bg-teal-700 transition-all flex items-center gap-2">
                        Export Report
                    </button>
                </div>
            </div>

            {/* Stats Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
                <StatCard title="Average Order Value" value="₹184" icon={<DollarSign size={24} />} trend="+5.4%" />
                <StatCard title="Conversion Rate" value="3.2%" icon={<TrendingUp size={24} />} trend="+1.2%" />
                <StatCard title="New Customers" value="842" icon={<Users size={24} />} trend="+18%" />
                <StatCard title="Repeat Orders" value="64%" icon={<ShoppingCart size={24} />} trend="-2%" />
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-10">
                {/* Revenue Area Chart */}
                <div className="bg-white p-8 rounded-[40px] border border-gray-100 shadow-sm">
                    <h3 className="text-xl font-black mb-8 underline decoration-teal-500 decoration-4">Revenue Growth</h3>
                    <div className="h-80">
                        <ResponsiveContainer width="100%" height="100%">
                            <AreaChart data={data}>
                                <defs>
                                    <linearGradient id="colorRev2" x1="0" y1="0" x2="0" y2="1">
                                        <stop offset="5%" stopColor="#0d9488" stopOpacity={0.1} />
                                        <stop offset="95%" stopColor="#0d9488" stopOpacity={0} />
                                    </linearGradient>
                                </defs>
                                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f3f4f6" />
                                <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fill: '#9ca3af', fontSize: 10, fontWeight: 'bold' }} />
                                <YAxis axisLine={false} tickLine={false} tick={{ fill: '#9ca3af', fontSize: 10, fontWeight: 'bold' }} />
                                <Tooltip contentStyle={{ borderRadius: '16px', border: 'none' }} />
                                <Area type="monotone" dataKey="revenue" stroke="#0d9488" strokeWidth={4} fillOpacity={1} fill="url(#colorRev2)" />
                            </AreaChart>
                        </ResponsiveContainer>
                    </div>
                </div>

                {/* Order Volume Bar Chart */}
                <div className="bg-white p-8 rounded-[40px] border border-gray-100 shadow-sm">
                    <h3 className="text-xl font-black mb-8 underline decoration-amber-500 decoration-4">Order Frequency</h3>
                    <div className="h-80">
                        <ResponsiveContainer width="100%" height="100%">
                            <BarChart data={data}>
                                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f3f4f6" />
                                <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fill: '#9ca3af', fontSize: 10, fontWeight: 'bold' }} />
                                <Tooltip contentStyle={{ borderRadius: '16px', border: 'none' }} cursor={{ fill: '#f0fdfa' }} />
                                <Bar dataKey="orders" fill="#f59e0b" radius={[6, 6, 0, 0]} barSize={40} />
                            </BarChart>
                        </ResponsiveContainer>
                    </div>
                </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-10">
                {/* Pie Chart for Regional Distribution */}
                <div className="bg-white p-8 rounded-[40px] border border-gray-100 shadow-sm flex flex-col items-center">
                    <h3 className="text-xl font-black mb-8 self-start">Regional Distribution</h3>
                    <div className="h-64 w-full">
                        <ResponsiveContainer width="100%" height="100%">
                            <PieChart>
                                <Pie data={pieData} innerRadius={60} outerRadius={80} paddingAngle={5} dataKey="value">
                                    {pieData.map((_, index) => (
                                        <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                                    ))}
                                </Pie>
                                <Tooltip />
                                <Legend iconType="circle" />
                            </PieChart>
                        </ResponsiveContainer>
                    </div>
                </div>

                {/* Top Selling Items Table - Simplified */}
                <div className="lg:col-span-2 bg-white p-8 rounded-[40px] border border-gray-100 shadow-sm">
                    <h3 className="text-xl font-black mb-8">Performance Ranking</h3>
                    <div className="space-y-6">
                        {[1, 2, 3].map(i => (
                            <div key={i} className="flex items-center justify-between p-4 hover:bg-gray-50 rounded-2xl transition-all">
                                <div className="flex items-center gap-4">
                                    <div className="w-12 h-12 bg-teal-50 text-teal-600 rounded-xl flex items-center justify-center font-black">#{i}</div>
                                    <div>
                                        <p className="font-black text-gray-900">{i === 1 ? 'Chicken 65' : i === 2 ? 'Veg Biryani' : 'Cold Coffee'}</p>
                                        <p className="text-[10px] font-black text-gray-400 uppercase tracking-widest">Main Course</p>
                                    </div>
                                </div>
                                <div className="text-right">
                                    <p className="font-black text-gray-900">₹{24000 - i * 5000}</p>
                                    <p className="text-xs text-green-500 font-bold flex items-center gap-1 justify-end">
                                        <ArrowUpRight size={12} /> {15 - i * 2}%
                                    </p>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Analytics;
