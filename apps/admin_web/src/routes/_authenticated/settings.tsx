import { createFileRoute } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";
import { toast } from "sonner";
import { backendApi } from "@/lib/backend-api";
import { useAuth } from "@/lib/auth";

export const Route = createFileRoute("/_authenticated/settings")({
  component: SettingsPage,
});

function SettingsPage() {
  const { user } = useAuth();
  const [config, setConfig] = useState({
    deliveryRadius: "5",
    commissionRate: "10",
    otpTtl: "10",
    maxOtpAttempts: "5",
    maintenanceMode: false,
    newVendorAutoApprove: false,
    walletEnabled: true,
    referralsEnabled: true,
    loyaltyEnabled: false,
    groupOrdersEnabled: true,
  });

  const canEdit = user?.role === 'super_admin';

  useEffect(() => {
    let cancelled = false;

    const load = async () => {
      try {
        const response = await backendApi.get<{ settings?: { commission_rate?: number; delivery_fee?: number; support_email?: string } }>('/admin/settings');
        if (cancelled) return;

        const settings = response.settings;
        if (settings) {
          setConfig((prev) => ({
            ...prev,
            commissionRate: String(settings.commission_rate ?? prev.commissionRate),
          }));
        }
      } catch {
        if (!cancelled) {
          // Keep the current defaults if the backend settings endpoint is unavailable.
        }
      }
    };

    void load();
    return () => {
      cancelled = true;
    };
  }, []);

  const handleSave = async () => {
    if (!canEdit) {
      toast.error('Only super admin can update settings');
      return;
    }

    try {
      await backendApi.post('/admin/settings', {
        commission_rate: Number(config.commissionRate),
        delivery_fee: Number(config.deliveryRadius),
        otp_ttl_minutes: Number(config.otpTtl),
        max_otp_attempts: Number(config.maxOtpAttempts),
        maintenance_mode: config.maintenanceMode,
        new_vendor_auto_approve: config.newVendorAutoApprove,
        wallet_enabled: config.walletEnabled,
        referrals_enabled: config.referralsEnabled,
        loyalty_enabled: config.loyaltyEnabled,
        group_orders_enabled: config.groupOrdersEnabled,
      });
      toast.success("Settings saved", { description: "Changes will take effect immediately." });
    } catch (error: any) {
      toast.error(error?.message || 'Failed to save settings');
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Platform Settings</h1>
        <p className="text-sm text-muted-foreground">Configure platform behavior and feature flags</p>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Platform Configuration</CardTitle>
            <CardDescription>Core operational settings</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="radius">Delivery Radius (km)</Label>
              <Input id="radius" type="number" value={config.deliveryRadius} onChange={(e) => setConfig((p) => ({ ...p, deliveryRadius: e.target.value }))} />
            </div>
            <div className="space-y-2">
              <Label htmlFor="commission">Commission Rate (%)</Label>
              <Input id="commission" type="number" value={config.commissionRate} onChange={(e) => setConfig((p) => ({ ...p, commissionRate: e.target.value }))} />
            </div>
            <div className="space-y-2">
              <Label htmlFor="otp">OTP TTL (minutes)</Label>
              <Input id="otp" type="number" value={config.otpTtl} onChange={(e) => setConfig((p) => ({ ...p, otpTtl: e.target.value }))} />
            </div>
            <div className="space-y-2">
              <Label htmlFor="attempts">Max OTP Attempts</Label>
              <Input id="attempts" type="number" value={config.maxOtpAttempts} onChange={(e) => setConfig((p) => ({ ...p, maxOtpAttempts: e.target.value }))} />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">Feature Flags</CardTitle>
            <CardDescription>Toggle platform features</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {[
              { key: "maintenanceMode" as const, label: "Maintenance Mode", desc: "Disable platform for users" },
              { key: "newVendorAutoApprove" as const, label: "Auto-Approve Vendors", desc: "Skip manual vendor approval" },
              { key: "walletEnabled" as const, label: "Wallet", desc: "Enable in-app wallet for users" },
              { key: "referralsEnabled" as const, label: "Referrals", desc: "Allow user referral rewards" },
              { key: "loyaltyEnabled" as const, label: "Loyalty Program", desc: "Points-based rewards system" },
              { key: "groupOrdersEnabled" as const, label: "Group Orders", desc: "Enable group order splitting" },
            ].map((item) => (
              <div key={item.key} className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium">{item.label}</p>
                  <p className="text-xs text-muted-foreground">{item.desc}</p>
                </div>
                <Switch
                  checked={config[item.key]}
                  disabled={!canEdit}
                  onCheckedChange={(checked) => setConfig((p) => ({ ...p, [item.key]: checked }))}
                />
              </div>
            ))}
          </CardContent>
        </Card>
      </div>

      <Separator />

      <div className="flex justify-end">
        <Button onClick={handleSave} disabled={!canEdit}>Save Settings</Button>
      </div>

      {!canEdit && (
        <p className="text-sm text-muted-foreground">Settings are read-only for the current admin account.</p>
      )}
    </div>
  );
}
