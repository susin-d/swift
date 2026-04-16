import { createFileRoute, Link } from "@tanstack/react-router";
import { Button } from "@/components/ui/button";
import { Shield, BarChart3, Users, CreditCard, ArrowRight, Zap } from "lucide-react";

export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "Swift Admin Portal — Logistics & Delivery Platform" },
      { name: "description", content: "Manage vendors, orders, finance, and users on the Swift delivery platform." },
    ],
  }),
  component: LandingPage,
});

const features = [
  { icon: Shield, title: "Moderation", desc: "Block users, approve vendors, enforce policies with full audit trail." },
  { icon: BarChart3, title: "Analytics", desc: "Real-time KPIs, revenue trends, and order volume insights." },
  { icon: CreditCard, title: "Finance", desc: "Track payouts, commissions, refunds, and wallet balances." },
  { icon: Users, title: "User Management", desc: "Full lifecycle management of students, vendors, and delivery partners." },
];

function LandingPage() {
  return (
    <div className="min-h-screen bg-background">
      {/* Nav */}
      <header className="border-b">
        <div className="mx-auto flex h-16 max-w-6xl items-center justify-between px-4">
          <div className="flex items-center gap-2">
            <Zap className="h-6 w-6 text-primary" />
            <span className="text-xl font-bold">Swift</span>
            <span className="rounded bg-primary/10 px-2 py-0.5 text-xs font-semibold text-primary">Admin</span>
          </div>
          <Link to="/login">
            <Button>Sign In</Button>
          </Link>
        </div>
      </header>

      {/* Hero */}
      <section className="mx-auto max-w-6xl px-4 py-24 text-center">
        <div className="mx-auto max-w-2xl">
          <h1 className="text-4xl font-bold tracking-tight sm:text-5xl">
            Command center for your
            <span className="text-primary"> delivery platform</span>
          </h1>
          <p className="mt-4 text-lg text-muted-foreground">
            Monitor operations, moderate content, manage finances, and govern your Swift food delivery ecosystem — all from one place.
          </p>
          <div className="mt-8 flex items-center justify-center gap-4">
            <Link to="/login">
              <Button size="lg" className="gap-2">
                Go to Dashboard <ArrowRight className="h-4 w-4" />
              </Button>
            </Link>
          </div>
          <p className="mt-4 text-xs text-muted-foreground">
            Sign in with a backend-managed admin account.
          </p>
        </div>
      </section>

      {/* Features */}
      <section className="border-t bg-muted/30 py-20">
        <div className="mx-auto max-w-6xl px-4">
          <h2 className="mb-12 text-center text-2xl font-bold">Everything you need to operate</h2>
          <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
            {features.map((f) => (
              <div key={f.title} className="rounded-xl border bg-card p-6">
                <div className="mb-4 inline-flex rounded-lg bg-primary/10 p-3">
                  <f.icon className="h-5 w-5 text-primary" />
                </div>
                <h3 className="mb-2 font-semibold">{f.title}</h3>
                <p className="text-sm text-muted-foreground">{f.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t py-8 text-center text-sm text-muted-foreground">
        <p>© 2025 Swift Platform. All rights reserved.</p>
      </footer>
    </div>
  );
}
