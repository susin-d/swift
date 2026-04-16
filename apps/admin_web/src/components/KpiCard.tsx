import { Card, CardContent } from "@/components/ui/card";
import type { LucideIcon } from "lucide-react";


interface KpiCardProps {
  title: string;
  value: string | number;
  subtitle?: string;
  icon: LucideIcon;
  trend?: { value: number; label: string };
  color?: string; // e.g. 'emerald', 'blue', 'orange', 'rose', 'violet'
}

export function KpiCard({ title, value, subtitle, icon: Icon, trend, color = "blue" }: KpiCardProps) {
  // Map color name to Tailwind color classes
  const colorMap: Record<string, { border: string; bg: string; icon: string }> = {
    emerald: { border: "border-emerald-500", bg: "bg-emerald-50", icon: "text-emerald-600" },
    blue: { border: "border-blue-500", bg: "bg-blue-50", icon: "text-blue-600" },
    orange: { border: "border-orange-500", bg: "bg-orange-50", icon: "text-orange-600" },
    rose: { border: "border-rose-500", bg: "bg-rose-50", icon: "text-rose-600" },
    violet: { border: "border-violet-500", bg: "bg-violet-50", icon: "text-violet-600" },
    indigo: { border: "border-indigo-500", bg: "bg-indigo-50", icon: "text-indigo-600" },
    teal: { border: "border-teal-500", bg: "bg-teal-50", icon: "text-teal-600" },
    pink: { border: "border-pink-500", bg: "bg-pink-50", icon: "text-pink-600" },
    yellow: { border: "border-yellow-500", bg: "bg-yellow-50", icon: "text-yellow-600" },
  };
  const c = colorMap[color] || colorMap.blue;
  return (
    <Card className={`border-l-8 ${c.border} shadow-sm`}>
      <CardContent className={`p-6 ${c.bg}`}>
        <div className="flex items-center justify-between">
          <div className="space-y-1">
            <p className="text-sm font-medium text-muted-foreground">{title}</p>
            <p className="text-2xl font-bold tracking-tight">{value}</p>
            {subtitle && <p className="text-xs text-muted-foreground">{subtitle}</p>}
            {trend && (
              <p className={`text-xs font-medium ${trend.value >= 0 ? "text-emerald-600" : "text-red-600"}`}>
                {trend.value >= 0 ? "↑" : "↓"} {Math.abs(trend.value)}% {trend.label}
              </p>
            )}
          </div>
          <div className={`rounded-lg ${c.bg} p-3`}>
            <Icon className={`h-5 w-5 ${c.icon}`} />
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
