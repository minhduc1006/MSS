import Layout from "../components/Layout";
import { Shield, AlertTriangle, Search, Filter } from "lucide-react";
import { motion } from "motion/react";

export default function StaffSecurity() {
  const securityLogs = [
    { id: 1, event: "Guest Entry", visitor: "John Doe", time: "10:30 AM", status: "Authorized" },
    { id: 2, event: "Gate Access", visitor: "Resident (Self)", time: "08:15 AM", status: "Success" },
    { id: 3, event: "Delivery", visitor: "Amazon Courier", time: "Yesterday", status: "Authorized" },
  ];

  return (
    <Layout title="Security" role="staff">
      <div className="p-4">
        <div className="flex items-center gap-3 mb-6">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
            <input 
              type="text" 
              placeholder="Search security log..." 
              className="w-full pl-10 pr-4 py-2 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl text-sm outline-none focus:ring-2 focus:ring-[#137fec]"
            />
          </div>
          <div className="p-2 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl">
            <Filter className="w-5 h-5 text-slate-500" />
          </div>
        </div>

        <div className="bg-red-50 dark:bg-red-900/10 border border-red-100 dark:border-red-900/30 rounded-2xl p-4 mb-6 flex items-center gap-4">
          <div className="size-12 bg-red-100 text-red-600 rounded-full flex items-center justify-center shrink-0 animate-pulse">
            <AlertTriangle className="w-6 h-6" />
          </div>
          <div className="flex-1">
            <h4 className="text-sm font-bold text-red-700 dark:text-red-400">Emergency SOS</h4>
            <p className="text-[10px] font-medium text-red-600 dark:text-red-500">Alert security team immediately</p>
          </div>
          <span className="bg-red-600 text-white px-4 py-2 rounded-lg font-bold text-xs">
            MONITOR
          </span>
        </div>

        <div className="space-y-4">
          <h3 className="text-sm font-bold uppercase tracking-widest text-slate-400 px-1">Access History</h3>
          <div className="space-y-3">
            {securityLogs.map((log) => (
              <motion.div 
                key={log.id}
                initial={{ opacity: 0, x: -10 }}
                animate={{ opacity: 1, x: 0 }}
                className="bg-white dark:bg-slate-900 p-4 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex items-center justify-between"
              >
                <div className="flex items-center gap-3">
                  <div className="size-10 bg-slate-100 dark:bg-slate-800 rounded-full flex items-center justify-center text-slate-500">
                    <Shield className="w-5 h-5" />
                  </div>
                  <div>
                    <h4 className="text-sm font-bold">{log.event}</h4>
                    <p className="text-[10px] text-slate-500 dark:text-slate-400 font-medium">{log.visitor} • {log.time}</p>
                  </div>
                </div>
                <span className="text-[9px] font-bold px-2 py-1 bg-green-50 text-green-600 rounded-full uppercase tracking-tighter">
                  {log.status}
                </span>
              </motion.div>
            ))}
          </div>
        </div>
      </div>
    </Layout>
  );
}
