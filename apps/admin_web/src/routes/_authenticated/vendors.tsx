import { createFileRoute } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { StatusBadge } from "@/components/StatusBadge";
import { ReasonCaptureDialog } from "@/components/ReasonCaptureDialog";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetDescription } from "@/components/ui/sheet";
import { Search, CheckCircle, XCircle, Star } from "lucide-react";
import { toast } from "sonner";
import { backendApi } from "@/lib/backend-api";

type BackendVendor = {
  id: string;
  name?: string;
  ownerName?: string;
  owner_name?: string;
  owner?: { name?: string; email?: string };
  email?: string;
  status?: string;
  rating?: number;
  totalOrders?: number;
  total_orders?: number;
  revenue?: number;
  created_at?: string;
  joinedAt?: string;
  cuisine?: string;
  payoutStatus?: string;
  payout_status?: string;
  pendingPayout?: number;
  pending_payout?: number;
};

type VendorRow = {
  id: string;
  name: string;
  ownerName: string;
  email: string;
  status: "pending" | "approved" | "rejected" | "suspended";
  rating: number;
  totalOrders: number;
  revenue: number;
  joinedAt: string;
  cuisine: string;
  payoutStatus: "pending" | "completed" | "failed";
  pendingPayout: number;
};

export const Route = createFileRoute("/_authenticated/vendors")({
  component: VendorsPage,
});

function VendorsPage() {
  const [vendors, setVendors] = useState<VendorRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [selectedVendor, setSelectedVendor] = useState<VendorRow | null>(null);
  const [reasonDialog, setReasonDialog] = useState<{ open: boolean; vendorId: string; action: "approve" | "reject" | "suspend" }>({ open: false, vendorId: "", action: "approve" });

  useEffect(() => {
    let cancelled = false;

    const load = async () => {
      try {
        const response = await backendApi.get<BackendVendor[]>('/admin/vendors');
        if (cancelled) return;

        setVendors((response || []).map((vendor) => ({
          id: vendor.id,
          name: vendor.name || vendor.id,
          ownerName: vendor.ownerName || vendor.owner_name || vendor.owner?.name || vendor.owner?.email || 'Unknown',
          email: vendor.email || vendor.owner?.email || '',
          status: (vendor.status === 'inactive' ? 'suspended' : (vendor.status as VendorRow['status']) || 'pending'),
          rating: Number(vendor.rating || 0),
          totalOrders: Number(vendor.totalOrders ?? vendor.total_orders ?? 0),
          revenue: Number(vendor.revenue || 0),
          joinedAt: vendor.joinedAt || vendor.created_at ? new Date(vendor.joinedAt || vendor.created_at || '').toLocaleDateString() : '—',
          cuisine: vendor.cuisine || '—',
          payoutStatus: (vendor.payoutStatus || vendor.payout_status || 'pending') as VendorRow['payoutStatus'],
          pendingPayout: Number(vendor.pendingPayout ?? vendor.pending_payout ?? 0),
        })));
      } catch {
        if (!cancelled) setVendors([]);
      } finally {
        if (!cancelled) setLoading(false);
      }
    };

    void load();
    return () => {
      cancelled = true;
    };
  }, []);

  const filtered = vendors.filter((v) =>
    v.name.toLowerCase().includes(search.toLowerCase()) ||
    v.ownerName.toLowerCase().includes(search.toLowerCase())
  );

  const handleAction = (reason: string) => {
    const { vendorId, action } = reasonDialog;
    const commit = async () => {
      if (action === 'approve') {
        await backendApi.patch(`/admin/vendors/${vendorId}/approve`, {});
      } else if (action === 'reject') {
        await backendApi.patch(`/admin/vendors/${vendorId}/reject`, { reason });
      } else {
        await backendApi.patch(`/admin/vendors/${vendorId}/status`, { status: 'inactive', reason });
      }

      setVendors((prev) =>
        prev.map((vendor) => {
          if (vendor.id !== vendorId) return vendor;
          if (action === 'approve') return { ...vendor, status: 'approved' };
          if (action === 'reject') return { ...vendor, status: 'rejected' };
          return { ...vendor, status: 'suspended' };
        })
      );
      toast.success(`Vendor ${action}d successfully`, { description: `Reason: ${reason}` });
    };

    void commit().catch((error: any) => {
      toast.error(error?.message || 'Failed to update vendor status');
    });
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Vendor Management</h1>
        <p className="text-sm text-muted-foreground">{vendors.length} vendors registered</p>
      </div>

      <Card>
        <CardHeader>
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input placeholder="Search vendors..." value={search} onChange={(e) => setSearch(e.target.value)} className="pl-9" />
          </div>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Vendor</TableHead>
                <TableHead>Owner</TableHead>
                <TableHead>Cuisine</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Rating</TableHead>
                <TableHead>Revenue</TableHead>
                <TableHead>Payout</TableHead>
                <TableHead>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {loading ? (
                <TableRow>
                  <TableCell colSpan={8} className="text-center text-sm text-muted-foreground">Loading vendors...</TableCell>
                </TableRow>
              ) : filtered.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={8} className="text-center text-sm text-muted-foreground">No vendors found.</TableCell>
                </TableRow>
              ) : filtered.map((v) => (
                <TableRow key={v.id} className="cursor-pointer" onClick={() => setSelectedVendor(v)}>
                  <TableCell className="font-medium">{v.name}</TableCell>
                  <TableCell className="text-muted-foreground">{v.ownerName}</TableCell>
                  <TableCell>{v.cuisine}</TableCell>
                  <TableCell><StatusBadge status={v.status} /></TableCell>
                  <TableCell>
                    {v.rating > 0 ? (
                      <span className="flex items-center gap-1 text-sm"><Star className="h-3 w-3 fill-amber-400 text-amber-400" />{v.rating}</span>
                    ) : "—"}
                  </TableCell>
                  <TableCell>₹{(v.revenue / 1000).toFixed(0)}K</TableCell>
                  <TableCell><StatusBadge status={v.payoutStatus} /></TableCell>
                  <TableCell>
                    <div className="flex gap-1" onClick={(e) => e.stopPropagation()}>
                      {v.status === "pending" && (
                        <>
                          <Button variant="ghost" size="icon" className="h-8 w-8" onClick={() => setReasonDialog({ open: true, vendorId: v.id, action: "approve" })}>
                            <CheckCircle className="h-4 w-4 text-emerald-600" />
                          </Button>
                          <Button variant="ghost" size="icon" className="h-8 w-8" onClick={() => setReasonDialog({ open: true, vendorId: v.id, action: "reject" })}>
                            <XCircle className="h-4 w-4 text-destructive" />
                          </Button>
                        </>
                      )}
                      {v.status === "approved" && (
                        <Button variant="ghost" size="icon" className="h-8 w-8" onClick={() => setReasonDialog({ open: true, vendorId: v.id, action: "suspend" })}>
                          <XCircle className="h-4 w-4 text-amber-600" />
                        </Button>
                      )}
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      <Sheet open={!!selectedVendor} onOpenChange={() => setSelectedVendor(null)}>
        <SheetContent>
          <SheetHeader>
            <SheetTitle>{selectedVendor?.name}</SheetTitle>
            <SheetDescription>{selectedVendor?.cuisine} • {selectedVendor?.ownerName}</SheetDescription>
          </SheetHeader>
          {selectedVendor && (
            <div className="mt-6 space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div><p className="text-xs text-muted-foreground">Email</p><p className="text-sm font-medium">{selectedVendor.email}</p></div>
                <div><p className="text-xs text-muted-foreground">Status</p><StatusBadge status={selectedVendor.status} /></div>
                <div><p className="text-xs text-muted-foreground">Rating</p><p className="text-sm font-medium">{selectedVendor.rating || "N/A"}</p></div>
                <div><p className="text-xs text-muted-foreground">Total Orders</p><p className="text-sm font-medium">{selectedVendor.totalOrders}</p></div>
                <div><p className="text-xs text-muted-foreground">Revenue</p><p className="text-sm font-medium">₹{selectedVendor.revenue.toLocaleString()}</p></div>
                <div><p className="text-xs text-muted-foreground">Pending Payout</p><p className="text-sm font-medium">₹{selectedVendor.pendingPayout.toLocaleString()}</p></div>
                <div><p className="text-xs text-muted-foreground">Joined</p><p className="text-sm font-medium">{selectedVendor.joinedAt}</p></div>
              </div>
            </div>
          )}
        </SheetContent>
      </Sheet>

      <ReasonCaptureDialog
        open={reasonDialog.open}
        onOpenChange={(open) => setReasonDialog((prev) => ({ ...prev, open }))}
        title={`${reasonDialog.action.charAt(0).toUpperCase() + reasonDialog.action.slice(1)} Vendor`}
        description={reasonDialog.action === 'approve' ? 'Approval will be applied immediately.' : 'This action will be recorded in the audit log. Provide a detailed reason (min 10 chars).'}
        actionLabel={reasonDialog.action.charAt(0).toUpperCase() + reasonDialog.action.slice(1)}
        variant={reasonDialog.action === "approve" ? "default" : "destructive"}
        onConfirm={handleAction}
      />
    </div>
  );
}
