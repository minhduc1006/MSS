import Layout from "../components/Layout";
import ActionGrid from "../components/ActionGrid";
import { useToast } from "../components/Toast";
import { Building2 } from "lucide-react";

export default function Apartment() {
  const { showToast } = useToast();
  const handleAction = (action: string) => {
    console.log(`Apartment Action: ${action}`);
  };

  return (
    <Layout title="Apartment Admin" role="admin">
      <div className="p-4">
        <div className="flex items-center gap-3 mb-6 bg-white dark:bg-slate-900 p-4 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm">
          <div className="bg-blue-100 dark:bg-blue-900/30 p-3 rounded-xl">
            <Building2 className="text-blue-600 dark:text-blue-400 w-6 h-6" />
          </div>
          <div>
            <h2 className="text-lg font-bold tracking-tight">Apartment Administration</h2>
            <p className="text-xs text-slate-500 dark:text-slate-400 font-medium">Manage units, leases, and building policies</p>
          </div>
        </div>

        <div className="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm overflow-hidden">
          <div className="px-4 py-3 border-b border-slate-100 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-800/50">
            <h3 className="text-xs font-bold uppercase tracking-widest text-slate-400">Administrative Operations</h3>
          </div>
          <ActionGrid onAction={handleAction} extraActions={true} />
        </div>

        <div className="mt-6 space-y-4">
          <h3 className="text-sm font-bold px-1">Building Statistics</h3>
          <div className="grid grid-cols-2 gap-4">
            <div className="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
              <p className="text-xs text-slate-500 dark:text-slate-400 font-bold uppercase tracking-wider">Total Units</p>
              <p className="text-2xl font-extrabold mt-1">120</p>
            </div>
            <div className="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
              <p className="text-xs text-slate-500 dark:text-slate-400 font-bold uppercase tracking-wider">Occupied</p>
              <p className="text-2xl font-extrabold mt-1">112</p>
            </div>
          </div>
        </div>
      </div>
    </Layout>
  );
}
