import React from 'react';
import { Navigate, Outlet } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';

interface ProtectedRouteProps {
    allowedRoles?: ('admin' | 'vendor')[];
}

const ProtectedRoute: React.FC<ProtectedRouteProps> = ({ allowedRoles }) => {
    const { user, loading } = useAuth();

    if (loading) {
        return (
            <div className="h-screen w-screen flex items-center justify-center font-black text-teal-600 animate-pulse">
                CONNECTING...
            </div>
        );
    }

    if (!user) {
        return <Navigate to="/login" replace />;
    }

    if (allowedRoles && !allowedRoles.includes(user.role as 'admin' | 'vendor')) {
        // If user is logged in but doesn't have the right role, 
        // redirect them to their respective dashboard instead of logout
        return <Navigate to={user.role === 'admin' ? '/admin' : '/vendor'} replace />;
    }

    return <Outlet />;
};

export default ProtectedRoute;
