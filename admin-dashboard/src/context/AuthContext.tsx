import React, { createContext, useContext, useEffect, useState } from 'react';
import axios from 'axios';
import { supabase } from '../lib/supabase';

interface UserProfile {
    id: string;
    email: string;
    role: 'admin' | 'vendor';
    profile?: any;
    [key: string]: any;
}

interface AuthContextType {
    user: UserProfile | null;
    session: any;
    loading: boolean;
    signIn: (email: string, password: string) => Promise<void>;
    signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
    const [user, setUser] = useState<UserProfile | null>(null);
    const [session, setSession] = useState<any>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        // Check active session
        supabase.auth.getSession().then(({ data: { session } }) => {
            setSession(session); // Keep session state updated
            if (session) {
                handleUserSession(session);
            } else {
                setUser(null);
            }
            setLoading(false);
        });

        // Listen for auth changes
        const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
            setSession(session); // Keep session state updated
            if (session) {
                handleUserSession(session);
            } else {
                setUser(null);
            }
            setLoading(false);
        });

        // Session Keep-alive / Heartbeat
        const heartbeat = setInterval(async () => {
            const { data: { session } } = await supabase.auth.getSession();
            if (session) {
                // Proactively refresh session if it's close to expiry
                const expiresAt = session.expires_at || 0;
                const now = Math.floor(Date.now() / 1000);
                if (expiresAt - now < 300) { // 5 minutes buffer
                    await supabase.auth.refreshSession();
                }
            }
        }, 60000); // Check every minute

        return () => {
            subscription.unsubscribe();
            clearInterval(heartbeat);
        };
    }, []);

    const handleUserSession = async (session: any) => {
        try {
            // Fetch role and profile from our backend to ensure sync
            const res = await axios.get(`${import.meta.env.VITE_API_URL}/auth/me`, {
                headers: { Authorization: `Bearer ${session.access_token}` }
            });

            setUser({
                ...session.user,
                role: res.data.user.role,
                profile: res.data.user
            });
        } catch (err) {
            console.error('Error syncing user profile:', err);
            setUser(session.user); // Fallback to basic session info
        }
    };

    const signIn = async (email: string, password: string) => {
        const { error } = await supabase.auth.signInWithPassword({
            email,
            password,
        });
        if (error) throw error;
        // The onAuthStateChange listener will handle updating the user state
    };

    const signOut = async () => {
        await supabase.auth.signOut();
        localStorage.removeItem('token');
        setUser(null);
        setSession(null); // Clear session state on signOut
    };

    return (
        <AuthContext.Provider value={{ user, session, loading, signIn, signOut }}>
            {children}
        </AuthContext.Provider>
    );
};

export const useAuth = () => {
    const context = useContext(AuthContext);
    if (context === undefined) throw new Error('useAuth must be used within an AuthProvider');
    return context;
};
