import { useEffect, useState } from 'react'
import Sidebar from '../components/Sidebar.jsx'
import { useAuth } from '../context/useAuth.js'
import { getAdminStats, getRecentOrders } from '../services/apiClient.js'

function toCurrency(value) {
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    maximumFractionDigits: 0,
  }).format(value ?? 0)
}

function DashboardPage() {
  const { token } = useAuth()
  const [stats, setStats] = useState(null)
  const [orders, setOrders] = useState([])
  const [isLoading, setIsLoading] = useState(true)
  const [loadError, setLoadError] = useState('')

  useEffect(() => {
    let ignore = false

    async function loadDashboard() {
      setIsLoading(true)
      setLoadError('')

      try {
        const [statsPayload, ordersPayload] = await Promise.all([
          getAdminStats(token),
          getRecentOrders(token),
        ])

        if (ignore) {
          return
        }

        setStats(statsPayload?.stats ?? null)
        setOrders(ordersPayload?.orders ?? [])
      } catch (error) {
        if (!ignore) {
          setLoadError(error.message ?? 'Failed to load dashboard data')
        }
      } finally {
        if (!ignore) {
          setIsLoading(false)
        }
      }
    }

    loadDashboard()
    return () => {
      ignore = true
    }
  }, [token])

  const kpiCards = [
    { label: 'Users', value: stats?.users ?? 0 },
    { label: 'Vendors', value: stats?.vendors ?? 0 },
    { label: 'Orders', value: stats?.orders ?? 0 },
    { label: 'Revenue', value: toCurrency(stats?.revenue ?? stats?.gmv ?? 0) },
  ]

  return (
    <main className="dashboard-page">
      <Sidebar />

      <section className="dashboard-content">
        <header>
          <p className="eyebrow">Operations</p>
          <h2>Live Dashboard</h2>
          <p>Live pulse of orders, vendors, users, and revenue.</p>
        </header>

        {loadError ? (
          <p className="status-banner" role="alert">
            {loadError}
          </p>
        ) : null}

        <div className="kpi-grid" aria-label="Dashboard key metrics">
          {kpiCards.map((card) => (
            <article key={card.label} className="kpi-card">
              <span>{card.label}</span>
              <strong>{card.value}</strong>
              <small>{isLoading ? 'Loading from backend...' : 'Synced from backend'}</small>
            </article>
          ))}
        </div>

        <section className="table-card" aria-label="Recent order queue">
          <h3>Order Queue</h3>
          <table>
            <thead>
              <tr>
                <th>ID</th>
                <th>Vendor</th>
                <th>Status</th>
                <th>ETA</th>
              </tr>
            </thead>
            <tbody>
              {orders.map((row) => (
                <tr key={row.id}>
                  <td>{row.id}</td>
                  <td>{row.vendor_name ?? row.vendor?.name ?? 'Unknown vendor'}</td>
                  <td>{row.status ?? 'pending'}</td>
                  <td>{row.eta?.max_minutes ? `${row.eta.max_minutes}m` : '--'}</td>
                </tr>
              ))}
            </tbody>
          </table>
          {!isLoading && orders.length === 0 ? (
            <p className="table-empty">No active orders right now.</p>
          ) : null}
        </section>
      </section>
    </main>
  )
}

export default DashboardPage

