import { createContext, useContext, useEffect, useState, useCallback, type ReactNode } from "react";
import { backendApi, setAdminToken } from "@/lib/backend-api";

export interface AdminUser {
  id: string;
  name: string;
  email: string;
  role: "admin" | "super_admin";
  avatar?: string;
}

interface AuthState {
  isAuthenticated: boolean;
  ready: boolean;
  user: AdminUser | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
}

const USER_STORAGE_KEY = 'swift_admin_user';

const readStoredUser = (): AdminUser | null => {
  if (typeof window === 'undefined') return null;
  try {
    const raw = window.localStorage.getItem(USER_STORAGE_KEY);
    return raw ? (JSON.parse(raw) as AdminUser) : null;
  } catch {
    return null;
  }
};

const storeUser = (user: AdminUser | null) => {
  if (typeof window === 'undefined') return;
  if (user) {
    window.localStorage.setItem(USER_STORAGE_KEY, JSON.stringify(user));
  } else {
    window.localStorage.removeItem(USER_STORAGE_KEY);
  }
};

const mapUser = (user: any): AdminUser => ({
  id: String(user.id || ''),
  name: String(user.name || user.email || 'Swift Admin'),
  email: String(user.email || ''),
  role: (user.role === 'super_admin' ? 'super_admin' : 'admin'),
  avatar: user.avatar,
});

const AuthContext = createContext<AuthState | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AdminUser | null>(() => readStoredUser());
  const [ready, setReady] = useState(false);

  useEffect(() => {
    const restore = async () => {
      const token = backendApi.getToken();
      const storedUser = readStoredUser();

      if (storedUser) {
        setUser(storedUser);
      }

      if (!token) {
        setReady(true);
        return;
      }

      try {
        const response = await backendApi.get<{ user: any }>('/auth/me');
        if (!['admin', 'super_admin'].includes(String(response.user?.role || 'admin'))) {
          throw new Error('Admin access required');
        }

        const nextUser = mapUser(response.user);
        setUser(nextUser);
        storeUser(nextUser);
      } catch {
        backendApi.setToken(null);
        storeUser(null);
        setUser(null);
      } finally {
        setReady(true);
      }
    };

    void restore();
  }, []);

  const login = useCallback(async (email: string, password: string) => {
    const response = await backendApi.post<{ user: any; session?: { access_token?: string } }>('/auth/session', {
      email,
      password,
    });

    if (!['admin', 'super_admin'].includes(String(response.user?.role || ''))) {
      throw new Error('Admin access required');
    }

    const nextUser = mapUser(response.user);
    setUser(nextUser);
    storeUser(nextUser);
    backendApi.setToken(response.session?.access_token || null);
  }, []);

  const logout = useCallback(() => {
    setUser(null);
    storeUser(null);
    backendApi.setToken(null);
  }, []);

  return (
    <AuthContext.Provider value={{ isAuthenticated: !!user, ready, user, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
