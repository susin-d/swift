import { Link, useLocation } from 'react-router-dom'
import { useAuth } from '../context/useAuth.js'

const navItems = [
  { label: 'Overview', to: '/dashboard' },
  { label: 'Orders', to: '/dashboard?tab=orders' },
  { label: 'Vendors', to: '/dashboard?tab=vendors' },
  { label: 'Users', to: '/dashboard?tab=users' },
  { label: 'Settings', to: '/dashboard?tab=settings' },
]

function Sidebar() {
  const location = useLocation()
  const { user, signOut } = useAuth()

  return (
    <aside className="sidebar" aria-label="Main navigation">
      <div className="brand-block">
        <span className="brand-kicker">Swift Ops</span>
        <h1>Admin Console</h1>
      </div>

      <nav>
        {navItems.map((item) => {
          const targetSearch = item.to.replace('/dashboard', '')
          const isActive =
            location.pathname === '/dashboard' &&
            (targetSearch ? location.search === targetSearch : location.search === '')

          return (
            <Link
              key={item.label}
              to={item.to}
              className={`nav-item ${isActive ? 'active' : ''}`}
            >
              {item.label}
            </Link>
          )
        })}
      </nav>

      <div className="status-card">
        <p>{user?.email ?? 'Admin session'}</p>
        <strong>All services operational</strong>
        <button className="btn btn-ghost sidebar-logout" type="button" onClick={signOut}>
          Sign out
        </button>
      </div>
    </aside>
  )
}

export default Sidebar

