import React from 'react';

interface EmptyStateProps {
    icon: React.ReactNode;
    message: string;
}

const EmptyState: React.FC<EmptyStateProps> = ({ icon, message }) => (
    <div className="col-span-full py-24 bg-white rounded-[40px] border-4 border-dashed border-gray-50 flex flex-col items-center justify-center grayscale opacity-30">
        <div className="mb-6">{icon}</div>
        <p className="text-xl font-black text-gray-400 uppercase tracking-widest">{message}</p>
    </div>
);

export default EmptyState;
