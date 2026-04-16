import { createFileRoute } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { StatusBadge } from "@/components/StatusBadge";
import { ReasonCaptureDialog } from "@/components/ReasonCaptureDialog";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetDescription } from "@/components/ui/sheet";
import { Search, Ban, CheckCircle } from "lucide-react";
import { toast } from "sonner";
import { backendApi } from "@/lib/backend-api";

type BackendUser = {
  id: string;
  name?: string;
  email?: string;
  role?: string;
  created_at?: string;
  blocked?: boolean;
};

type UserRow = {
  id: string;
  name: string;
  email: string;
  phone: string;
  status: "active" | "blocked" | "pending_deletion";
  joinedAt: string;
  totalOrders: number;
  totalSpent: number;
  role: string;
};

export const Route = createFileRoute("/_authenticated/users")({
  component: UsersPage,
});

function UsersPage() {
  const [users, setUsers] = useState<UserRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [selectedUser, setSelectedUser] = useState<UserRow | null>(null);
  const [reasonDialog, setReasonDialog] = useState<{ open: boolean; userId: string; action: "block" | "unblock" }>({ open: false, userId: "", action: "block" });

  useEffect(() => {
    let cancelled = false;

    const load = async () => {
      try {
        const response = await backendApi.get<{ users: BackendUser[] }>('/admin/users?limit=100');
        if (cancelled) return;

        setUsers((response.users || []).map((user) => ({
          id: user.id,
          name: user.name || user.email || user.id,
          email: user.email || '',
          phone: '—',
          status: user.blocked ? 'blocked' : 'active',
          joinedAt: user.created_at ? new Date(user.created_at).toLocaleDateString() : '—',
          totalOrders: 0,
          totalSpent: 0,
          role: user.role || 'user',
        })));
      } catch {
        if (!cancelled) setUsers([]);
      } finally {
        if (!cancelled) setLoading(false);
      }
    };

    void load();
    return () => {
      cancelled = true;
    };
  }, []);

  const filtered = users.filter((u) =>
    u.name.toLowerCase().includes(search.toLowerCase()) ||
    u.email.toLowerCase().includes(search.toLowerCase())
  );

  const handleAction = (reason: string) => {
    const { userId, action } = reasonDialog;
    const blocked = action === 'block';

    console.log(`Attempting to ${action} user ${userId} with reason:`, reason);
    
    void backendApi.patch(`/admin/users/${userId}/block`, { blocked, reason }).then(() => {
      console.log(`Successfully ${action}ed user ${userId}`);
      setUsers((prev) => prev.map((user) => (user.id === userId ? { ...user, status: blocked ? 'blocked' : 'active' } : user)));
      toast.success(`User ${blocked ? 'blocked' : 'unblocked'} successfully`, { description: `Reason: ${reason}` });
    }).catch((error: any) => {
      console.error(`Failed to ${action} user ${userId}:`, error);
      toast.error(error?.message || 'Failed to update user status');
    });
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">User Management</h1>
        <p className="text-sm text-muted-foreground">{users.length} registered users</p>
      </div>

      <Card>
        <CardHeader>
          <div className="flex items-center gap-3">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input placeholder="Search users..." value={search} onChange={(e) => setSearch(e.target.value)} className="pl-9" />
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Name</TableHead>
                <TableHead>Email</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Role</TableHead>
                <TableHead>Joined</TableHead>
                <TableHead>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {loading ? (
                <TableRow>
                  <TableCell colSpan={6} className="text-center text-sm text-muted-foreground">Loading users...</TableCell>
                </TableRow>
              ) : filtered.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={6} className="text-center text-sm text-muted-foreground">No users found.</TableCell>
                </TableRow>
              ) : filtered.map((u) => (
                <TableRow key={u.id} className="cursor-pointer" onClick={() => setSelectedUser(u)}>
                  <TableCell className="font-medium">{u.name}</TableCell>
                  <TableCell className="text-muted-foreground">{u.email}</TableCell>
                  <TableCell><StatusBadge status={u.status} /></TableCell>
                  <TableCell>{u.role}</TableCell>
                  <TableCell className="text-muted-foreground">{u.joinedAt}</TableCell>
                  <TableCell>
                    <div className="flex gap-1" onClick={(e) => e.stopPropagation()}>
                      {u.status === "active" ? (
                        <Button variant="ghost" size="icon" className="h-8 w-8" onClick={() => setReasonDialog({ open: true, userId: u.id, action: "block" })}>
                          <Ban className="h-4 w-4 text-destructive" />
                        </Button>
                      ) : u.status === "blocked" ? (
                        <Button variant="ghost" size="icon" className="h-8 w-8" onClick={() => setReasonDialog({ open: true, userId: u.id, action: "unblock" })}>
                          <CheckCircle className="h-4 w-4 text-emerald-600" />
                        </Button>
                      ) : null}
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      {/* User Detail Sheet */}
      <Sheet open={!!selectedUser} onOpenChange={() => setSelectedUser(null)}>
        <SheetContent>
          <SheetHeader>
            <SheetTitle>{selectedUser?.name}</SheetTitle>
            <SheetDescription>{selectedUser?.email}</SheetDescription>
          </SheetHeader>
          {selectedUser && (
            <div className="mt-6 space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div><p className="text-xs text-muted-foreground">Phone</p><p className="text-sm font-medium">{selectedUser.phone}</p></div>
                <div><p className="text-xs text-muted-foreground">Status</p><StatusBadge status={selectedUser.status} /></div>
                <div><p className="text-xs text-muted-foreground">Role</p><p className="text-sm font-medium">{selectedUser.role}</p></div>
                <div><p className="text-xs text-muted-foreground">Total Orders</p><p className="text-sm font-medium">{selectedUser.totalOrders}</p></div>
                <div><p className="text-xs text-muted-foreground">Total Spent</p><p className="text-sm font-medium">₹{selectedUser.totalSpent.toLocaleString()}</p></div>
                <div><p className="text-xs text-muted-foreground">Joined</p><p className="text-sm font-medium">{selectedUser.joinedAt}</p></div>
              </div>
            </div>
          )}
        </SheetContent>
      </Sheet>

      <ReasonCaptureDialog
        open={reasonDialog.open}
        onOpenChange={(open) => setReasonDialog((prev) => ({ ...prev, open }))}
        title={`${reasonDialog.action.charAt(0).toUpperCase() + reasonDialog.action.slice(1)} User`}
        description="This action will be recorded in the audit log. Please provide a reason."
        actionLabel={reasonDialog.action.charAt(0).toUpperCase() + reasonDialog.action.slice(1)}
        onConfirm={handleAction}
      />
    </div>
  );
}
