const DEFAULT_API_BASE_URL = 'http://localhost:3000/api/v1';
const TOKEN_STORAGE_KEY = 'swift_admin_token';

export class BackendApiError extends Error {
  status: number;

  constructor(status: number, message: string) {
    super(message);
    this.name = 'BackendApiError';
    this.status = status;
  }
}

const getApiBaseUrl = () => {
  const value = import.meta.env.VITE_BACKEND_API_URL || DEFAULT_API_BASE_URL;
  return value.replace(/\/+$/, '');
};

const storageAvailable = () => typeof window !== 'undefined' && typeof window.localStorage !== 'undefined';

export const getAdminToken = () => {
  if (!storageAvailable()) return null;
  return window.localStorage.getItem(TOKEN_STORAGE_KEY);
};

export const setAdminToken = (token: string | null) => {
  if (!storageAvailable()) return;
  if (token) {
    window.localStorage.setItem(TOKEN_STORAGE_KEY, token);
  } else {
    window.localStorage.removeItem(TOKEN_STORAGE_KEY);
  }
};

const parseResponseBody = async (response: Response) => {
  if (response.status === 204) {
    return null;
  }
  
  const contentType = response.headers.get('content-type') || '';
  if (contentType.includes('application/json')) {
    try {
      const text = await response.text();
      return text ? JSON.parse(text) : null;
    } catch {
      return null;
    }
  }

  const text = await response.text();
  return text ? { message: text } : null;
};

export async function backendRequest<T>(path: string, init: RequestInit = {}): Promise<T> {
  const response = await fetch(`${getApiBaseUrl()}${path}`, {
    ...init,
    headers: {
      'Content-Type': 'application/json',
      ...(getAdminToken() ? { Authorization: `Bearer ${getAdminToken()}` } : {}),
      ...(init.headers || {}),
    },
  });

  const body = await parseResponseBody(response);

  if (!response.ok) {
    const message = (body as any)?.message || (body as any)?.error || response.statusText || 'Request failed';
    throw new BackendApiError(response.status, String(message));
  }

  return body as T;
}

export const backendApi = {
  get: <T>(path: string) => backendRequest<T>(path),
  post: <T>(path: string, body?: unknown) =>
    backendRequest<T>(path, { method: 'POST', body: body === undefined ? undefined : JSON.stringify(body) }),
  patch: <T>(path: string, body?: unknown) =>
    backendRequest<T>(path, { method: 'PATCH', body: body === undefined ? undefined : JSON.stringify(body) }),
  del: <T>(path: string, body?: unknown) =>
    backendRequest<T>(path, { method: 'DELETE', body: body === undefined ? undefined : JSON.stringify(body) }),
  setToken: setAdminToken,
  getToken: getAdminToken,
};