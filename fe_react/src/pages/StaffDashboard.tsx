import Layout from "../components/Layout";
import { ClipboardList, Shield, Construction, Clock, CheckCircle2, AlertCircle } from "lucide-react";
import { motion } from "motion/react";
import { useToast } from "../components/Toast";

export default function StaffDashboard() {
  const { showToast } = useToast();

  const tasks = [
    { id: 1, title: "Check Fire Extinguishers", zone: "Tower A, Floor 1-10", priority: "High", status: "Pending", icon: AlertCircle, color: "text-red-500 bg-red-50" },
    { id: 2, title: "Lobby Cleaning Supervision", zone: "Main Entrance", priority: "Medium", status: "In Progress", icon: Clock, color: "text-orange-500 bg-orange-50" },
    { id: 3, title: "Pool Water Quality Test", zone: "Amenity Deck", priority: "Low", status: "Completed", icon: CheckCircle2, color: "text-green-500 bg-green-50" },
  ];

  return (
    <Layout title="Staff Portal" role="staff">
      <div className="p-4">
        <div className="flex items-center gap-3 mb-6 bg-white dark:bg-slate-900 p-4 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm">
          <div className="bg-[#137fec]/10 p-3 rounded-xl">
            <ClipboardList className="text-[#137fec] w-6 h-6" />
          </div>
          <div>
            <h2 className="text-lg font-bold tracking-tight">Staff Operations</h2>
            <p className="text-xs text-slate-500 dark:text-slate-400 font-medium">Manage your daily tasks and reports</p>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-4 mb-6">
          <div className="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
            <p className="text-[10px] text-slate-500 dark:text-slate-400 font-bold uppercase tracking-wider">My Tasks</p>
            <p className="text-2xl font-extrabold mt-1">12</p>
          </div>
          <div className="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
            <p className="text-[10px] text-slate-500 dark:text-slate-400 font-bold uppercase tracking-wider">Completed</p>
            <p className="text-2xl font-extrabold mt-1 text-green-500">8</p>
          </div>
        </div>

        <div className="space-y-4">
          <div className="flex items-center justify-between px-1">
            <h3 className="text-sm font-bold uppercase tracking-widest text-slate-400">Assigned Tasks</h3>
            <button className="text-[#137fec] text-xs font-bold">View All</button>
          </div>

          <div className="space-y-3">
            {tasks.map((task) => (
              <motion.div 
                key={task.id}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                onClick={() => showToast(`Opening task: ${task.title}`, "info")}
                className="bg-white dark:bg-slate-900 p-4 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex items-center gap-4 cursor-pointer active:scale-[0.98] transition-all"
              >
                <div className={`size-10 rounded-full flex items-center justify-center shrink-0 ${task.color}`}>
                  <task.icon className="w-5 h-5" />
                </div>
                <div className="flex-1 min-w-0">
                  <h4 className="text-sm font-bold truncate">{task.title}</h4>
                  <p className="text-[11px] text-slate-500 dark:text-slate-400 font-medium">{task.zone}</p>
                </div>
                <div className="text-right">
                  <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                    task.status === 'Completed' ? 'bg-green-100 text-green-600' : 
                    task.status === 'In Progress' ? 'bg-orange-100 text-orange-600' : 
                    'bg-red-100 text-red-600'
                  }`}>
                    {task.status}
                  </span>
                </div>
              </motion.div>
            ))}
          </div>
        </div>

        <div className="mt-8 grid grid-cols-2 gap-3">
          <button 
            onClick={() => showToast("Incident report form opened", "info")}
            className="flex flex-col items-center justify-center p-4 bg-red-50 dark:bg-red-900/10 border border-red-100 dark:border-red-900/30 rounded-xl gap-2"
          >
            <Shield className="w-6 h-6 text-red-500" />
            <span className="text-xs font-bold text-red-600">Report Incident</span>
          </button>
          <button 
            onClick={() => showToast("Maintenance request form opened", "info")}
            className="flex flex-col items-center justify-center p-4 bg-blue-50 dark:bg-blue-900/10 border border-blue-100 dark:border-blue-900/30 rounded-xl gap-2"
          >
            <Construction className="w-6 h-6 text-[#137fec]" />
            <span className="text-xs font-bold text-[#137fec]">Request Repair</span>
          </button>
        </div>
      </div>
    </Layout>
  );
}
