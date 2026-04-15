import { useState } from 'react'
import { Link } from 'react-router-dom'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/useAuth.js'

function LoginPage() {
  const navigate = useNavigate()
  const { signIn, isAuthenticating } = useAuth()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [formError, setFormError] = useState('')

  async function handleSubmit(event) {
    event.preventDefault()
    setFormError('')

    try {
      await signIn({ email, password })
      navigate('/dashboard', { replace: true })
    } catch (error) {
      setFormError(error.message ?? 'Unable to sign in right now')
    }
  }

  return (
    <main className="auth-page">
      <section className="auth-card" aria-labelledby="login-title">
        <div>
          <p className="eyebrow">Secure Access</p>
          <h1 id="login-title">Admin Login</h1>
          <p>Use your operations account to access moderation and analytics.</p>
        </div>

        <form className="auth-form" onSubmit={handleSubmit}>
          <label htmlFor="email">Email</label>
          <input
            id="email"
            type="email"
            placeholder="ops@swift.app"
            required
            value={email}
            onChange={(event) => setEmail(event.target.value)}
          />

          <label htmlFor="password">Password</label>
          <input
            id="password"
            type="password"
            placeholder="Enter password"
            required
            value={password}
            onChange={(event) => setPassword(event.target.value)}
          />

          {formError ? (
            <p className="form-error" role="alert">
              {formError}
            </p>
          ) : null}

          <button className="btn btn-primary" type="submit">
            {isAuthenticating ? 'Signing in...' : 'Sign in'}
          </button>
        </form>

        <p className="inline-link">
          Need access? <Link to="/">Request admin onboarding</Link>
        </p>
      </section>
    </main>
  )
}

export default LoginPage

