import React, { useState, useEffect } from 'react';
import { Plus, Search, Edit2, Trash2, MoreVertical, X, Save, Image as ImageIcon } from 'lucide-react';
import api from '../lib/api';

const FOOD_IMAGES = [
    'https://images.unsplash.com/photo-1589302168068-964692d93d51?q=80&w=800',
    'https://images.unsplash.com/photo-1601050690597-df0568f70950?q=80&w=800',
    'https://images.unsplash.com/photo-1512152272829-e3139592d56f?q=80&w=800',
    'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?q=80&w=800',
    'https://images.unsplash.com/photo-1544333346-713fe54453b6?q=80&w=800',
    'https://images.unsplash.com/photo-1567620905732-2d1ec7bb7445?q=80&w=800',
];

const MenuStudio: React.FC = () => {
    const [items, setItems] = useState<any[]>([]);
    const [categories, setCategories] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchQuery, setSearchQuery] = useState('');

    // Modal State
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingItem, setEditingItem] = useState<any>(null);
    const [formData, setFormData] = useState({
        name: '',
        description: '',
        price: '',
        category_id: '',
        image_url: '',
        is_available: true
    });
    const [saving, setSaving] = useState(false);

    useEffect(() => {
        fetchMenuItems();
    }, []);

    const fetchMenuItems = async () => {
        try {
            const res = await api.get('/vendor-ops/menu');
            setItems(res.data.items);
            setCategories(res.data.categories);
        } catch (err) {
            console.error('Error fetching menu:', err);
        } finally {
            setLoading(false);
        }
    };

    const handleOpenModal = (item: any = null) => {
        if (item) {
            setEditingItem(item);
            // Find the menu_id (category_id)
            const cat = categories.find(c => c.category_name === item.category);
            setFormData({
                name: item.name,
                description: item.description || '',
                price: item.price.toString(),
                category_id: cat?.id || '',
                image_url: item.image_url || '',
                is_available: item.is_available
            });
        } else {
            setEditingItem(null);
            setFormData({
                name: '',
                description: '',
                price: '',
                category_id: categories[0]?.id || '',
                image_url: FOOD_IMAGES[0],
                is_available: true
            });
        }
        setIsModalOpen(true);
    };

    const handleSave = async (e: React.FormEvent) => {
        e.preventDefault();
        setSaving(true);
        try {
            const payload = {
                name: formData.name,
                description: formData.description,
                price: parseFloat(formData.price),
                menu_id: formData.category_id,
                image_url: formData.image_url,
                is_available: formData.is_available
            };

            if (editingItem) {
                await api.patch(`/menus/items/${editingItem.id}`, payload);
            } else {
                await api.post('/menus/items', payload);
            }

            setIsModalOpen(false);
            fetchMenuItems();
        } catch (err) {
            console.error('Error saving item:', err);
        } finally {
            setSaving(false);
        }
    };

    const handleDelete = async (id: string) => {
        if (window.confirm('Are you sure you want to delete this item?')) {
            try {
                await api.delete(`/menus/items/${id}`);
                fetchMenuItems();
            } catch (err) {
                console.error('Error deleting item:', err);
            }
        }
    };

    const toggleAvailability = async (id: string, currentStatus: boolean) => {
        try {
            await api.patch(`/menus/items/${id}`, { is_available: !currentStatus });
            fetchMenuItems();
        } catch (err) {
            console.error('Error toggling availability:', err);
        }
    };

    const filteredItems = items.filter(item =>
        item.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        item.category?.toLowerCase().includes(searchQuery.toLowerCase())
    );

    return (
        <div className="p-10 space-y-10 pb-20 relative">
            {/* Header */}
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div>
                    <h2 className="text-3xl font-black text-gray-900 tracking-tight">Menu Studio</h2>
                    <p className="text-gray-500 font-bold mt-1">Design and publish your campus offerings</p>
                </div>
                <div className="flex gap-4">
                    <div className="bg-white px-6 py-3 rounded-2xl border border-gray-100 shadow-sm flex items-center gap-4 focus-within:ring-2 focus-within:ring-teal-500 transition-all">
                        <Search size={20} className="text-gray-400" />
                        <input
                            type="text"
                            placeholder="Search items..."
                            className="bg-transparent border-none focus:outline-none text-sm font-bold w-64"
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                        />
                    </div>
                    <button
                        onClick={() => handleOpenModal()}
                        className="flex items-center gap-3 px-8 py-4 bg-teal-600 text-white rounded-2xl font-black shadow-xl shadow-teal-600/30 hover:bg-teal-700 transition-all"
                    >
                        <Plus size={20} /> Add Item
                    </button>
                </div>
            </div>

            {loading ? (
                <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-8">
                    {[1, 2, 3].map(i => (
                        <div key={i} className="h-64 bg-white rounded-[32px] border border-gray-100 animate-pulse"></div>
                    ))}
                </div>
            ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-8">
                    {filteredItems.map(item => (
                        <div key={item.id} className="bg-white rounded-[40px] border border-gray-100 shadow-sm hover:shadow-2xl transition-all overflow-hidden group">
                            <div className="aspect-[16/10] bg-gray-100 relative overflow-hidden">
                                {item.image_url ? (
                                    <img src={item.image_url} alt={item.name} className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700" />
                                ) : (
                                    <div className="w-full h-full flex items-center justify-center text-gray-300">
                                        <ImageIcon size={48} />
                                    </div>
                                )}
                                <div className="absolute top-4 right-4 flex gap-2">
                                    <button
                                        onClick={() => handleOpenModal(item)}
                                        className="p-3 bg-white/90 backdrop-blur-md rounded-2xl text-gray-600 hover:text-teal-600 shadow-xl transition-all"
                                    >
                                        <Edit2 size={16} />
                                    </button>
                                    <button
                                        onClick={() => handleDelete(item.id)}
                                        className="p-3 bg-white/90 backdrop-blur-md rounded-2xl text-gray-600 hover:text-red-600 shadow-xl transition-all"
                                    >
                                        <Trash2 size={16} />
                                    </button>
                                </div>
                                <div className="absolute bottom-4 left-4">
                                    <span className={`px-4 py-2 rounded-xl text-[10px] font-black uppercase tracking-widest shadow-lg ${item.is_available ? 'bg-teal-600 text-white' : 'bg-red-500 text-white'}`}>
                                        {item.is_available ? 'In Stock' : 'Sold Out'}
                                    </span>
                                </div>
                            </div>

                            <div className="p-8">
                                <div className="flex justify-between items-start mb-4">
                                    <div>
                                        <h3 className="text-xl font-black text-gray-900 tracking-tight">{item.name}</h3>
                                        <p className="text-xs text-gray-400 font-bold uppercase tracking-widest leading-none mt-1">{item.category}</p>
                                    </div>
                                    <span className="text-2xl font-black text-teal-900 tracking-tighter">₹{item.price}</span>
                                </div>

                                <p className="text-sm text-gray-500 mb-8 line-clamp-2 font-medium leading-relaxed">
                                    {item.description || 'No description provided.'}
                                </p>

                                <div className="flex items-center gap-3">
                                    <button
                                        onClick={() => toggleAvailability(item.id, item.is_available)}
                                        className={`flex-1 py-4 rounded-2xl text-[10px] font-black uppercase tracking-widest transition-all ${item.is_available ? 'bg-amber-50 text-amber-600 hover:bg-amber-100' : 'bg-teal-50 text-teal-600 hover:bg-teal-100'}`}
                                    >
                                        {item.is_available ? 'Mark Sold Out' : 'Mark Available'}
                                    </button>
                                    <button className="p-4 bg-gray-50 text-gray-400 rounded-2xl hover:text-gray-900 transition-all">
                                        <MoreVertical size={20} />
                                    </button>
                                </div>
                            </div>
                        </div>
                    ))}
                </div>
            )}

            {/* Add/Edit Modal */}
            {isModalOpen && (
                <div className="fixed inset-0 z-[100] flex items-center justify-center p-6 sm:p-10">
                    <div className="absolute inset-0 bg-gray-900/60 backdrop-blur-sm" onClick={() => setIsModalOpen(false)}></div>
                    <div className="bg-white w-full max-w-2xl rounded-[48px] shadow-2xl relative z-10 overflow-hidden flex flex-col max-h-full">
                        <div className="p-10 border-b border-gray-100 flex items-center justify-between">
                            <div>
                                <h3 className="text-2xl font-black text-gray-900">{editingItem ? 'Edit Item' : 'Add New Item'}</h3>
                                <p className="text-sm text-gray-500 font-bold">Fill in the details for your menu item</p>
                            </div>
                            <button
                                onClick={() => setIsModalOpen(false)}
                                className="p-4 bg-gray-50 text-gray-400 rounded-2xl hover:bg-red-50 hover:text-red-500 transition-all"
                            >
                                <X size={20} />
                            </button>
                        </div>

                        <form onSubmit={handleSave} className="flex-1 overflow-y-auto p-10 space-y-8">
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                                <div className="space-y-6">
                                    <div>
                                        <label className="block text-[10px] font-black uppercase tracking-widest text-gray-400 mb-2 px-1">Item Name</label>
                                        <input
                                            type="text"
                                            required
                                            value={formData.name}
                                            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                                            className="w-full px-6 py-4 bg-gray-50 border-none rounded-2xl font-bold focus:ring-2 focus:ring-teal-500 transition-all"
                                            placeholder="e.g. Special Chicken Biryani"
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-[10px] font-black uppercase tracking-widest text-gray-400 mb-2 px-1">Category</label>
                                        <select
                                            required
                                            value={formData.category_id}
                                            onChange={(e) => setFormData({ ...formData, category_id: e.target.value })}
                                            className="w-full px-6 py-4 bg-gray-50 border-none rounded-2xl font-bold focus:ring-2 focus:ring-teal-500 transition-all"
                                        >
                                            {categories.map(cat => (
                                                <option key={cat.id} value={cat.id}>{cat.category_name}</option>
                                            ))}
                                        </select>
                                    </div>
                                    <div>
                                        <label className="block text-[10px] font-black uppercase tracking-widest text-gray-400 mb-2 px-1">Price (₹)</label>
                                        <input
                                            type="number"
                                            required
                                            value={formData.price}
                                            onChange={(e) => setFormData({ ...formData, price: e.target.value })}
                                            className="w-full px-6 py-4 bg-gray-50 border-none rounded-2xl font-bold focus:ring-2 focus:ring-teal-500 transition-all"
                                            placeholder="0.00"
                                        />
                                    </div>
                                </div>

                                <div className="space-y-6">
                                    <div>
                                        <label className="block text-[10px] font-black uppercase tracking-widest text-gray-400 mb-2 px-1">Cover Image</label>
                                        <div className="grid grid-cols-3 gap-3">
                                            {FOOD_IMAGES.map((img, i) => (
                                                <button
                                                    key={i}
                                                    type="button"
                                                    onClick={() => setFormData({ ...formData, image_url: img })}
                                                    className={`aspect-square rounded-2xl overflow-hidden border-4 transition-all ${formData.image_url === img ? 'border-teal-500 scale-95' : 'border-transparent opacity-50 hover:opacity-100'}`}
                                                >
                                                    <img src={img} className="w-full h-full object-cover" alt="Food option" />
                                                </button>
                                            ))}
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div>
                                <label className="block text-[10px] font-black uppercase tracking-widest text-gray-400 mb-2 px-1">Description</label>
                                <textarea
                                    value={formData.description}
                                    onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                                    className="w-full px-6 py-4 bg-gray-50 border-none rounded-2xl font-bold focus:ring-2 focus:ring-teal-500 transition-all min-h-[100px]"
                                    placeholder="Describe the taste, ingredients, and portions..."
                                />
                            </div>

                            <div className="flex items-center gap-4 p-4 bg-teal-50 rounded-2xl">
                                <input
                                    type="checkbox"
                                    id="available"
                                    checked={formData.is_available}
                                    onChange={(e) => setFormData({ ...formData, is_available: e.target.checked })}
                                    className="w-5 h-5 text-teal-600 rounded-lg border-none focus:ring-0"
                                />
                                <label htmlFor="available" className="text-sm font-black text-teal-900">Mark as available immediately</label>
                            </div>
                        </form>

                        <div className="p-10 bg-gray-50 flex gap-4">
                            <button
                                type="button"
                                onClick={() => setIsModalOpen(false)}
                                className="flex-1 py-4 bg-white border border-gray-200 text-gray-500 rounded-2xl font-black hover:bg-gray-100 transition-all"
                            >
                                Cancel
                            </button>
                            <button
                                onClick={handleSave}
                                disabled={saving}
                                className="flex-[2] py-4 bg-teal-600 text-white rounded-2xl font-black shadow-xl shadow-teal-600/30 hover:bg-teal-700 transition-all disabled:opacity-50 flex items-center justify-center gap-3"
                            >
                                {saving ? 'Processing...' : <><Save size={20} /> {editingItem ? 'Update Item' : 'Publish Item'}</>}
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default MenuStudio;
