import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { ShieldCheck, Lock, Mail, Loader2 } from 'lucide-react';

export const Login: React.FC = () => {
    const { signIn } = useAuth();
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setError('');
        try {
            await signIn(email, password);
        } catch (err: any) {
            setError('Invalid admin credentials');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="min-h-screen flex items-center justify-center relative overflow-hidden font-sans">
            {/* Background Image with sophisticated Overlay */}
            <div
                className="absolute inset-0 z-0 bg-cover bg-center bg-no-repeat transition-all duration-1000 scale-105"
                style={{ backgroundImage: 'url("/bg-campus.png")' }}
            >
                <div className="absolute inset-0 bg-gradient-to-br from-teal-950/60 via-teal-900/40 to-black/60 backdrop-blur-[3px]"></div>
            </div>

            {/* Inner Glow/Ambient Light */}
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-teal-500/10 rounded-full blur-[120px] pointer-events-none"></div>

            <div className="max-w-md w-full space-y-8 bg-white/70 backdrop-blur-2xl p-12 rounded-[48px] shadow-[0_32px_120px_-15px_rgba(0,0,0,0.5)] border border-white/30 relative z-10 transition-all hover:border-white/50 group/card overflow-hidden">
                <div className="absolute top-0 left-0 w-full h-2 bg-gradient-to-r from-teal-400 to-teal-600 opacity-60"></div>

                <div className="text-center space-y-2">
                    <div className="flex justify-center">
                        <div className="bg-white/40 p-5 rounded-[24px] shadow-sm backdrop-blur-md border border-white/50 group-hover/card:scale-110 transition-transform duration-500">
                            <ShieldCheck className="h-10 w-10 text-teal-600" />
                        </div>
                    </div>
                    <div className="pt-4">
                        <h2 className="text-4xl font-extrabold text-slate-900 tracking-tight leading-tight">Swift</h2>
                        <div className="h-px w-12 bg-teal-500/20 mx-auto mt-4"></div>
                    </div>
                </div>

                <form className="mt-10 space-y-5" onSubmit={handleSubmit}>
                    {error && (
                        <div className="bg-red-50/90 backdrop-blur-md text-red-600 px-5 py-4 rounded-2xl text-xs font-bold border border-red-100/50 animate-shake flex items-center gap-3">
                            <div className="w-1.5 h-1.5 bg-red-500 rounded-full animate-pulse"></div>
                            {error}
                        </div>
                    )}

                    <div className="space-y-4">
                        <div className="relative">
                            <Mail className="absolute left-5 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400 pointer-events-none" />
                            <input
                                type="email"
                                required
                                className="block w-full pl-14 pr-5 py-4.5 bg-slate-100/40 border border-slate-200/50 rounded-2xl text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-500/50 focus:bg-white/80 transition-all shadow-sm font-medium text-sm"
                                placeholder="Admin Email"
                                value={email}
                                onChange={(e) => setEmail(e.target.value)}
                            />
                        </div>
                        <div className="relative">
                            <Lock className="absolute left-5 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400 pointer-events-none" />
                            <input
                                type="password"
                                required
                                className="block w-full pl-14 pr-5 py-4.5 bg-slate-100/40 border border-slate-200/50 rounded-2xl text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-500/50 focus:bg-white/80 transition-all shadow-sm font-medium text-sm"
                                placeholder="Password"
                                value={password}
                                onChange={(e) => setPassword(e.target.value)}
                            />
                        </div>
                    </div>

                    <div className="pt-4">
                        <button
                            type="submit"
                            disabled={loading}
                            className="w-full flex justify-center py-5 px-4 border border-transparent text-base font-bold rounded-2xl text-white bg-teal-600 hover:bg-teal-500 shadow-xl shadow-teal-500/25 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-teal-500 transition-all active:scale-[0.98] disabled:opacity-50 relative overflow-hidden group shadow-[0_20px_40px_-10px_rgba(13,148,136,0.3)]"
                        >
                            <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent -translate-x-full group-hover:animate-[shimmer_2s_infinite]"></div>
                            {loading ? <Loader2 className="animate-spin h-5 w-5" /> : 'Access Dashboard'}
                        </button>
                    </div>
                </form>

                <p className="text-center text-[11px] text-slate-400 font-medium uppercase tracking-widest pt-4">
                    Authorized Personnel Only &copy; 2026
                </p>
            </div>
        </div>
    );
};
