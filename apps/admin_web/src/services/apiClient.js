import { getApiBaseUrl } from '../config/runtimeConfig.js'

const API_BASE_URL = getApiBaseUrl()

async function request(path, options = {}) {
  const response = await fetch(`${API_BASE_URL}${path}`, {
    headers: {
      'Content-Type': 'application/json',
      ...(options.headers ?? {}),
    },
    ...options,
  })

  const text = await response.text()
  let payload = null

  if (text) {
    try {
      payload = JSON.parse(text)
    } catch {
      payload = { message: text }
    }
  }

  if (!response.ok) {
    const message =
      payload?.message ?? payload?.error ?? `Request failed with ${response.status}`
    const error = new Error(message)
    error.status = response.status
    throw error
  }

  return payload
}

export function loginAdmin({ email, password }) {
  return request('/auth/session', {
    method: 'POST',
    body: JSON.stringify({ email, password }),
  })
}

export function getAdminStats(token) {
  return request('/admin/stats', {
    headers: { Authorization: `Bearer ${token}` },
  })
}

export function getRecentOrders(token) {
  return request('/admin/orders?limit=5&page=1', {
    headers: { Authorization: `Bearer ${token}` },
  })
}
