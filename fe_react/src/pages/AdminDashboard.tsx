import { useState, useEffect, type FormEvent } from "react";
import Layout from "../components/Layout";
import { useToast } from "../components/Toast";
import { Users, Bed, Wallet, Wrench, Plus, Receipt, Construction, ShieldCheck, X, Save, UserPlus, KeyRound, ClipboardList } from "lucide-react";
import { motion, AnimatePresence } from "motion/react";
import { useNavigate } from "react-router-dom";

export default function AdminDashboard() {
  const { showToast } = useToast();
  const navigate = useNavigate();
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [stats, setStats] = useState({
    residents: 1248,
    occupancy: 94.2,
    pendingBilling: 14,
    openRequests: 8,
  });

  const recentActivity = [
    { id: 1, type: "billing", title: "Billing generated for Unit 402", desc: "Monthly maintenance fee processed.", time: "2 minutes ago", icon: Receipt, color: "bg-blue-100 text-blue-600" },
    { id: 2, type: "maintenance", title: "Maintenance Request: Leak", desc: "Unit 105 reported a kitchen sink leak.", time: "45 minutes ago", icon: Construction, color: "bg-orange-100 text-orange-600" },
    { id: 3, type: "onboarding", title: "New Resident Onboarded", desc: "John Doe moved into Unit 812.", time: "3 hours ago", icon: Users, color: "bg-green-100 text-green-600" },
  ];

  const handleAddResident = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setIsSaving(true);
    setTimeout(() => {
      setIsSaving(false);
      setIsAddModalOpen(false);
      setStats(prev => ({ ...prev, residents: prev.residents + 1 }));
      showToast("New resident added successfully!", "success");
    }, 1500);
  };

  return (
    <Layout title="Skyline Heights" role="admin">
      <div className="p-4 lg:p-6">
        <div className="flex items-center gap-3 mb-4">
          <div className="bg-[#137fec]/10 p-2 rounded-lg">
            <ShieldCheck className="text-[#137fec] w-6 h-6" />
          </div>
          <div>
            <h2 className="text-slate-900 dark:text-slate-100 text-lg font-bold leading-tight tracking-tight">Skyline Heights</h2>
            <p className="text-xs text-slate-500 dark:text-slate-400">Admin Dashboard</p>
          </div>
        </div>

        <section className="mb-6 grid grid-cols-2 gap-4 xl:grid-cols-4">
          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="ui-hover-lift ui-hover-accent flex flex-col gap-2 rounded-xl p-4 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-sm"
          >
            <div className="flex items-center justify-between">
              <Users className="text-[#137fec] bg-[#137fec]/10 p-2 rounded-lg w-10 h-10" />
              <span className="text-xs font-bold text-green-500">+4%</span>
            </div>
            <div>
              <p className="text-slate-500 dark:text-slate-400 text-xs font-medium">Total Residents</p>
              <p className="text-slate-900 dark:text-slate-100 text-2xl font-extrabold leading-tight">{stats.residents.toLocaleString()}</p>
            </div>
          </motion.div>

          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="ui-hover-lift ui-hover-accent flex flex-col gap-2 rounded-xl p-4 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-sm"
          >
            <div className="flex items-center justify-between">
              <Bed className="text-orange-500 bg-orange-500/10 p-2 rounded-lg w-10 h-10" />
              <span className="text-xs font-bold text-slate-400">Stable</span>
            </div>
            <div>
              <p className="text-slate-500 dark:text-slate-400 text-xs font-medium">Occupancy Rate</p>
              <p className="text-slate-900 dark:text-slate-100 text-2xl font-extrabold leading-tight">{stats.occupancy}%</p>
            </div>
          </motion.div>

          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
            className="ui-hover-lift ui-hover-accent flex flex-col gap-2 rounded-xl p-4 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-sm"
          >
            <div className="flex items-center justify-between">
              <Wallet className="text-red-500 bg-red-500/10 p-2 rounded-lg w-10 h-10" />
              <span className="text-xs font-bold text-red-500">{stats.pendingBilling} New</span>
            </div>
            <div>
              <p className="text-slate-500 dark:text-slate-400 text-xs font-medium">Pending Billing</p>
              <p className="text-slate-900 dark:text-slate-100 text-2xl font-extrabold leading-tight">{stats.pendingBilling}</p>
            </div>
          </motion.div>

          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3 }}
            className="ui-hover-lift ui-hover-accent flex flex-col gap-2 rounded-xl p-4 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-sm"
          >
            <div className="flex items-center justify-between">
              <Wrench className="text-purple-500 bg-purple-500/10 p-2 rounded-lg w-10 h-10" />
              <span className="text-xs font-bold text-orange-500">High</span>
            </div>
            <div>
              <p className="text-slate-500 dark:text-slate-400 text-xs font-medium">Open Requests</p>
              <p className="text-slate-900 dark:text-slate-100 text-2xl font-extrabold leading-tight">{stats.openRequests}</p>
            </div>
          </motion.div>
        </section>

        <div className="mb-6 grid gap-3 lg:grid-cols-3">
          <button 
            onClick={() => navigate("/admin/residents")}
            className="ui-hover-soft flex w-full cursor-pointer items-center justify-center overflow-hidden rounded-xl h-14 bg-[#137fec] text-white gap-2 text-base font-bold shadow-lg shadow-[#137fec]/25 active:scale-95 transition-transform"
          >
            <Plus className="w-5 h-5" />
            <span>Resident Management</span>
          </button>
          <button 
            onClick={() => navigate("/admin/leasing")}
            className="ui-hover-soft ui-hover-accent flex w-full cursor-pointer items-center justify-center overflow-hidden rounded-xl h-14 border border-slate-200 bg-white text-slate-900 gap-2 text-base font-bold shadow-sm active:scale-95 transition-transform dark:border-slate-800 dark:bg-slate-900 dark:text-slate-100"
          >
            <KeyRound className="w-5 h-5 text-[#137fec]" />
            <span>Leasing & Utilities</span>
          </button>
          <button 
            onClick={() => navigate("/admin/ops")}
            className="ui-hover-soft ui-hover-accent flex w-full cursor-pointer items-center justify-center overflow-hidden rounded-xl h-14 border border-slate-200 bg-white text-slate-900 gap-2 text-base font-bold shadow-sm active:scale-95 transition-transform dark:border-slate-800 dark:bg-slate-900 dark:text-slate-100"
          >
            <ClipboardList className="w-5 h-5 text-[#137fec]" />
            <span>Operations Hub</span>
          </button>
        </div>

        <section>
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-slate-900 dark:text-slate-100 text-lg font-bold tracking-tight">Recent Activity</h3>
            <button 
              onClick={() => navigate("/admin/activity")}
              className="text-[#137fec] text-sm font-semibold"
            >
              View All
            </button>
          </div>
          <div className="space-y-3 xl:grid xl:grid-cols-3 xl:gap-4 xl:space-y-0">
            {recentActivity.map((activity) => (
              <div key={activity.id} className="ui-hover-lift ui-hover-accent flex items-start gap-4 p-4 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl">
                <div className={`size-10 rounded-full flex items-center justify-center shrink-0 ${activity.color}`}>
                  <activity.icon className="w-5 h-5" />
                </div>
                <div className="flex-1">
                  <p className="text-sm font-bold text-slate-900 dark:text-slate-100">{activity.title}</p>
                  <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">{activity.desc}</p>
                  <p className="text-[10px] text-slate-400 mt-2 font-medium">{activity.time}</p>
                </div>
              </div>
            ))}
          </div>
        </section>
      </div>

      {/* Add Resident Modal */}
      <AnimatePresence>
        {isAddModalOpen && (
          <>
            <motion.div 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setIsAddModalOpen(false)}
              className="fixed inset-0 z-[100] bg-black/60 backdrop-blur-sm"
            />
            <motion.div 
              initial={{ opacity: 0, y: 40 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: 40 }}
              transition={{ type: "spring", damping: 25, stiffness: 200 }}
              className="fixed inset-x-4 bottom-0 z-[110] mx-auto rounded-t-[32px] bg-white p-6 pb-10 shadow-2xl dark:bg-[#101922] sm:max-w-xl lg:inset-x-0 lg:top-1/2 lg:bottom-auto lg:w-full lg:max-w-2xl lg:-translate-y-1/2 lg:rounded-[32px] lg:pb-6"
            >
              <div className="flex items-center justify-between mb-6">
                <div className="flex items-center gap-3">
                  <div className="size-10 rounded-xl bg-[#137fec]/10 text-[#137fec] flex items-center justify-center">
                    <UserPlus className="w-6 h-6" />
                  </div>
                  <div>
                    <h3 className="font-bold text-lg">Add Resident</h3>
                    <p className="text-xs text-slate-500 font-medium">Onboard a new tenant</p>
                  </div>
                </div>
                <button onClick={() => setIsAddModalOpen(false)} className="ui-hover-soft p-2 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-full transition-colors">
                  <X className="w-5 h-5 text-slate-400" />
                </button>
              </div>

              <form onSubmit={handleAddResident} className="space-y-4 mb-8">
                <div className="space-y-1">
                  <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest px-1">Full Name</label>
                  <input required type="text" placeholder="e.g. Alice Smith" className="w-full p-4 bg-slate-50 dark:bg-slate-800/50 border border-slate-100 dark:border-slate-800 rounded-2xl text-sm outline-none focus:ring-2 focus:ring-[#137fec]" />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-1">
                    <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest px-1">Unit Number</label>
                    <input required type="text" placeholder="e.g. 812" className="w-full p-4 bg-slate-50 dark:bg-slate-800/50 border border-slate-100 dark:border-slate-800 rounded-2xl text-sm outline-none focus:ring-2 focus:ring-[#137fec]" />
                  </div>
                  <div className="space-y-1">
                    <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest px-1">Tower</label>
                    <select className="w-full p-4 bg-slate-50 dark:bg-slate-800/50 border border-slate-100 dark:border-slate-800 rounded-2xl text-sm outline-none focus:ring-2 focus:ring-[#137fec]">
                      <option>Skyview Tower</option>
                      <option>Ocean Tower</option>
                      <option>Garden Tower</option>
                    </select>
                  </div>
                </div>
                <div className="space-y-1">
                  <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest px-1">Email Address</label>
                  <input required type="email" placeholder="alice@example.com" className="w-full p-4 bg-slate-50 dark:bg-slate-800/50 border border-slate-100 dark:border-slate-800 rounded-2xl text-sm outline-none focus:ring-2 focus:ring-[#137fec]" />
                </div>

                <button 
                  disabled={isSaving}
                  type="submit"
                  className="w-full mt-4 py-4 bg-[#137fec] text-white rounded-2xl font-bold text-sm shadow-lg shadow-blue-500/20 active:scale-[0.98] transition-all disabled:opacity-50 disabled:active:scale-100 flex items-center justify-center gap-2"
                >
                  {isSaving ? (
                    <div className="size-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                  ) : (
                    <>
                      <Save className="w-4 h-4" />
                      Confirm Onboarding
                    </>
                  )}
                </button>
              </form>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </Layout>
  );
}
