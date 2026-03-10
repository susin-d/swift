import React, { useState, useEffect } from 'react';
import { Routes, Route, Navigate, useLocation } from 'react-router-dom';
import { supabase } from './lib/supabase';
import api from './lib/api';
import { useAuth } from './context/AuthContext';
import { Login } from './components/Login';
import ProtectedRoute from './components/auth/ProtectedRoute';
import Sidebar from './components/layout/Sidebar';
import Header from './components/layout/Header';
import Dashboard from './pages/Dashboard';
import Orders from './pages/Orders';
import MenuStudio from './pages/Menu';
import StoreSettings from './pages/StoreSettings';
import Vendors from './pages/Vendors';
import Analytics from './pages/Analytics';
import CampusMap from './pages/CampusMap';
import { Settings } from 'lucide-react';

// Chart data state removed from top-level const

const App: React.FC = () => {
  const { user, loading: authLoading } = useAuth();
  const isAdmin = user?.role === 'admin';
  const isVendor = user?.role === 'vendor';
  const location = useLocation();

  // Admin State
  const [adminStats, setAdminStats] = useState({ users: 0, vendors: 0, orders: 0, gmv: 0 });
  const [pendingVendors, setPendingVendors] = useState<any[]>([]);
  const [chartData, setChartData] = useState<any[]>([]);

  // Vendor State
  const [orders, setOrders] = useState<any[]>([]);
  const [storeStatus, setStoreStatus] = useState('Open');
  const [vendorProfile, setVendorProfile] = useState<any>(null);

  useEffect(() => {
    if (user) {
      if (isAdmin) {
        fetchGlobalStats();
        fetchPendingVendors();
        fetchChartData();
      } else if (isVendor) {
        fetchVendorProfile();
        fetchOrders();
        const cleanup = subscribeToOrders();
        return cleanup;
      }
    }
  }, [user, isAdmin, isVendor]);

  // Admin Logic
  const fetchGlobalStats = async () => {
    try {
      const res = await api.get('/admin/stats');
      setAdminStats({
        users: res.data.stats.users,
        vendors: res.data.stats.vendors,
        orders: res.data.stats.orders,
        gmv: res.data.stats.gmv
      });
    } catch (err) {
      console.error('Error fetching global stats:', err);
    }
  };

  const fetchChartData = async () => {
    try {
      const res = await api.get('/admin/charts');
      setChartData(res.data.chartData);
    } catch (err) {
      console.error('Error fetching chart data:', err);
    }
  };

  const fetchPendingVendors = async () => {
    try {
      const res = await api.get('/admin/vendors/pending');
      setPendingVendors(res.data.vendors);
    } catch (err) {
      console.error('Error fetching pending vendors:', err);
    }
  };

  const handleApproveVendor = async (vendorId: string) => {
    try {
      await api.patch(`/admin/vendors/${vendorId}/approve`);
      fetchPendingVendors(); // Refresh list
    } catch (err) {
      console.error('Error approving vendor:', err);
    }
  };

  // Vendor Logic
  const fetchVendorProfile = async () => {
    try {
      const res = await api.get('/vendor-ops/profile');
      setVendorProfile(res.data.vendor);
      setStoreStatus(res.data.vendor.is_open ? 'Open' : 'Closed');
    } catch (err) {
      console.error('Error fetching profile:', err);
    }
  };

  const fetchOrders = async () => {
    try {
      const res = await api.get('/vendor-ops/orders');
      setOrders(res.data); // Backend returns the array directly now
    } catch (err) {
      console.error('Error fetching orders:', err);
    }
  };

  const subscribeToOrders = () => {
    const channel = supabase
      .channel('vendor-orders')
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'orders' }, fetchOrders)
      .on('postgres_changes', { event: 'UPDATE', schema: 'public', table: 'orders' }, fetchOrders)
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  };

  const toggleStore = async () => {
    const newStatus = storeStatus === 'Open' ? false : true;
    try {
      await api.patch('/vendor-ops/profile', { is_open: newStatus });
      setStoreStatus(newStatus ? 'Open' : 'Closed');
    } catch (err) {
      console.error('Error toggling store:', err);
    }
  };

  const handleUpdateStatus = async (orderId: string, status: string) => {
    try {
      await api.patch(`/orders/${orderId}/status`, { status });
      fetchOrders();
    } catch (err) {
      console.error('Error updating status:', err);
    }
  };

  if (authLoading) return <div className="h-screen w-screen flex items-center justify-center font-black text-teal-600 animate-pulse">CONNECTING...</div>;

  return (
    <Routes>
      <Route path="/login" element={user ? <Navigate to="/" replace /> : <Login />} />

      {/* Root redirect based on role */}
      <Route path="/" element={
        user ? (
          isAdmin ? <Navigate to="/admin" replace /> :
            isVendor ? <Navigate to="/vendor" replace /> :
              <div className="h-screen w-screen flex flex-col items-center justify-center font-black text-teal-600 bg-white">
                <div className="animate-spin mb-4 text-4xl">🌀</div>
                <p className="tracking-widest animate-pulse">SYNCING PORTAL...</p>
              </div>
        ) : (
          <Navigate to="/login" replace />
        )
      } />

      {/* Admin Portal */}
      <Route element={<ProtectedRoute allowedRoles={['admin']} />}>
        <Route path="/admin" element={
          <div className="flex h-screen bg-gray-50 overflow-hidden font-['Inter']">
            <Sidebar />
            <main className="flex-1 flex flex-col overflow-hidden relative">
              <Header vendorProfile={vendorProfile} storeStatus={storeStatus} toggleStore={toggleStore} />
              <div className="flex-1 overflow-y-auto bg-gray-50/50">
                <Routes>
                  <Route index element={<Dashboard adminStats={adminStats} pendingVendors={pendingVendors} handleApproveVendor={handleApproveVendor} chartData={chartData} />} />
                  <Route path="orders" element={<CampusMap />} />
                  <Route path="vendors" element={<Vendors />} />
                  <Route path="analytics" element={<Analytics />} />
                  <Route path="*" element={<ModulePlaceholder name={location.pathname.split('/').pop() || ''} />} />
                </Routes>
              </div>
            </main>
          </div>
        } />
      </Route>

      {/* Vendor Portal */}
      <Route element={<ProtectedRoute allowedRoles={['vendor']} />}>
        <Route path="/vendor" element={
          <div className="flex h-screen bg-gray-50 overflow-hidden font-['Inter']">
            <Sidebar />
            <main className="flex-1 flex flex-col overflow-hidden relative">
              <Header vendorProfile={vendorProfile} storeStatus={storeStatus} toggleStore={toggleStore} />
              <div className="flex-1 overflow-y-auto bg-gray-50/50">
                <Routes>
                  <Route index element={<Orders orders={orders} handleUpdateStatus={handleUpdateStatus} />} />
                  <Route path="menus" element={<MenuStudio />} />
                  <Route path="settings" element={<StoreSettings initialProfile={vendorProfile} onUpdate={fetchVendorProfile} />} />
                  <Route path="analytics" element={<Analytics />} />
                  <Route path="*" element={<ModulePlaceholder name={location.pathname.split('/').pop() || ''} />} />
                </Routes>
              </div>
            </main>
          </div>
        } />
      </Route>

      {/* Fallback */}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
};

const ModulePlaceholder: React.FC<{ name: string }> = ({ name }) => (
  <div className="h-full flex flex-col items-center justify-center text-gray-400 p-20">
    <div className="w-24 h-24 bg-gray-100 rounded-[32px] flex items-center justify-center mb-6">
      <Settings size={48} className="text-gray-200" />
    </div>
    <p className="text-2xl font-black uppercase tracking-widest">{name} Module</p>
    <p className="font-bold mt-2">Coming soon as part of the Phase 2 roadmap</p>
  </div>
);

export default App;
