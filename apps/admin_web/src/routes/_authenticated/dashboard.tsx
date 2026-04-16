import { createFileRoute } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { KpiCard } from "@/components/KpiCard";
import { StatusBadge } from "@/components/StatusBadge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Users, Store, ShoppingCart, DollarSign, TrendingUp, TicketCheck } from "lucide-react";
import { ResponsiveContainer, AreaChart, Area, XAxis, YAxis, Tooltip, BarChart, Bar } from "recharts";
import { backendApi } from "@/lib/backend-api";

type StatsResponse = { stats: { users: number; vendors: number; orders: number; revenue: number } };
type SummaryResponse = { summary: { total_users: number; total_vendors: number; active_orders: number; completed_orders: number; revenue: number } };
type ChartPoint = { name: string; orders: number; revenue: number };

type BackendVendor = { id: string; name?: string; status?: string; revenue?: number };
type BackendOrder = {
  id: string;
  status?: string;
  created_at?: string;
  total_amount?: number;
  total?: number;
  user?: { name?: string; email?: string };
  users?: { name?: string; email?: string };
  vendor?: { name?: string };
  vendors?: { name?: string };
};

export const Route = createFileRoute("/_authenticated/dashboard")({
  component: DashboardPage,
});

function DashboardPage() {
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState<StatsResponse['stats'] | null>(null);
  const [summary, setSummary] = useState<SummaryResponse['summary'] | null>(null);
  const [chartData, setChartData] = useState<ChartPoint[]>([]);
  const [vendors, setVendors] = useState<BackendVendor[]>([]);
  const [orders, setOrders] = useState<BackendOrder[]>([]);

  useEffect(() => {
    let cancelled = false;

    const load = async () => {
      try {
        const [statsResp, summaryResp, chartResp, vendorsResp, ordersResp] = await Promise.all([
          backendApi.get<StatsResponse>('/admin/stats'),
          backendApi.get<SummaryResponse>('/admin/dashboard/summary'),
          backendApi.get<{ chartData: ChartPoint[] }>('/admin/charts'),
          backendApi.get<BackendVendor[]>('/admin/vendors'),
          backendApi.get<{ orders?: BackendOrder[]; data?: BackendOrder[] }>('/admin/orders?limit=7'),
        ]);

        if (cancelled) return;

        setStats(statsResp.stats);
        setSummary(summaryResp.summary);
        setChartData(chartResp.chartData || []);
        setVendors(vendorsResp || []);
        setOrders((ordersResp.orders || ordersResp.data || []).slice(0, 7));
      } catch {
        if (!cancelled) {
          setStats(null);
          setSummary(null);
          setChartData([]);
          setVendors([]);
          setOrders([]);
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    };

    void load();
    return () => {
      cancelled = true;
    };
  }, []);

  const approvedVendors = vendors
    .filter((vendor) => vendor.status === 'approved' || vendor.status === 'active')
    .sort((left, right) => (Number(right.revenue || 0) - Number(left.revenue || 0)))
    .slice(0, 4);

  const revenue = summary?.revenue ?? stats?.revenue ?? 0;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Dashboard</h1>
        <p className="text-sm text-muted-foreground">Platform overview and key metrics</p>
      </div>

      {/* KPI Cards */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6">
        <KpiCard title="Total Users" value={summary?.total_users ?? stats?.users ?? 0} icon={Users} trend={{ value: 12, label: "vs last month" }} color="blue" />
        <KpiCard title="Active Vendors" value={summary?.total_vendors ?? stats?.vendors ?? 0} icon={Store} trend={{ value: 5, label: "vs last month" }} color="emerald" />
        <KpiCard title="Orders Today" value={summary?.active_orders ?? stats?.orders ?? 0} icon={ShoppingCart} trend={{ value: 8, label: "vs yesterday" }} color="orange" />
        <KpiCard title="Revenue (MTD)" value={`₹${revenue.toLocaleString()}`} icon={DollarSign} trend={{ value: 15, label: "vs last month" }} color="violet" />
        <KpiCard title="Total Revenue" value={`₹${(revenue / 1000).toFixed(0)}K`} icon={TrendingUp} color="indigo" />
        <KpiCard title="Open Tickets" value="Live" icon={TicketCheck} subtitle="Use Support tab" color="rose" />
      </div>

      {/* Charts */}
      <div className="grid gap-4 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Revenue Trend (April)</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={250}>
              <AreaChart data={chartData}>
                <defs>
                  <linearGradient id="revGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="hsl(var(--chart-1))" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="hsl(var(--chart-1))" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <XAxis dataKey="name" tick={{ fontSize: 12 }} />
                <YAxis tick={{ fontSize: 12 }} tickFormatter={(v) => `₹${v / 1000}K`} />
                <Tooltip formatter={(v: any) => [`₹${Number(v).toLocaleString()}`, "Revenue"]} />
                <Area type="monotone" dataKey="revenue" stroke="hsl(var(--chart-1))" fill="url(#revGrad)" strokeWidth={2} />
              </AreaChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">Orders Trend (April)</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={250}>
              <BarChart data={chartData}>
                <XAxis dataKey="name" tick={{ fontSize: 12 }} />
                <YAxis tick={{ fontSize: 12 }} />
                <Tooltip />
                <Bar dataKey="orders" fill="hsl(var(--chart-2))" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      </div>

      {/* Top Vendors */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Top Vendors by Revenue</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
              {approvedVendors.length === 0 && !loading ? (
                <p className="text-sm text-muted-foreground">No vendor data available.</p>
              ) : (
                approvedVendors.map((vendor) => (
                  <div key={vendor.id} className="flex items-center gap-3 rounded-lg border p-3">
                    <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary/10 text-sm font-bold text-primary">
                      {(vendor.name || 'V')[0]}
                    </div>
                    <div>
                      <p className="text-sm font-medium">{vendor.name || vendor.id}</p>
                      <p className="text-xs text-muted-foreground">₹{(Number(vendor.revenue || 0) / 1000).toFixed(0)}K revenue</p>
                    </div>
                  </div>
                ))
              )}
          </div>
        </CardContent>
      </Card>

      {/* Recent Orders */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Recent Orders</CardTitle>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Order ID</TableHead>
                <TableHead>Customer</TableHead>
                <TableHead>Vendor</TableHead>
                <TableHead>Total</TableHead>
                <TableHead>Status</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {orders.length === 0 && !loading ? (
                <TableRow>
                  <TableCell colSpan={5} className="text-center text-sm text-muted-foreground">No recent orders found.</TableCell>
                </TableRow>
              ) : (
                orders.map((order) => {
                  const total = Number(order.total_amount ?? order.total ?? 0);
                  const userName = order.user?.name || order.users?.name || order.user?.email || order.users?.email || 'Unknown';
                  const vendorName = order.vendor?.name || order.vendors?.name || 'Unknown';

                  return (
                    <TableRow key={order.id}>
                      <TableCell className="font-mono text-xs">{order.id}</TableCell>
                      <TableCell>{userName}</TableCell>
                      <TableCell>{vendorName}</TableCell>
                      <TableCell>₹{total.toLocaleString()}</TableCell>
                      <TableCell><StatusBadge status={order.status || 'placed'} /></TableCell>
                    </TableRow>
                  );
                })
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}
