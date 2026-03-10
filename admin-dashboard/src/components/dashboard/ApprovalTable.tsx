import React from 'react';

interface ApprovalTableProps {
    vendors: any[];
    onApprove: (id: string) => void;
}

const ApprovalTable: React.FC<ApprovalTableProps> = ({ vendors, onApprove }) => (
    <div className="bg-white rounded-[32px] border border-gray-100 shadow-sm overflow-hidden">
        <div className="p-8 border-b border-gray-100 flex items-center justify-between bg-gray-50/30">
            <h3 className="text-2xl font-black tracking-tight underline decoration-teal-500 decoration-4">Vendor Approvals</h3>
            <button className="text-teal-600 font-black text-xs uppercase tracking-widest hover:underline">Full Directory</button>
        </div>
        <div className="overflow-x-auto">
            <table className="w-full text-left">
                <thead>
                    <tr className="bg-gray-50/50 text-[10px] font-black uppercase tracking-widest text-gray-400 border-b border-gray-100">
                        <th className="px-10 py-6">Applicant Entity</th>
                        <th className="px-10 py-6">Timeline</th>
                        <th className="px-10 py-6 text-right">Verification</th>
                    </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                    {vendors.map((vendor: any) => (
                        <tr key={vendor.id} className="group hover:bg-gray-50/50 transition-all cursor-pointer">
                            <td className="px-10 py-8">
                                <div className="flex items-center gap-6">
                                    <div className="w-14 h-14 bg-teal-600/10 text-teal-700 rounded-2xl flex items-center justify-center font-black text-xl">
                                        {vendor.name?.[0] || 'V'}
                                    </div>
                                    <div>
                                        <p className="font-black text-lg text-gray-900 tracking-tight">{vendor.name}</p>
                                        <p className="text-xs text-gray-400 font-bold uppercase tracking-wider">
                                            {vendor.owner?.name} • {vendor.owner?.email}
                                        </p>
                                    </div>
                                </div>
                            </td>
                            <td className="px-10 py-8 text-sm font-bold text-gray-400 uppercase tracking-widest">
                                {new Date(vendor.created_at).toLocaleDateString()}
                            </td>
                            <td className="px-10 py-8">
                                <div className="flex gap-3 justify-end opacity-0 group-hover:opacity-100 transition-all translate-x-4 group-hover:translate-x-0">
                                    <button
                                        onClick={() => onApprove(vendor.id)}
                                        className="px-6 py-3 bg-teal-600 text-white rounded-xl text-[10px] font-black uppercase tracking-widest shadow-lg shadow-teal-500/20 hover:bg-teal-700 transition-all"
                                    >
                                        Grant Access
                                    </button>
                                    <button className="px-6 py-3 border-2 border-red-50 text-red-500 rounded-xl text-[10px] font-black uppercase tracking-widest hover:bg-red-50 transition-all">Decline</button>
                                </div>
                            </td>
                        </tr>
                    ))}
                    {vendors.length === 0 && (
                        <tr>
                            <td colSpan={3} className="px-10 py-12 text-center text-gray-400 font-bold uppercase tracking-widest text-sm">
                                No pending applications
                            </td>
                        </tr>
                    )}
                </tbody>
            </table>
        </div>
    </div>
);

export default ApprovalTable;
