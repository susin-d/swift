import React, { useState, useEffect } from 'react';
import { Search, ShieldAlert, Award, Star, ExternalLink, Plus, X } from 'lucide-react';
import api from '../lib/api';

const Vendors: React.FC = () => {
    const [vendors, setVendors] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchQuery, setSearchQuery] = useState('');
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [newVendor, setNewVendor] = useState({
        name: '',
        email: '',
        password: '',
        description: '',
        location: ''
    });

    useEffect(() => {
        fetchVendors();
    }, []);

    const fetchVendors = async () => {
        try {
            const res = await api.get('/admin/vendors');
            setVendors(res.data.vendors);
        } catch (err) {
            console.error('Error fetching vendors:', err);
        } finally {
            setLoading(false);
        }
    };

    const handleSuspend = async (id: string, currentStatus: string) => {
        const newStatus = currentStatus === 'suspended' ? 'approved' : 'suspended';
        try {
            await api.patch(`/admin/vendors/${id}/status`, { status: newStatus });
            fetchVendors();
        } catch (err) {
            console.error('Error updating vendor status:', err);
        }
    };

    const handleCreateVendor = async (e: React.FormEvent) => {
        e.preventDefault();
        try {
            await api.post('/admin/vendors', newVendor);
            setIsModalOpen(false);
            setNewVendor({ name: '', email: '', password: '', description: '', location: '' });
            fetchVendors();
        } catch (err) {
            console.error('Error creating vendor:', err);
            alert('Failed to create vendor account');
        }
    };

    const filteredVendors = vendors.filter(v =>
        v.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        v.owner?.name?.toLowerCase().includes(searchQuery.toLowerCase())
    );

    return (
        <div className="p-10 space-y-10 pb-20 relative">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div>
                    <h2 className="text-3xl font-black text-gray-900 tracking-tight">Vendor Management</h2>
                    <p className="text-gray-500 font-bold mt-1">Audit, monitor and regulate campus stalls</p>
                </div>
                <div className="flex items-center gap-4">
                    <button
                        onClick={() => setIsModalOpen(true)}
                        className="bg-black text-white px-6 py-3 rounded-2xl font-black text-sm tracking-widest uppercase hover:bg-teal-600 transition-all flex items-center gap-2 shadow-xl shadow-black/10"
                    >
                        <Plus size={18} /> Add Vendor
                    </button>
                    <div className="bg-white px-6 py-3 rounded-2xl border border-gray-100 shadow-sm flex items-center gap-4 focus-within:ring-2 focus-within:ring-teal-500 transition-all">
                        <Search size={20} className="text-gray-400" />
                        <input
                            type="text"
                            placeholder="Search vendors..."
                            className="bg-transparent border-none focus:outline-none text-sm font-bold w-64"
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                        />
                    </div>
                </div>
            </div>

            {/* Create Vendor Modal */}
            {isModalOpen && (
                <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-6">
                    <div className="bg-white w-full max-w-lg rounded-[40px] p-10 relative shadow-2xl animate-in zoom-in duration-300">
                        <button onClick={() => setIsModalOpen(false)} className="absolute top-8 right-8 text-gray-400 hover:text-black transition-all">
                            <X size={24} />
                        </button>
                        <h3 className="text-2xl font-black text-gray-900 mb-2">New Vendor Account</h3>
                        <p className="text-gray-500 font-bold mb-8">Create an atomic auth & profile record</p>

                        <form onSubmit={handleCreateVendor} className="space-y-6">
                            <div className="space-y-2">
                                <label className="text-[10px] font-black text-gray-400 uppercase tracking-widest ml-4">Shop Name</label>
                                <input required type="text" className="w-full bg-gray-50 border-none rounded-2xl px-6 py-4 font-bold focus:ring-2 focus:ring-teal-500 transition-all"
                                    value={newVendor.name} onChange={e => setNewVendor({ ...newVendor, name: e.target.value })} />
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div className="space-y-2">
                                    <label className="text-[10px] font-black text-gray-400 uppercase tracking-widest ml-4">Email</label>
                                    <input required type="email" className="w-full bg-gray-50 border-none rounded-2xl px-6 py-4 font-bold focus:ring-2 focus:ring-teal-500 transition-all"
                                        value={newVendor.email} onChange={e => setNewVendor({ ...newVendor, email: e.target.value })} />
                                </div>
                                <div className="space-y-2">
                                    <label className="text-[10px] font-black text-gray-400 uppercase tracking-widest ml-4">Password</label>
                                    <input required type="password" placeholder="Min 6 chars" className="w-full bg-gray-50 border-none rounded-2xl px-6 py-4 font-bold focus:ring-2 focus:ring-teal-500 transition-all"
                                        value={newVendor.password} onChange={e => setNewVendor({ ...newVendor, password: e.target.value })} />
                                </div>
                            </div>
                            <div className="space-y-2">
                                <label className="text-[10px] font-black text-gray-400 uppercase tracking-widest ml-4">Location</label>
                                <input required type="text" placeholder="e.g. Near Hostel 4" className="w-full bg-gray-50 border-none rounded-2xl px-6 py-4 font-bold focus:ring-2 focus:ring-teal-500 transition-all"
                                    value={newVendor.location} onChange={e => setNewVendor({ ...newVendor, location: e.target.value })} />
                            </div>
                            <button type="submit" className="w-full bg-teal-600 text-white py-5 rounded-[24px] font-black uppercase tracking-widest hover:bg-black transition-all shadow-xl shadow-teal-600/20 active:scale-[0.98]">
                                Initialize Vendor Portal
                            </button>
                        </form>
                    </div>
                </div>
            )}

            <div className="grid grid-cols-1 gap-6">
                {loading ? (
                    [1, 2, 3].map(i => <div key={i} className="h-24 bg-white rounded-3xl border border-gray-100 animate-pulse"></div>)
                ) : (
                    filteredVendors.map(vendor => (
                        <div key={vendor.id} className="bg-white p-8 rounded-[32px] border border-gray-100 shadow-sm hover:shadow-xl transition-all flex flex-col md:flex-row md:items-center justify-between gap-8 group">
                            <div className="flex items-center gap-6">
                                <div className="w-16 h-16 bg-teal-50 text-teal-600 rounded-2xl flex items-center justify-center font-black text-2xl relative">
                                    {vendor.name?.[0]}
                                    <div className={`absolute -top-1 -right-1 w-4 h-4 rounded-full border-4 border-white ${vendor.status === 'approved' ? 'bg-green-500' : 'bg-red-500'}`}></div>
                                </div>
                                <div>
                                    <h3 className="text-xl font-black text-gray-900 tracking-tight flex items-center gap-2">
                                        {vendor.name}
                                        {vendor.is_open && <span className="px-2 py-0.5 bg-green-50 text-green-600 text-[10px] uppercase font-black rounded-lg">Online</span>}
                                    </h3>
                                    <div className="flex gap-4 mt-1">
                                        <p className="text-xs text-gray-400 font-bold uppercase tracking-widest">{vendor.owner?.name || vendor.email}</p>
                                        <p className="text-xs text-gray-400 font-bold uppercase tracking-widest border-l pl-4 border-gray-100">Joined {new Date(vendor.created_at).toLocaleDateString()}</p>
                                    </div>
                                </div>
                            </div>

                            <div className="flex items-center gap-12">
                                <div className="text-center">
                                    <p className="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1">Lifetime GMV</p>
                                    <p className="text-xl font-black text-teal-900 tracking-tighter">₹{vendor.revenue || '0.00'}</p>
                                </div>
                                <div className="text-center">
                                    <p className="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1">Rating</p>
                                    <p className="text-xl font-black text-amber-500 tracking-tighter flex items-center gap-1 leading-none">
                                        4.8 <Star size={14} fill="currentColor" />
                                    </p>
                                </div>
                                <div className="flex gap-3">
                                    <button className="p-4 bg-gray-50 text-gray-400 rounded-2xl hover:bg-teal-50 hover:text-teal-600 transition-all">
                                        <Award size={20} />
                                    </button>
                                    <button
                                        onClick={() => handleSuspend(vendor.id, vendor.status)}
                                        className={`p-4 rounded-2xl transition-all ${vendor.status === 'suspended' ? 'bg-green-50 text-green-600 hover:bg-green-100' : 'bg-red-50 text-red-500 hover:bg-red-100'}`}
                                    >
                                        <ShieldAlert size={20} />
                                    </button>
                                    <button className="p-4 bg-gray-900 text-white rounded-2xl shadow-lg hover:bg-teal-700 transition-all">
                                        <ExternalLink size={20} />
                                    </button>
                                </div>
                            </div>
                        </div>
                    ))
                )}
            </div>
        </div>
    );
};

export default Vendors;
