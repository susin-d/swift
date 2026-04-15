import { Link } from 'react-router-dom'

const commandSignals = [
  { label: 'Live Orders', value: '1,284', delta: '+12%' },
  { label: 'SLA Breach Risk', value: '04', delta: '-2' },
  { label: 'Active Vendors', value: '93', delta: '+7' },
]

const quickActions = [
  'Escalation Queue',
  'Vendor Approvals',
  'Fraud Flags',
  'Payout Holds',
]

const workflowCards = [
  {
    title: 'Detect',
    text: 'Identify delivery bottlenecks, payout drift, and risk spikes in one feed.',
  },
  {
    title: 'Decide',
    text: 'Approve vendors, triage incidents, and route decisions with audit-safe actions.',
  },
  {
    title: 'Deploy',
    text: 'Push corrective actions quickly and watch impact in near real time.',
  },
]

const reliabilityStats = [
  { label: 'Admin Actions Logged', value: '100%' },
  { label: 'Role-Gated Endpoints', value: 'All Critical' },
  { label: 'Ops Visibility', value: 'Live' },
]

function LandingPage() {
  return (
    <main className="landing-page">
      <div className="landing-stack">
        <section className="landing-screen landing-hero">
          <div className="hero-copy command-copy">
            <p className="eyebrow">Swift Control Layer</p>
            <h1>Orchestrate Every Campus Shift From One Command Surface.</h1>
            <p>
              Coordinate approvals, queue pressure, and revenue response in a
              high-velocity admin interface tuned for operations teams.
            </p>
            <div className="hero-actions">
              <Link className="btn btn-primary" to="/login">
                Enter Admin
              </Link>
              <Link className="btn btn-ghost" to="/dashboard">
                View Live Console
              </Link>
            </div>

            <div className="hero-marquee" aria-label="Operational focus areas">
              {quickActions.map((item) => (
                <span key={item}>{item}</span>
              ))}
            </div>
          </div>

          <div className="hero-panel command-panel" aria-label="Key metrics preview">
            <header>
              <p className="eyebrow">Live Ops Snapshot</p>
              <h2>Signal Board</h2>
            </header>
            <div className="signal-grid">
              {commandSignals.map((signal) => (
                <article key={signal.label}>
                  <span>{signal.label}</span>
                  <strong>{signal.value}</strong>
                  <small>{signal.delta} vs last shift</small>
                </article>
              ))}
            </div>
            <div className="pulse-row">
              <p>System pulse: Stable</p>
              <span />
            </div>
          </div>
        </section>

        <section className="landing-screen workflow-screen" aria-labelledby="workflow-title">
          <div className="screen-shell">
            <p className="eyebrow">How Teams Operate</p>
            <h2 id="workflow-title">A Fast Loop For Daily Operations</h2>
            <p>
              Built to keep teams decisive during demand spikes, with clear
              progression from signal to execution.
            </p>
            <div className="workflow-grid">
              {workflowCards.map((card) => (
                <article key={card.title} className="workflow-card">
                  <h3>{card.title}</h3>
                  <p>{card.text}</p>
                </article>
              ))}
            </div>
          </div>
        </section>

        <section className="landing-screen reliability-screen" aria-labelledby="reliability-title">
          <div className="screen-shell">
            <p className="eyebrow">Reliability Layer</p>
            <h2 id="reliability-title">Secure By Design, Ready For Scale</h2>
            <p>
              Admin workflows remain protected with role checks, auditable action
              trails, and backend-synced visibility.
            </p>
            <div className="reliability-grid">
              {reliabilityStats.map((stat) => (
                <article key={stat.label} className="reliability-card">
                  <span>{stat.label}</span>
                  <strong>{stat.value}</strong>
                </article>
              ))}
            </div>
            <div className="hero-actions">
              <Link className="btn btn-primary" to="/login">
                Start Managing
              </Link>
            </div>
          </div>
        </section>
      </div>
    </main>
  )
}

export default LandingPage
