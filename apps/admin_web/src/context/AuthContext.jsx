import { useMemo, useState } from 'react'
import { AuthContext } from './authContext.js'
import { loginAdmin } from '../services/apiClient.js'

const STORAGE_KEY = 'swift.admin.session'
function readStoredSession() {
  const raw = localStorage.getItem(STORAGE_KEY)
  if (!raw) {
    return { user: null, token: null }
  }

  try {
    const session = JSON.parse(raw)
    return {
      user: session.user ?? null,
      token: session.token ?? null,
    }
  } catch {
    return { user: null, token: null }
  }
}

export function AuthProvider({ children }) {
  const [session, setSession] = useState(readStoredSession)
  const [isAuthenticating, setIsAuthenticating] = useState(false)

  const isAuthenticated = Boolean(session.token && session.user)

  async function signIn({ email, password }) {
    setIsAuthenticating(true)
    try {
      const payload = await loginAdmin({ email, password })
      const token = payload?.session?.access_token
      const user = payload?.user

      if (!token || !user) {
        throw new Error('Invalid login response from backend')
      }

      if (user.role !== 'admin') {
        throw new Error('This account is not permitted for admin access')
      }

      const nextSession = { user, token }
      localStorage.setItem(STORAGE_KEY, JSON.stringify(nextSession))
      setSession(nextSession)
      return user
    } finally {
      setIsAuthenticating(false)
    }
  }

  function signOut() {
    localStorage.removeItem(STORAGE_KEY)
    setSession({ user: null, token: null })
  }

  const value = useMemo(
    () => ({
      user: session.user,
      token: session.token,
      isAuthenticated,
      isAuthenticating,
      signIn,
      signOut,
    }),
    [isAuthenticated, isAuthenticating, session.token, session.user],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}
