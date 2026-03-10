import React from 'react';
import { Search } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';

interface HeaderProps {
    vendorProfile?: any;
    storeStatus?: string;
    toggleStore?: () => void;
}

const Header: React.FC<HeaderProps> = ({ vendorProfile, storeStatus, toggleStore }) => {
    const { user } = useAuth();
    const isVendor = user?.role === 'vendor';

    if (!user) return null;

    return (
        <header className="h-20 bg-white/80 backdrop-blur-md border-b border-gray-200 px-10 flex items-center justify-between sticky top-0 z-10">
            <div className="flex-1">
                {isVendor ? (
                    <div>
                        <h1 className="text-xl font-black text-gray-900 tracking-tight">{vendorProfile?.name || 'My Stall'}</h1>
                        <p className="text-xs text-gray-500 flex items-center gap-1 font-bold">
                            <span className={`inline-block w-2 h-2 rounded-full ${storeStatus === 'Open' ? 'bg-green-500' : 'bg-red-500'}`}></span>
                            Status: {storeStatus}
                        </p>
                    </div>
                ) : (
                    <div className="flex items-center gap-4 bg-gray-100 px-4 py-2 rounded-xl w-96 group focus-within:ring-2 focus-within:ring-teal-500 transition-all">
                        <Search size={18} className="text-gray-400 group-hover:text-teal-600" />
                        <input type="text" placeholder="Search resources..." className="bg-transparent border-none focus:outline-none text-sm w-full font-medium" />
                    </div>
                )}
            </div>

            <div className="flex items-center gap-6">
                {isVendor && toggleStore && (
                    <button
                        onClick={toggleStore}
                        className={`px-4 py-2 rounded-xl font-black text-xs uppercase border-2 transition-all ${storeStatus === 'Open' ? 'border-red-100 text-red-600 hover:bg-red-50' : 'border-green-100 text-green-600 hover:bg-green-50'}`}
                    >
                        {storeStatus === 'Open' ? 'Go Offline' : 'Go Online'}
                    </button>
                )}
                <div className="text-right">
                    <p className="text-[10px] font-black text-gray-400 uppercase tracking-widest">{user.role}</p>
                    <p className="font-bold text-teal-900 text-sm">{user.email}</p>
                </div>
                <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-teal-500 to-teal-700 shadow-lg shadow-teal-500/20 border-2 border-white flex items-center justify-center text-white font-black">
                    {user.email?.[0].toUpperCase()}
                </div>
            </div>
        </header>
    );
};

export default Header;
