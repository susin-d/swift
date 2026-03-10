import React from 'react';
import { Users, Store, ShoppingBag, TrendingUp } from 'lucide-react';
import StatCard from '../components/dashboard/StatCard';
import ChartCard from '../components/dashboard/ChartCard';
import ApprovalTable from '../components/dashboard/ApprovalTable';
import { useAuth } from '../context/AuthContext';

interface DashboardProps {
    adminStats: { users: number; vendors: number; orders: number; gmv: number };
    pendingVendors: any[];
    handleApproveVendor: (id: string) => void;
    chartData: any[];
}

const Dashboard: React.FC<DashboardProps> = ({
    adminStats,
    pendingVendors,
    handleApproveVendor,
    chartData
}) => {
    const { user } = useAuth();
    const isAdmin = user?.role === 'admin';

    return (
        <div className="space-y-10 p-10">
            {/* Stats Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
                {isAdmin ? (
                    <>
                        <StatCard title="Total Users" value={adminStats.users} icon={<Users size={24} />} trend="+12%" />
                        <StatCard title="Active Vendors" value={adminStats.vendors} icon={<Store size={24} />} trend="+2%" />
                        <StatCard title="Total Orders" value={adminStats.orders} icon={<ShoppingBag size={24} />} trend="+24%" />
                        <StatCard
                            title="Platform GMV"
                            value={`₹${(adminStats.gmv / 1000).toFixed(1)}k`}
                            icon={<TrendingUp size={24} />}
                            isDark
                        />
                    </>
                ) : (
                    <>
                        <StatCard title="Today's Orders" value={adminStats.orders} icon={<ShoppingBag size={24} />} trend="+5%" />
                        <StatCard title="Daily Revenue" value="₹8.2k" icon={<TrendingUp size={24} />} trend="+18%" />
                        <StatCard title="Top Item" value="Chicken 65" icon={<ShoppingBag size={24} />} />
                        <StatCard title="Store Status" value="Open" icon={<Store size={24} />} isDark />
                    </>
                )}
            </div>

            {/* Charts Section */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-10">
                <ChartCard title={isAdmin ? "System Volume" : "Order Volume"} data={chartData} />
                <ChartCard title={isAdmin ? "Revenue Stream" : "Earnings History"} data={chartData} isArea />
            </div>

            {/* Admin Specific Sections */}
            {isAdmin && (
                <ApprovalTable vendors={pendingVendors} onApprove={handleApproveVendor} />
            )}
        </div>
    );
};

export default Dashboard;
