import { useState } from "react";
import Layout from "../components/Layout";
import { Construction, CheckCircle2, Clock, AlertCircle, Plus, Search, Filter, X, FileText, History, Save } from "lucide-react";
import { motion, AnimatePresence } from "motion/react";
import { useToast } from "../components/Toast";

export default function StaffFacilities() {
  const { showToast } = useToast();
  const [activeFacility, setActiveFacility] = useState<any | null>(null);
  const [isSaving, setIsSaving] = useState(false);

  const facilities = [
    { id: 1, name: "Swimming Pool", status: "Operational", lastCheck: "2h ago", health: 98, logs: ["PH levels checked", "Chlorine added"] },
    { id: 2, name: "Gymnasium", status: "Maintenance", lastCheck: "1d ago", health: 65, logs: ["Treadmill #3 motor issue", "Cable machine lubricated"] },
    { id: 3, name: "Elevator B2", status: "Operational", lastCheck: "5h ago", health: 92, logs: ["Door sensor cleaned", "Control panel tested"] },
    { id: 4, name: "Lobby Lighting", status: "Issue Reported", lastCheck: "10m ago", health: 40, logs: ["3 bulbs flickering", "Wiring inspection needed"] },
  ];

  const handleSaveLog = () => {
    setIsSaving(true);
    setTimeout(() => {
      setIsSaving(false);
      setActiveFacility(null);
      showToast("Maintenance log updated successfully!", "success");
    }, 1500);
  };

  return (
    <Layout title="Facilities" role="staff">
      <div className="p-4">
        <div className="flex items-center gap-3 mb-6">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
            <input 
              type="text" 
              placeholder="Search facility..." 
              className="w-full pl-10 pr-4 py-2 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl text-sm outline-none focus:ring-2 focus:ring-[#137fec]"
            />
          </div>
          <button className="p-2 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl">
            <Filter className="w-5 h-5 text-slate-500" />
          </button>
        </div>

        <div className="space-y-4">
          {facilities.map((facility) => (
            <motion.div 
              key={facility.id}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              onClick={() => setActiveFacility(facility)}
              className="bg-white dark:bg-slate-900 p-4 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm flex flex-col gap-4 cursor-pointer active:scale-[0.98] transition-all"
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className={`size-10 rounded-xl flex items-center justify-center ${
                    facility.status === 'Operational' ? 'bg-green-100 text-green-600' : 
                    facility.status === 'Maintenance' ? 'bg-orange-100 text-orange-600' : 
                    'bg-red-100 text-red-600'
                  }`}>
                    <Construction className="w-5 h-5" />
                  </div>
                  <div>
                    <h4 className="text-sm font-bold">{facility.name}</h4>
                    <p className="text-[10px] text-slate-500 dark:text-slate-400 font-medium">Last checked: {facility.lastCheck}</p>
                  </div>
                </div>
                <span className={`text-[9px] font-bold px-2 py-1 rounded-full uppercase tracking-tighter ${
                  facility.status === 'Operational' ? 'bg-green-50 text-green-600' : 
                  facility.status === 'Maintenance' ? 'bg-orange-50 text-orange-600' : 
                  'bg-red-50 text-red-600'
                }`}>
                  {facility.status}
                </span>
              </div>

              <div className="space-y-1.5">
                <div className="flex justify-between items-center text-[10px] font-bold text-slate-400 uppercase tracking-widest">
                  <span>Facility Health</span>
                  <span className={facility.health > 80 ? 'text-green-500' : facility.health > 50 ? 'text-orange-500' : 'text-red-500'}>
                    {facility.health}%
                  </span>
                </div>
                <div className="h-1.5 w-full bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
                  <motion.div 
                    initial={{ width: 0 }}
                    animate={{ width: `${facility.health}%` }}
                    className={`h-full rounded-full ${
                      facility.health > 80 ? 'bg-green-500' : 
                      facility.health > 50 ? 'bg-orange-500' : 
                      'bg-red-500'
                    }`}
                  />
                </div>
              </div>
            </motion.div>
          ))}
        </div>

        <button 
          onClick={() => showToast("Opening new maintenance log", "info")}
          className="fixed bottom-28 right-4 size-14 bg-[#137fec] text-white rounded-full shadow-xl shadow-[#137fec]/30 flex items-center justify-center active:scale-[0.9] transition-all z-40"
        >
          <Plus className="w-8 h-8" />
        </button>
      </div>

      {/* Maintenance Log Modal */}
      <AnimatePresence>
        {activeFacility && (
          <>
            <motion.div 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setActiveFacility(null)}
              className="fixed inset-0 bg-black/60 backdrop-blur-sm z-[100] max-w-md mx-auto"
            />
            <motion.div 
              initial={{ y: "100%" }}
              animate={{ y: 0 }}
              exit={{ y: "100%" }}
              transition={{ type: "spring", damping: 25, stiffness: 200 }}
              className="fixed inset-x-0 bottom-0 max-w-md mx-auto bg-white dark:bg-[#101922] rounded-t-[32px] z-[110] p-6 pb-10 shadow-2xl"
            >
              <div className="flex items-center justify-between mb-6">
                <div className="flex items-center gap-3">
                  <div className="size-10 rounded-xl bg-[#137fec]/10 text-[#137fec] flex items-center justify-center">
                    <FileText className="w-6 h-6" />
                  </div>
                  <div>
                    <h3 className="font-bold text-lg">Maintenance Log</h3>
                    <p className="text-xs text-slate-500 font-medium">{activeFacility.name}</p>
                  </div>
                </div>
                <button onClick={() => setActiveFacility(null)} className="p-2 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-full transition-colors">
                  <X className="w-5 h-5 text-slate-400" />
                </button>
              </div>

              <div className="space-y-6 mb-8">
                <div>
                  <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-2 block">Recent Activity</label>
                  <div className="space-y-2">
                    {activeFacility.logs.map((log: string, i: number) => (
                      <div key={i} className="flex items-center gap-3 p-3 bg-slate-50 dark:bg-slate-800/50 rounded-xl border border-slate-100 dark:border-slate-800">
                        <History className="w-3.5 h-3.5 text-slate-400" />
                        <span className="text-xs font-medium text-slate-600 dark:text-slate-300">{log}</span>
                      </div>
                    ))}
                  </div>
                </div>

                <div>
                  <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-2 block">Add New Note</label>
                  <textarea 
                    placeholder="Describe maintenance performed..."
                    className="w-full p-4 bg-slate-50 dark:bg-slate-800/50 border border-slate-100 dark:border-slate-800 rounded-2xl text-sm outline-none focus:ring-2 focus:ring-[#137fec] min-h-[100px] resize-none"
                  />
                </div>

                <div className="flex items-center justify-between p-4 bg-slate-50 dark:bg-slate-800/50 rounded-2xl border border-slate-100 dark:border-slate-800">
                  <div className="flex items-center gap-3">
                    <Clock className="w-4 h-4 text-slate-400" />
                    <span className="text-xs font-bold">Mark as Operational</span>
                  </div>
                  <div className="w-10 h-5 bg-[#137fec] rounded-full p-1 flex items-center justify-end">
                    <div className="size-3 bg-white rounded-full" />
                  </div>
                </div>
              </div>

              <button 
                disabled={isSaving}
                onClick={handleSaveLog}
                className="w-full py-4 bg-[#137fec] text-white rounded-2xl font-bold text-sm shadow-lg shadow-blue-500/20 active:scale-[0.98] transition-all disabled:opacity-50 disabled:active:scale-100 flex items-center justify-center gap-2"
              >
                {isSaving ? (
                  <div className="size-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                ) : (
                  <>
                    <Save className="w-4 h-4" />
                    Save Changes
                  </>
                )}
              </button>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </Layout>
  );
}
