import { createFileRoute } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { StatusBadge } from "@/components/StatusBadge";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetDescription } from "@/components/ui/sheet";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { toast } from "sonner";
import { backendApi } from "@/lib/backend-api";

type BackendTicket = {
  id: string;
  subject: string;
  description: string;
  priority: 'low' | 'normal' | 'high' | 'urgent';
  status: 'open' | 'in_progress' | 'resolved' | 'closed';
  user_id: string;
  assignee_id: string | null;
  resolution_note: string | null;
  created_at: string;
  updated_at: string;
};

type TicketTimelineEvent = {
  id: string;
  eventType: string;
  payload: Record<string, unknown>;
  createdAt: string;
};

type TicketRow = {
  id: string;
  userName: string;
  subject: string;
  description: string;
  priority: BackendTicket['priority'];
  status: BackendTicket['status'];
  createdAt: string;
  assignedTo?: string | null;
  resolutionNote?: string | null;
  userId: string;
};

export const Route = createFileRoute("/_authenticated/support")({
  component: SupportPage,
});

function SupportPage() {
  const [tickets, setTickets] = useState<TicketRow[]>([]);
  const [selectedTicket, setSelectedTicket] = useState<TicketRow | null>(null);
  const [timeline, setTimeline] = useState<TicketTimelineEvent[]>([]);
  const [loading, setLoading] = useState(true);
  const [broadcast, setBroadcast] = useState({
    title: '',
    body: '',
    audience: 'both' as 'user' | 'vendor' | 'both',
    type: 'general',
    sending: false,
  });

  useEffect(() => {
    let cancelled = false;

    const load = async () => {
      try {
        const response = await backendApi.get<{ tickets?: BackendTicket[] }>('/admin/support/tickets?limit=100');
        if (cancelled) return;

        setTickets((response.tickets || []).map((ticket) => ({
          id: ticket.id,
          userName: ticket.user_id,
          subject: ticket.subject,
          description: ticket.description,
          priority: ticket.priority,
          status: ticket.status,
          createdAt: ticket.created_at,
          assignedTo: ticket.assignee_id,
          resolutionNote: ticket.resolution_note,
          userId: ticket.user_id,
        })));
      } catch {
        if (!cancelled) setTickets([]);
      } finally {
        if (!cancelled) setLoading(false);
      }
    };

    void load();
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    if (!selectedTicket) {
      setTimeline([]);
      return;
    }

    let cancelled = false;

    const loadTimeline = async () => {
      try {
        const response = await backendApi.get<{ events?: Array<{ id: string; eventType: string; payload: Record<string, unknown>; createdAt: string }> }>(`/admin/support/tickets/${selectedTicket.id}/timeline`);
        if (cancelled) return;
        setTimeline((response.events || []).map((event) => ({ ...event })));
      } catch {
        if (!cancelled) setTimeline([]);
      }
    };

    void loadTimeline();
    return () => {
      cancelled = true;
    };
  }, [selectedTicket]);

  const updateStatus = (id: string, status: BackendTicket["status"]) => {
    void backendApi.patch(`/admin/support/tickets/${id}`, { status }).then(() => {
      setTickets((prev) => prev.map((ticket) => (ticket.id === id ? { ...ticket, status } : ticket)));
      toast.success(`Ticket ${status.replace("_", " ")}`);
    }).catch((error: any) => {
      toast.error(error?.message || 'Failed to update ticket');
    });
  };

  const sendBroadcast = async () => {
    if (!broadcast.title.trim() || !broadcast.body.trim()) {
      toast.error('Title and body are required');
      return;
    }

    setBroadcast((prev) => ({ ...prev, sending: true }));
    try {
      const response = await backendApi.post<{ message?: string; sent?: number; recipients?: number }>(
        '/admin/notifications/broadcast',
        {
          title: broadcast.title.trim(),
          body: broadcast.body.trim(),
          audience: broadcast.audience,
          type: broadcast.type.trim() || 'general',
          metadata: {
            source: 'admin_web',
          },
        },
      );

      toast.success(response.message || 'Notification sent', {
        description: `${response.sent ?? 0} delivered to ${response.recipients ?? 0} recipients.`,
      });
      setBroadcast({ title: '', body: '', audience: 'both', type: 'general', sending: false });
    } catch (error: any) {
      toast.error(error?.message || 'Failed to send notification');
      setBroadcast((prev) => ({ ...prev, sending: false }));
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Support Tickets</h1>
        <p className="text-sm text-muted-foreground">{tickets.filter((t) => t.status === "open" || t.status === "in_progress").length} open tickets</p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Broadcast Notification</CardTitle>
          <CardDescription>Send an update to users, vendors, or both roles from one place.</CardDescription>
        </CardHeader>
        <CardContent className="grid gap-4 lg:grid-cols-[1.2fr_1fr_auto]">
          <div className="space-y-2 lg:col-span-2">
            <Label htmlFor="broadcast-title">Title</Label>
            <Input
              id="broadcast-title"
              value={broadcast.title}
              onChange={(event) => setBroadcast((prev) => ({ ...prev, title: event.target.value }))}
              placeholder="Campus lunch update"
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="broadcast-type">Type</Label>
            <Input
              id="broadcast-type"
              value={broadcast.type}
              onChange={(event) => setBroadcast((prev) => ({ ...prev, type: event.target.value }))}
              placeholder="general"
            />
          </div>
          <div className="space-y-2 lg:col-span-3">
            <Label htmlFor="broadcast-body">Message</Label>
            <Textarea
              id="broadcast-body"
              value={broadcast.body}
              onChange={(event) => setBroadcast((prev) => ({ ...prev, body: event.target.value }))}
              placeholder="Tell users and vendors about the active offer or service update."
              className="min-h-[108px]"
            />
          </div>
          <div className="space-y-2">
            <Label>Audience</Label>
            <Select value={broadcast.audience} onValueChange={(value) => setBroadcast((prev) => ({ ...prev, audience: value as 'user' | 'vendor' | 'both' }))}>
              <SelectTrigger>
                <SelectValue placeholder="Choose audience" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="both">Users + Vendors</SelectItem>
                <SelectItem value="user">Users only</SelectItem>
                <SelectItem value="vendor">Vendors only</SelectItem>
              </SelectContent>
            </Select>
          </div>
          <div className="flex items-end">
            <Button onClick={sendBroadcast} disabled={broadcast.sending} className="w-full lg:w-auto">
              {broadcast.sending ? 'Sending...' : 'Send notification'}
            </Button>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader />
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>ID</TableHead>
                <TableHead>User</TableHead>
                <TableHead>Subject</TableHead>
                <TableHead>Priority</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Created</TableHead>
                <TableHead>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {loading ? (
                <TableRow>
                  <TableCell colSpan={7} className="text-center text-sm text-muted-foreground">Loading support tickets...</TableCell>
                </TableRow>
              ) : tickets.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={7} className="text-center text-sm text-muted-foreground">No support tickets found.</TableCell>
                </TableRow>
              ) : tickets.map((t) => (
                <TableRow key={t.id} className="cursor-pointer" onClick={() => setSelectedTicket(t)}>
                  <TableCell className="font-mono text-xs">{t.id}</TableCell>
                  <TableCell>{t.userName}</TableCell>
                  <TableCell className="max-w-[200px] truncate">{t.subject}</TableCell>
                  <TableCell><StatusBadge status={t.priority} /></TableCell>
                  <TableCell><StatusBadge status={t.status} /></TableCell>
                  <TableCell className="text-muted-foreground">{new Date(t.createdAt).toLocaleDateString()}</TableCell>
                  <TableCell>
                    <div onClick={(e) => e.stopPropagation()}>
                      <Select value={t.status} onValueChange={(v) => updateStatus(t.id, v as BackendTicket["status"])}>
                        <SelectTrigger className="h-8 w-[130px]">
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="open">Open</SelectItem>
                          <SelectItem value="in_progress">In Progress</SelectItem>
                          <SelectItem value="resolved">Resolved</SelectItem>
                          <SelectItem value="closed">Closed</SelectItem>
                        </SelectContent>
                      </Select>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      <Sheet open={!!selectedTicket} onOpenChange={() => setSelectedTicket(null)}>
        <SheetContent className="sm:max-w-lg">
          <SheetHeader>
            <SheetTitle>{selectedTicket?.subject}</SheetTitle>
            <SheetDescription>{selectedTicket?.userName} • {selectedTicket?.id}</SheetDescription>
          </SheetHeader>
          {selectedTicket && (
            <div className="mt-6 space-y-4">
              <div className="flex gap-2">
                <StatusBadge status={selectedTicket.priority} />
                <StatusBadge status={selectedTicket.status} />
              </div>
              <div className="space-y-3">
                <div className="grid grid-cols-2 gap-4 rounded-lg border p-4">
                  <div><p className="text-xs text-muted-foreground">Description</p><p className="text-sm font-medium">{selectedTicket.description}</p></div>
                  <div><p className="text-xs text-muted-foreground">Assigned To</p><p className="text-sm font-medium">{selectedTicket.assignedTo || 'Unassigned'}</p></div>
                  <div><p className="text-xs text-muted-foreground">Resolution Note</p><p className="text-sm font-medium">{selectedTicket.resolutionNote || '—'}</p></div>
                  <div><p className="text-xs text-muted-foreground">Created</p><p className="text-sm font-medium">{new Date(selectedTicket.createdAt).toLocaleString()}</p></div>
                </div>
                <p className="text-xs font-medium text-muted-foreground">Timeline</p>
                {timeline.length === 0 ? (
                  <p className="text-sm text-muted-foreground">No timeline entries available.</p>
                ) : timeline.map((event) => (
                  <div key={event.id} className="rounded-lg bg-muted p-3 text-sm">
                    <p className="mb-1 text-xs font-medium">{event.eventType.replace(/_/g, ' ')}</p>
                    <pre className="whitespace-pre-wrap text-xs text-muted-foreground">{JSON.stringify(event.payload, null, 2)}</pre>
                    <p className="mt-1 text-xs text-muted-foreground">{new Date(event.createdAt).toLocaleString()}</p>
                  </div>
                ))}
              </div>
            </div>
          )}
        </SheetContent>
      </Sheet>
    </div>
  );
}
