import Layout from "../components/Layout";
import ActionGrid from "../components/ActionGrid";
import { useToast } from "../components/Toast";
import { Construction } from "lucide-react";

export default function Facilities() {
  const { showToast } = useToast();
  const handleAction = (action: string) => {
    console.log(`Facility Action: ${action}`);
  };

  const handleFacilityAction = (name: string, action: string) => {
    showToast(`${action} performed on ${name}`, "success");
  };

  return (
    <Layout title="Facility & Service" role="admin">
      <div className="p-4">
        <div className="flex items-center gap-3 mb-6 bg-white dark:bg-slate-900 p-4 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm">
          <div className="bg-orange-100 dark:bg-orange-900/30 p-3 rounded-xl">
            <Construction className="text-orange-600 dark:text-orange-400 w-6 h-6" />
          </div>
          <div>
            <h2 className="text-lg font-bold tracking-tight">Facility Management</h2>
            <p className="text-xs text-slate-500 dark:text-slate-400 font-medium">Manage building services and amenities</p>
          </div>
        </div>

        <div className="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm overflow-hidden">
          <div className="px-4 py-3 border-b border-slate-100 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-800/50">
            <h3 className="text-xs font-bold uppercase tracking-widest text-slate-400">Available Operations</h3>
          </div>
          <ActionGrid onAction={handleAction} extraActions={true} />
        </div>

        <div className="mt-6 space-y-4">
          <h3 className="text-sm font-bold px-1">Active Facilities</h3>
          {[
            { name: "Swimming Pool", status: "Open", icon: "🏊" },
            { name: "Fitness Center", status: "Maintenance", icon: "🏋️" },
            { name: "Community Hall", status: "Open", icon: "🏛️" },
          ].map((facility) => (
            <div 
              key={facility.name} 
              onClick={() => handleFacilityAction(facility.name, "Manage")}
              className="flex items-center justify-between p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm cursor-pointer hover:border-[#137fec] transition-all"
            >
              <div className="flex items-center gap-3">
                <span className="text-2xl">{facility.icon}</span>
                <span className="font-bold text-sm">{facility.name}</span>
              </div>
              <span className={`text-[10px] font-bold uppercase px-2 py-1 rounded-full ${facility.status === 'Open' ? 'bg-emerald-100 text-emerald-600' : 'bg-amber-100 text-amber-600'}`}>
                {facility.status}
              </span>
            </div>
          ))}
        </div>
      </div>
    </Layout>
  );
}
