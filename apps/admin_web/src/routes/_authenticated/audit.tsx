import { createFileRoute } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Search } from "lucide-react";
import { backendApi } from "@/lib/backend-api";

type BackendAuditRow = {
  id: string;
  action?: string;
  action_performed?: string;
  target?: string;
  entity_id?: string;
  reason?: string;
  details?: { reason?: string };
  created_at?: string;
  admin?: { name?: string; email?: string };
  admin_id?: string;
};

type AuditRow = {
  id: string;
  admin: string;
  action: string;
  target: string;
  reason: string;
  timestamp: string;
};

export const Route = createFileRoute("/_authenticated/audit")({
  component: AuditPage,
});

const actionColors: Record<string, string> = {
  block_user: "bg-red-100 text-red-700",
  unblock_user: "bg-emerald-100 text-emerald-700",
  approve_vendor: "bg-emerald-100 text-emerald-700",
  reject_vendor: "bg-red-100 text-red-700",
  suspend_vendor: "bg-amber-100 text-amber-700",
  cancel_order: "bg-red-100 text-red-700",
  process_refund: "bg-amber-100 text-amber-700",
  update_settings: "bg-blue-100 text-blue-700",
  vendor_payout: "bg-emerald-100 text-emerald-700",
};

function AuditPage() {
  const [search, setSearch] = useState("");
  const [logs, setLogs] = useState<AuditRow[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;

    const load = async () => {
      try {
        const response = await backendApi.get<{ data?: BackendAuditRow[] }>('/admin/audit-logs?limit=100&offset=0');
        if (cancelled) return;

        setLogs((response.data || []).map((entry) => ({
          id: entry.id,
          admin: entry.admin?.name || entry.admin?.email || entry.admin_id || 'System',
          action: entry.action || entry.action_performed || 'unknown',
          target: entry.target || entry.entity_id || '—',
          reason: entry.reason || entry.details?.reason || '—',
          timestamp: entry.created_at || new Date().toISOString(),
        })));
      } catch {
        if (!cancelled) setLogs([]);
      } finally {
        if (!cancelled) setLoading(false);
      }
    };

    void load();
    return () => {
      cancelled = true;
    };
  }, []);

  const filtered = logs.filter((e) =>
    e.action.includes(search.toLowerCase()) ||
    e.target.toLowerCase().includes(search.toLowerCase()) ||
    e.reason.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Audit Log</h1>
        <p className="text-sm text-muted-foreground">Complete history of admin actions</p>
      </div>

      <Card>
        <CardHeader>
          <div className="relative">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input placeholder="Search audit entries..." value={search} onChange={(e) => setSearch(e.target.value)} className="pl-9" />
          </div>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Timestamp</TableHead>
                <TableHead>Admin</TableHead>
                <TableHead>Action</TableHead>
                <TableHead>Target</TableHead>
                <TableHead className="max-w-[300px]">Reason</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {loading ? (
                <TableRow>
                  <TableCell colSpan={5} className="text-center text-sm text-muted-foreground">Loading audit logs...</TableCell>
                </TableRow>
              ) : filtered.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={5} className="text-center text-sm text-muted-foreground">No audit logs found.</TableCell>
                </TableRow>
              ) : filtered.map((e) => (
                <TableRow key={e.id}>
                  <TableCell className="text-muted-foreground whitespace-nowrap">{new Date(e.timestamp).toLocaleString()}</TableCell>
                  <TableCell className="font-medium">{e.admin}</TableCell>
                  <TableCell>
                    <Badge variant="outline" className={actionColors[e.action] || ""}>
                      {e.action.replace(/_/g, " ")}
                    </Badge>
                  </TableCell>
                  <TableCell>{e.target}</TableCell>
                  <TableCell className="max-w-[300px] text-sm text-muted-foreground">{e.reason}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}
