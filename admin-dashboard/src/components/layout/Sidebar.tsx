import React from 'react';
import { NavLink } from 'react-router-dom';
import {
    Users,
    Store,
    ShieldCheck,
    Settings,
    LogOut,
    LayoutDashboard,
    ClipboardList,
    MenuSquare,
    BarChart3,
    Star,
    FileText,
    CreditCard,
    Bell,
    Box
} from 'lucide-react';
import { useAuth } from '../../context/AuthContext';

const Sidebar: React.FC = () => {
    const { user, signOut } = useAuth();
    const isAdmin = user?.role === 'admin';

    const menuItems = [
        { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard, roles: ['admin', 'vendor'], path: isAdmin ? '/admin' : '/vendor' },
        { id: 'orders', label: 'Orders', icon: ClipboardList, roles: ['admin', 'vendor'], path: isAdmin ? '/admin/orders' : '/vendor' },
        { id: 'menus', label: 'Menus', icon: MenuSquare, roles: ['vendor'], path: '/vendor/menus' },
        { id: 'vendors', label: 'Vendors', icon: Store, roles: ['admin'], path: '/admin/vendors' },
        { id: 'users', label: 'Users', icon: Users, roles: ['admin'], path: '/admin/users' },
        { id: 'analytics', label: 'Analytics', icon: BarChart3, roles: ['admin', 'vendor'], path: isAdmin ? '/admin/analytics' : '/vendor/analytics' },
        { id: 'payments', label: 'Payments', icon: CreditCard, roles: ['admin', 'vendor'], path: isAdmin ? '/admin/payments' : '/vendor/payments' },
        { id: 'notifications', label: 'Notifications', icon: Bell, roles: ['admin', 'vendor'], path: isAdmin ? '/admin/notifications' : '/vendor/notifications' },
        { id: 'reviews', label: 'Reviews', icon: Star, roles: ['admin', 'vendor'], path: isAdmin ? '/admin/reviews' : '/vendor/reviews' },
        { id: 'inventory', label: 'Inventory', icon: Box, roles: ['vendor'], path: '/vendor/inventory' },
        { id: 'settings', label: 'Settings', icon: Settings, roles: ['admin', 'vendor'], path: isAdmin ? '/admin/settings' : '/vendor/settings' },
        { id: 'logs', label: 'Audit Logs', icon: FileText, roles: ['admin'], path: '/admin/logs' },
    ];

    const filteredMenu = menuItems.filter(item => item.roles.includes(user?.role || ''));

    return (
        <aside className="w-72 bg-white border-r border-gray-200 flex flex-col relative z-20">
            <div className="h-20 px-8 flex items-center gap-3 border-b border-gray-100">
                <div className="w-10 h-10 bg-teal-600 rounded-xl flex items-center justify-center shadow-lg shadow-teal-600/20">
                    {isAdmin ? <ShieldCheck className="text-white w-6 h-6" /> : <Store className="text-white w-6 h-6" />}
                </div>
                <span className="text-xl font-black text-gray-900 tracking-tight">{isAdmin ? 'CampusAdmin' : 'VendorDash'}</span>
            </div>

            <nav className="flex-1 p-6 space-y-2 overflow-y-auto">
                <p className="px-4 text-[10px] font-black uppercase tracking-widest text-gray-400 mb-4">Main Navigation</p>

                {filteredMenu.map(item => (
                    <NavLink
                        key={item.id}
                        to={item.path}
                        end={item.path === '/admin' || item.path === '/vendor'}
                        className={({ isActive }) =>
                            `w-full flex items-center gap-4 px-4 py-4 rounded-2xl transition-all group ${isActive ? 'bg-teal-600 text-white shadow-xl shadow-teal-600/30' : 'text-gray-500 hover:bg-gray-50'}`
                        }
                    >
                        {({ isActive }) => (
                            <>
                                <item.icon size={20} className={isActive ? 'text-white' : 'group-hover:text-teal-600'} />
                                <span className="font-bold">{item.label}</span>
                            </>
                        )}
                    </NavLink>
                ))}
            </nav>

            <div className="p-6">
                <button
                    onClick={signOut}
                    className="w-full flex items-center gap-4 px-6 py-4 rounded-2xl bg-gray-900 text-white font-bold shadow-lg hover:bg-teal-800 transition-all"
                >
                    <LogOut size={20} /> Logout
                </button>
            </div>
        </aside>
    );
};

export default Sidebar;
