const DEFAULT_API_BASE_URL = 'http://localhost:3000/api/v1'

export function getApiBaseUrl() {
  const configured = import.meta.env.VITE_API_BASE_URL
  if (typeof configured === 'string' && configured.trim().length > 0) {
    return configured.replace(/\/$/, '')
  }

  return DEFAULT_API_BASE_URL
}
