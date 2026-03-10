import React, { useState } from 'react';
import { Save, Image as ImageIcon, MapPin } from 'lucide-react';
import api from '../lib/api';

interface StoreSettingsProps {
    initialProfile: any;
    onUpdate: () => void;
}

const StoreSettings: React.FC<StoreSettingsProps> = ({ initialProfile, onUpdate }) => {
    const [profile, setProfile] = useState(initialProfile || {});
    const [saving, setSaving] = useState(false);

    const handleSave = async () => {
        setSaving(true);
        try {
            await api.patch('/vendor-ops/profile', profile);
            onUpdate();
        } catch (err) {
            console.error('Error saving settings:', err);
        } finally {
            setSaving(false);
        }
    };

    return (
        <div className="p-10 max-w-5xl mx-auto space-y-10 pb-20">
            <div className="flex items-center justify-between">
                <div>
                    <h2 className="text-3xl font-black text-gray-900 tracking-tight">Store Settings</h2>
                    <p className="text-gray-500 font-bold mt-1">Customize your digital storefront and branding</p>
                </div>
                <button
                    onClick={handleSave}
                    disabled={saving}
                    className="flex items-center gap-3 px-8 py-4 bg-teal-600 text-white rounded-2xl font-black shadow-xl shadow-teal-600/30 hover:bg-teal-700 transition-all disabled:opacity-50"
                >
                    {saving ? 'Saving...' : <><Save size={20} /> Save Changes</>}
                </button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-10">
                {/* Branding Section */}
                <div className="bg-white p-8 rounded-[40px] border border-gray-100 shadow-sm space-y-8">
                    <div className="flex items-center gap-4 mb-2">
                        <div className="p-3 bg-teal-50 text-teal-600 rounded-2xl">
                            <ImageIcon size={24} />
                        </div>
                        <h3 className="text-xl font-black">Branding & Identity</h3>
                    </div>

                    <div className="space-y-6">
                        <div>
                            <label className="block text-[10px] font-black uppercase tracking-widest text-gray-400 mb-2 px-1">Internal Name</label>
                            <input
                                type="text"
                                value={profile.name || ''}
                                onChange={(e) => setProfile({ ...profile, name: e.target.value })}
                                className="w-full px-6 py-4 bg-gray-50 border-none rounded-2xl font-bold focus:ring-2 focus:ring-teal-500 transition-all"
                                placeholder="The Spice Route"
                            />
                        </div>
                        <div>
                            <label className="block text-[10px] font-black uppercase tracking-widest text-gray-400 mb-2 px-1">Description</label>
                            <textarea
                                value={profile.description || ''}
                                onChange={(e) => setProfile({ ...profile, description: e.target.value })}
                                className="w-full px-6 py-4 bg-gray-50 border-none rounded-2xl font-bold focus:ring-2 focus:ring-teal-500 transition-all min-h-[120px]"
                                placeholder="What makes your stall special?"
                            />
                        </div>
                    </div>
                </div>

                {/* Location & Contact */}
                <div className="bg-white p-8 rounded-[40px] border border-gray-100 shadow-sm space-y-8">
                    <div className="flex items-center gap-4 mb-2">
                        <div className="p-3 bg-amber-50 text-amber-600 rounded-2xl">
                            <MapPin size={24} />
                        </div>
                        <h3 className="text-xl font-black">Campus Location</h3>
                    </div>

                    <div className="space-y-6">
                        <div>
                            <label className="block text-[10px] font-black uppercase tracking-widest text-gray-400 mb-2 px-1">Building / Block</label>
                            <input
                                type="text"
                                value={profile.location || ''}
                                onChange={(e) => setProfile({ ...profile, location: e.target.value })}
                                className="w-full px-6 py-4 bg-gray-50 border-none rounded-2xl font-bold focus:ring-2 focus:ring-amber-500 transition-all"
                                placeholder="South Campus, Block B"
                            />
                        </div>
                        <div className="grid grid-cols-2 gap-6">
                            <div>
                                <label className="block text-[10px] font-black uppercase tracking-widest text-gray-400 mb-2 px-1">Open Time</label>
                                <input
                                    type="time"
                                    value={profile.open_time || '09:00'}
                                    onChange={(e) => setProfile({ ...profile, open_time: e.target.value })}
                                    className="w-full px-6 py-4 bg-gray-50 border-none rounded-2xl font-bold focus:ring-2 focus:ring-teal-500 transition-all"
                                />
                            </div>
                            <div>
                                <label className="block text-[10px] font-black uppercase tracking-widest text-gray-400 mb-2 px-1">Close Time</label>
                                <input
                                    type="time"
                                    value={profile.close_time || '21:00'}
                                    onChange={(e) => setProfile({ ...profile, close_time: e.target.value })}
                                    className="w-full px-6 py-4 bg-gray-50 border-none rounded-2xl font-bold focus:ring-2 focus:ring-teal-500 transition-all"
                                />
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default StoreSettings;
