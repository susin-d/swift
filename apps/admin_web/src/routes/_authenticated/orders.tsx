import { createFileRoute } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { StatusBadge } from "@/components/StatusBadge";
import { ReasonCaptureDialog } from "@/components/ReasonCaptureDialog";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetDescription } from "@/components/ui/sheet";
import { Search, XCircle } from "lucide-react";
import { toast } from "sonner";
import { backendApi } from "@/lib/backend-api";

type BackendOrder = {
  id: string;
  status?: string;
  created_at?: string;
  total_amount?: number;
  total?: number;
  payment_method?: string;
  paymentMethod?: string;
  delivered_at?: string;
  deliveredAt?: string;
  user?: { name?: string; email?: string };
  users?: { name?: string; email?: string };
  vendor?: { name?: string };
  vendors?: { name?: string };
  order_items?: Array<{ name?: string; quantity?: number; qty?: number; unit_price?: number; price?: number }>;
};

type OrderRow = {
  id: string;
  userName: string;
  vendorName: string;
  items: Array<{ name: string; qty: number; price: number }>;
  total: number;
  status: "placed" | "preparing" | "out_for_delivery" | "delivered" | "cancelled" | "refunded";
  placedAt: string;
  deliveredAt?: string;
  paymentMethod: string;
};

export const Route = createFileRoute("/_authenticated/orders")({
  component: OrdersPage,
});

function OrdersPage() {
  const [orders, setOrders] = useState<OrderRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [selectedOrder, setSelectedOrder] = useState<OrderRow | null>(null);
  const [reasonDialog, setReasonDialog] = useState<{ open: boolean; orderId: string; action: "cancel" }>({ open: false, orderId: "", action: "cancel" });

  useEffect(() => {
    let cancelled = false;

    const load = async () => {
      try {
        const response = await backendApi.get<{ orders?: BackendOrder[]; data?: BackendOrder[] }>('/admin/orders?limit=100');
        const list = response.orders || response.data || [];

        if (cancelled) return;

        setOrders(list.map((order) => {
          const items = (order.order_items || []).map((item, index) => ({
            name: item.name || `Item ${index + 1}`,
            qty: Number(item.qty ?? item.quantity ?? 1),
            price: Number(item.price ?? item.unit_price ?? 0),
          }));

          return {
            id: order.id,
            userName: order.user?.name || order.users?.name || order.user?.email || order.users?.email || 'Unknown',
            vendorName: order.vendor?.name || order.vendors?.name || 'Unknown',
            items,
            total: Number(order.total_amount ?? order.total ?? 0),
            status: (order.status || 'placed') as OrderRow['status'],
            placedAt: order.created_at || new Date().toISOString(),
            deliveredAt: order.delivered_at || order.deliveredAt,
            paymentMethod: order.payment_method || order.paymentMethod || 'unknown',
          };
        }));
      } catch {
        if (!cancelled) setOrders([]);
      } finally {
        if (!cancelled) setLoading(false);
      }
    };

    void load();
    return () => {
      cancelled = true;
    };
  }, []);

  const filtered = orders.filter((o) => {
    const matchesSearch = o.id.includes(search) || o.userName.toLowerCase().includes(search.toLowerCase()) || o.vendorName.toLowerCase().includes(search.toLowerCase());
    const matchesStatus = statusFilter === "all" || o.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const handleAction = (reason: string) => {
    const { orderId } = reasonDialog;
    void backendApi.patch(`/admin/orders/${orderId}/cancel`, { reason }).then(() => {
      setOrders((prev) => prev.map((order) => (order.id === orderId ? { ...order, status: 'cancelled' } : order)));
      toast.success('Order cancelled successfully', { description: `Reason: ${reason}` });
    }).catch((error: any) => {
      toast.error(error?.message || 'Failed to cancel order');
    });
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Order Management</h1>
        <p className="text-sm text-muted-foreground">{orders.length} total orders</p>
      </div>

      <Card>
        <CardHeader>
          <div className="flex flex-wrap items-center gap-3">
            <div className="relative flex-1 min-w-[200px]">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input placeholder="Search orders..." value={search} onChange={(e) => setSearch(e.target.value)} className="pl-9" />
            </div>
            <Select value={statusFilter} onValueChange={setStatusFilter}>
              <SelectTrigger className="w-[180px]">
                <SelectValue placeholder="Filter by status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All statuses</SelectItem>
                <SelectItem value="placed">Placed</SelectItem>
                <SelectItem value="preparing">Preparing</SelectItem>
                <SelectItem value="out_for_delivery">Out for Delivery</SelectItem>
                <SelectItem value="delivered">Delivered</SelectItem>
                <SelectItem value="cancelled">Cancelled</SelectItem>
                <SelectItem value="refunded">Refunded</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Order ID</TableHead>
                <TableHead>Customer</TableHead>
                <TableHead>Vendor</TableHead>
                <TableHead>Items</TableHead>
                <TableHead>Total</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Date</TableHead>
                <TableHead>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {loading ? (
                <TableRow>
                  <TableCell colSpan={8} className="text-center text-sm text-muted-foreground">Loading orders...</TableCell>
                </TableRow>
              ) : filtered.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={8} className="text-center text-sm text-muted-foreground">No orders found.</TableCell>
                </TableRow>
              ) : filtered.map((o) => (
                <TableRow key={o.id} className="cursor-pointer" onClick={() => setSelectedOrder(o)}>
                  <TableCell className="font-mono text-xs">{o.id}</TableCell>
                  <TableCell>{o.userName}</TableCell>
                  <TableCell>{o.vendorName}</TableCell>
                  <TableCell className="text-muted-foreground">{o.items.length} items</TableCell>
                  <TableCell>₹{o.total}</TableCell>
                  <TableCell><StatusBadge status={o.status} /></TableCell>
                  <TableCell className="text-muted-foreground">{new Date(o.placedAt).toLocaleDateString()}</TableCell>
                  <TableCell>
                    <div className="flex gap-1" onClick={(e) => e.stopPropagation()}>
                      {(o.status === "placed" || o.status === "preparing") && (
                        <Button variant="ghost" size="icon" className="h-8 w-8" onClick={() => setReasonDialog({ open: true, orderId: o.id, action: "cancel" })}>
                          <XCircle className="h-4 w-4 text-destructive" />
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

      <Sheet open={!!selectedOrder} onOpenChange={() => setSelectedOrder(null)}>
        <SheetContent>
          <SheetHeader>
            <SheetTitle>Order {selectedOrder?.id}</SheetTitle>
            <SheetDescription>{selectedOrder?.userName} → {selectedOrder?.vendorName}</SheetDescription>
          </SheetHeader>
          {selectedOrder && (
            <div className="mt-6 space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div><p className="text-xs text-muted-foreground">Status</p><StatusBadge status={selectedOrder.status} /></div>
                <div><p className="text-xs text-muted-foreground">Payment</p><p className="text-sm font-medium capitalize">{selectedOrder.paymentMethod}</p></div>
                <div><p className="text-xs text-muted-foreground">Placed</p><p className="text-sm font-medium">{new Date(selectedOrder.placedAt).toLocaleString()}</p></div>
                {selectedOrder.deliveredAt && <div><p className="text-xs text-muted-foreground">Delivered</p><p className="text-sm font-medium">{new Date(selectedOrder.deliveredAt).toLocaleString()}</p></div>}
              </div>
              <div>
                <p className="mb-2 text-xs font-medium text-muted-foreground">Items</p>
                {selectedOrder.items.map((item, i) => (
                  <div key={i} className="flex items-center justify-between border-b py-2 text-sm">
                    <span>{item.name} × {item.qty}</span>
                    <span>₹{item.price * item.qty}</span>
                  </div>
                ))}
                <div className="flex items-center justify-between pt-2 text-sm font-bold">
                  <span>Total</span>
                  <span>₹{selectedOrder.total}</span>
                </div>
              </div>
            </div>
          )}
        </SheetContent>
      </Sheet>

      <ReasonCaptureDialog
        open={reasonDialog.open}
        onOpenChange={(open) => setReasonDialog((prev) => ({ ...prev, open }))}
        title="Cancel Order"
        description="This action will be recorded in the audit log."
        actionLabel="Cancel Order"
        onConfirm={handleAction}
      />
    </div>
  );
}
