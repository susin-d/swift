import { createFileRoute } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { KpiCard } from "@/components/KpiCard";
import { StatusBadge } from "@/components/StatusBadge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { DollarSign, Wallet, TrendingUp, AlertCircle } from "lucide-react";
import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, Tooltip } from "recharts";
import { backendApi } from "@/lib/backend-api";

type BackendVendor = {
  id: string;
  name?: string;
  status?: string;
  revenue?: number;
  pendingPayout?: number;
  pending_payout?: number;
  payoutStatus?: string;
  payout_status?: string;
};

type FinanceSummary = { summary: { total_revenue: number; today_revenue: number; week_revenue: number; month_revenue: number } };
type FinancePayout = { vendor_id: string; vendor_name: string; total_orders: number; total_revenue: number };

export const Route = createFileRoute("/_authenticated/finance")({
  component: FinancePage,
});

function FinancePage() {
  const [loading, setLoading] = useState(true);
  const [summary, setSummary] = useState<FinanceSummary['summary'] | null>(null);
  const [vendors, setVendors] = useState<BackendVendor[]>([]);
  const [payouts, setPayouts] = useState<FinancePayout[]>([]);

  useEffect(() => {
    let cancelled = false;

    const load = async () => {
      try {
        const [summaryResp, vendorsResp, payoutsResp] = await Promise.all([
          backendApi.get<FinanceSummary>('/admin/finance/summary'),
          backendApi.get<BackendVendor[]>('/admin/vendors'),
          backendApi.get<{ payouts?: FinancePayout[] }>('/admin/finance/payouts'),
        ]);

        if (cancelled) return;

        setSummary(summaryResp.summary);
        setVendors(vendorsResp || []);
        setPayouts(payoutsResp.payouts || []);
      } catch {
        if (!cancelled) {
          setSummary(null);
          setVendors([]);
          setPayouts([]);
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

  const approvedVendors = vendors.filter((vendor) => vendor.status === 'approved' || vendor.status === 'active');
  const vendorRevenue = approvedVendors
    .sort((left, right) => Number(right.revenue || 0) - Number(left.revenue || 0))
    .map((vendor) => ({ name: vendor.name || vendor.id, revenue: Number(vendor.revenue || 0) / 1000 }));

  const totalRevenue = summary?.total_revenue ?? 0;
  const platformCommission = Math.round(totalRevenue * 0.1);
  const pendingPayouts = vendors.reduce((sum, vendor) => sum + Number(vendor.pendingPayout ?? vendor.pending_payout ?? 0), 0);
  const failedPayouts = vendors.filter((vendor) => (vendor.payoutStatus || vendor.payout_status) === 'failed').length;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Finance & Payouts</h1>
        <p className="text-sm text-muted-foreground">Revenue, payouts, and transaction ledger</p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <KpiCard title="Total Revenue" value={`₹${(totalRevenue / 1000).toFixed(0)}K`} icon={DollarSign} trend={{ value: 12, label: "vs last month" }} />
        <KpiCard title="Platform Commission" value={`₹${(platformCommission / 1000).toFixed(0)}K`} icon={TrendingUp} subtitle="10% rate" />
        <KpiCard title="Pending Payouts" value={`₹${(pendingPayouts / 1000).toFixed(1)}K`} icon={Wallet} />
        <KpiCard title="Failed Payouts" value={failedPayouts} icon={AlertCircle} subtitle="Needs attention" />
      </div>

      <Tabs defaultValue="payouts">
        <TabsList>
          <TabsTrigger value="payouts">Vendor Payouts</TabsTrigger>
          <TabsTrigger value="ledger">Payout Records</TabsTrigger>
          <TabsTrigger value="chart">Revenue by Vendor</TabsTrigger>
        </TabsList>

        <TabsContent value="payouts" className="mt-4">
          <Card>
            <CardHeader><CardTitle className="text-base">Payout Health by Vendor</CardTitle></CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Vendor</TableHead>
                    <TableHead>Total Revenue</TableHead>
                    <TableHead>Pending Payout</TableHead>
                    <TableHead>Payout Status</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {loading ? (
                    <TableRow>
                      <TableCell colSpan={4} className="text-center text-sm text-muted-foreground">Loading finance data...</TableCell>
                    </TableRow>
                  ) : approvedVendors.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={4} className="text-center text-sm text-muted-foreground">No vendor payout data found.</TableCell>
                    </TableRow>
                  ) : approvedVendors.map((v) => (
                    <TableRow key={v.id}>
                      <TableCell className="font-medium">{v.name || v.id}</TableCell>
                      <TableCell>₹{Number(v.revenue || 0).toLocaleString()}</TableCell>
                      <TableCell>₹{Number(v.pendingPayout ?? v.pending_payout ?? 0).toLocaleString()}</TableCell>
                      <TableCell><StatusBadge status={(v.payoutStatus || v.payout_status || 'pending') as string} /></TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="ledger" className="mt-4">
          <Card>
            <CardHeader><CardTitle className="text-base">Payout Records</CardTitle></CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Vendor</TableHead>
                    <TableHead>Total Orders</TableHead>
                    <TableHead>Revenue</TableHead>
                    <TableHead>Estimated Commission</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {loading ? (
                    <TableRow>
                      <TableCell colSpan={4} className="text-center text-sm text-muted-foreground">Loading payout records...</TableCell>
                    </TableRow>
                  ) : payouts.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={4} className="text-center text-sm text-muted-foreground">No payout records found.</TableCell>
                    </TableRow>
                  ) : payouts.map((payout) => (
                    <TableRow key={payout.vendor_id}>
                      <TableCell className="font-medium">{payout.vendor_name}</TableCell>
                      <TableCell>{payout.total_orders}</TableCell>
                      <TableCell>₹{payout.total_revenue.toLocaleString()}</TableCell>
                      <TableCell>₹{Math.round(payout.total_revenue * 0.1).toLocaleString()}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="chart" className="mt-4">
          <Card>
            <CardHeader><CardTitle className="text-base">Revenue by Vendor (₹ thousands)</CardTitle></CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={vendorRevenue} layout="vertical">
                  <XAxis type="number" tick={{ fontSize: 12 }} tickFormatter={(v) => `₹${v}K`} />
                  <YAxis dataKey="name" type="category" tick={{ fontSize: 12 }} width={110} />
                  <Tooltip formatter={(v: any) => [`₹${v}K`, "Revenue"]} />
                  <Bar dataKey="revenue" fill="hsl(var(--chart-1))" radius={[0, 4, 4, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
