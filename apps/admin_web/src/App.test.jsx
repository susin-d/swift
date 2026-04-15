import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import App from './App.jsx'

const SESSION_KEY = 'swift.admin.session'

function renderAt(path) {
  render(
    <MemoryRouter initialEntries={[path]}>
      <App />
    </MemoryRouter>,
  )
}

function okJson(data) {
  return {
    ok: true,
    text: async () => JSON.stringify(data),
  }
}

describe('admin web routes', () => {
  beforeEach(() => {
    localStorage.clear()
    vi.restoreAllMocks()
  })

  it('renders landing page by default', () => {
    renderAt('/')

    expect(
      screen.getByRole('heading', {
        name: /orchestrate every campus shift from one command surface/i,
      }),
    ).toBeInTheDocument()
  })

  it('renders login page', () => {
    renderAt('/login')

    expect(
      screen.getByRole('heading', {
        name: /admin login/i,
      }),
    ).toBeInTheDocument()
  })

  it('redirects dashboard to login when not authenticated', () => {
    renderAt('/dashboard')

    expect(
      screen.getByRole('heading', {
        name: /admin login/i,
      }),
    ).toBeInTheDocument()
  })

  it('logs in admin user and navigates to dashboard', async () => {
    vi.stubGlobal(
      'fetch',
      vi
        .fn()
        .mockResolvedValueOnce(
          okJson({
            user: { id: 'admin-1', email: 'ops@swift.app', role: 'admin' },
            session: { access_token: 'token-123' },
          }),
        )
        .mockResolvedValueOnce(
          okJson({
            stats: { users: 10, vendors: 4, orders: 7, revenue: 1200, gmv: 1200 },
          }),
        )
        .mockResolvedValueOnce(okJson({ orders: [] })),
    )

    renderAt('/login')

    fireEvent.change(screen.getByLabelText(/email/i), {
      target: { value: 'ops@swift.app' },
    })
    fireEvent.change(screen.getByLabelText(/password/i), {
      target: { value: 'secure1234' },
    })
    fireEvent.click(screen.getByRole('button', { name: /sign in/i }))

    await waitFor(() =>
      expect(
        screen.getByRole('heading', {
          name: /live dashboard/i,
        }),
      ).toBeInTheDocument(),
    )
  })

  it('renders dashboard with backend data for authenticated session', async () => {
    localStorage.setItem(
      SESSION_KEY,
      JSON.stringify({
        user: { id: 'admin-1', email: 'ops@swift.app', role: 'admin' },
        token: 'token-abc',
      }),
    )

    vi.stubGlobal(
      'fetch',
      vi
        .fn()
        .mockResolvedValueOnce(
          okJson({
            stats: { users: 42, vendors: 12, orders: 99, revenue: 10500, gmv: 10500 },
          }),
        )
        .mockResolvedValueOnce(
          okJson({
            orders: [{ id: 'order-1', vendor_name: 'Urban Bowl', status: 'pending' }],
          }),
        ),
    )

    renderAt('/dashboard')

    await waitFor(() => {
      expect(screen.getByText('42')).toBeInTheDocument()
      expect(screen.getByText('Urban Bowl')).toBeInTheDocument()
    })
  })
})
