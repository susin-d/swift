import React from 'react';
import { Navigation, Shield } from 'lucide-react';

const hotspots = [
    { id: 1, name: 'Main Canteen', x: 25, y: 30, value: 85, trend: '+12%' },
    { id: 2, name: 'South Block Cafe', x: 65, y: 75, value: 42, trend: '-5%' },
    { id: 3, name: 'Library Plaza', x: 45, y: 55, value: 124, trend: '+45%' },
    { id: 4, name: 'Techno Park Food Court', x: 80, y: 20, value: 67, trend: '+8%' },
];

const CampusMap: React.FC = () => {
    return (
        <div className="p-10 space-y-10 pb-20">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div>
                    <h2 className="text-3xl font-black text-gray-900 tracking-tight text-transparent bg-clip-text bg-gradient-to-r from-teal-600 to-indigo-600">Live Campus Pulse</h2>
                    <p className="text-gray-500 font-bold mt-1">Geospatial visualization of ordering activity and logistics</p>
                </div>
                <div className="flex gap-4">
                    <div className="bg-white px-6 py-3 rounded-2xl border border-gray-100 shadow-sm flex items-center gap-3">
                        <div className="w-2 h-2 rounded-full bg-green-500 animate-ping"></div>
                        <span className="text-xs font-black uppercase tracking-widest text-teal-600">Live Feed Active</span>
                    </div>
                    <button className="px-8 py-4 bg-gray-900 text-white rounded-2xl font-black shadow-xl hover:bg-teal-700 transition-all flex items-center gap-2">
                        <Shield size={18} /> Zone Controls
                    </button>
                </div>
            </div>

            <div className="grid grid-cols-1 xl:grid-cols-4 gap-10">
                {/* Map Visualization */}
                <div className="xl:col-span-3 bg-white p-4 rounded-[48px] border-8 border-gray-50 shadow-inner relative min-h-[600px] overflow-hidden group">
                    {/* Mock Map Background */}
                    <div className="absolute inset-0 bg-[url('https://images.unsplash.com/photo-1524813686514-a57345688048?auto=format&fit=crop&q=80&w=2000')] bg-cover opacity-10 grayscale group-hover:grayscale-0 transition-all duration-1000"></div>

                    {/* Grid Overlay */}
                    <div className="absolute inset-0 grid grid-cols-12 grid-rows-12 pointer-events-none opacity-20">
                        {Array.from({ length: 144 }).map((_, i) => (
                            <div key={i} className="border border-white/40"></div>
                        ))}
                    </div>

                    {/* Hotspots */}
                    {hotspots.map(spot => (
                        <div
                            key={spot.id}
                            className="absolute cursor-pointer group/pin"
                            style={{ left: `${spot.x}%`, top: `${spot.y}%` }}
                        >
                            <div className="relative">
                                <div className="absolute -inset-8 bg-teal-400/20 rounded-full animate-ping"></div>
                                <div className="w-6 h-6 bg-teal-600 rounded-full border-4 border-white shadow-xl relative z-10 hover:scale-150 transition-all duration-300"></div>

                                {/* Info Card */}
                                <div className="absolute bottom-full mb-4 left-1/2 -translate-x-1/2 w-48 bg-white p-4 rounded-2xl shadow-2xl opacity-0 group-hover/pin:opacity-100 transition-all pointer-events-none z-50">
                                    <p className="font-black text-gray-900 text-sm">{spot.name}</p>
                                    <p className="text-[10px] font-black text-teal-600 uppercase tracking-widest mt-1">{spot.value} Active Orders</p>
                                    <div className="h-1 w-full bg-gray-100 mt-3 rounded-full overflow-hidden">
                                        <div className="h-full bg-teal-500" style={{ width: `${(spot.value / 150) * 100}%` }}></div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    ))}
                </div>

                {/* Sidebar Stats */}
                <div className="space-y-8">
                    <div className="bg-white p-8 rounded-[40px] border border-gray-100 shadow-sm">
                        <h3 className="text-xl font-black mb-6">Heatmap Summary</h3>
                        <div className="space-y-6">
                            {hotspots.map(spot => (
                                <div key={spot.id} className="flex items-center justify-between">
                                    <div className="flex items-center gap-3">
                                        <div className="w-2 h-2 rounded-full bg-teal-500"></div>
                                        <p className="text-sm font-bold text-gray-700">{spot.name}</p>
                                    </div>
                                    <span className={`text-xs font-black ${spot.trend.startsWith('+') ? 'text-green-500' : 'text-red-500'}`}>
                                        {spot.trend}
                                    </span>
                                </div>
                            ))}
                        </div>
                    </div>

                    <div className="bg-gray-900 p-8 rounded-[40px] text-white space-y-6">
                        <div className="flex items-center gap-4">
                            <div className="p-3 bg-teal-600 rounded-2xl">
                                <Navigation size={20} />
                            </div>
                            <div>
                                <p className="text-[10px] font-black text-teal-400 uppercase tracking-widest">Global Density</p>
                                <p className="text-2xl font-black">High Activity</p>
                            </div>
                        </div>
                        <p className="text-xs text-gray-400 font-bold leading-relaxed">
                            Main Canteen and Library Plaza are experiencing peak load. Suggesting bandwidth redirection for delivery partners.
                        </p>
                        <button className="w-full py-4 bg-teal-600 rounded-2xl font-black text-xs uppercase tracking-widest hover:bg-teal-500 transition-all">
                            Manage Logistics
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default CampusMap;
