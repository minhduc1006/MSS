import { useState, useEffect } from "react";
import Layout from "../components/Layout";
import ActionGrid from "../components/ActionGrid";
import { useToast } from "../components/Toast";
import { Shield, AlertTriangle, Construction, CheckCircle, Search, Map, List, UserPlus, MoreHorizontal } from "lucide-react";
import { motion } from "motion/react";

export default function Security() {
  const { showToast } = useToast();
  const [view, setView] = useState<"map" | "list">("list");

  const handleAction = (action: string) => {
    console.log(`Security Action: ${action}`);
  };

  const handleIncidentAction = (title: string, action: string) => {
    showToast(`${action} performed on incident: ${title}`, "success");
  };

  const incidents = [
    { id: 1, title: "Unauthorized Access", zone: "Zone B • West Lobby", time: "2m ago", status: "Open", desc: "A person was seen entering the restricted service elevator area without a keycard.", icon: AlertTriangle, color: "bg-red-100 text-red-600 dark:bg-red-900/30 dark:text-red-400" },
    { id: 2, title: "Broken Lock", zone: "P2 Parking • Gate 4", time: "15m ago", status: "In-Progress", desc: "Assigned to: Officer David K.", icon: Construction, color: "bg-amber-100 text-amber-600 dark:bg-amber-900/30 dark:text-amber-400" },
    { id: 3, title: "Suspicious Package", zone: "Mailroom • Main Tower", time: "1h ago", status: "Resolved", desc: "Package identified as resident delivery. Case closed by Admin.", icon: CheckCircle, color: "bg-green-100 text-green-600 dark:bg-green-900/30 dark:text-green-400" },
  ];

  return (
    <Layout title="Security Tracking" role="admin">
      <div className="bg-white dark:bg-[#101922]">
        <div className="flex border-b border-slate-200 dark:border-slate-800 px-4 justify-between">
          <button 
            onClick={() => setView("map")}
            className={`flex flex-col items-center justify-center border-b-2 pb-3 pt-4 flex-1 transition-all ${view === "map" ? "border-[#137fec] text-[#137fec]" : "border-transparent text-slate-500 dark:text-slate-400"}`}
          >
            <div className="flex items-center gap-2">
              <Map className="w-4 h-4" />
              <p className="text-sm font-bold tracking-tight">Map View</p>
            </div>
          </button>
          <button 
            onClick={() => setView("list")}
            className={`flex flex-col items-center justify-center border-b-2 pb-3 pt-4 flex-1 transition-all ${view === "list" ? "border-[#137fec] text-[#137fec]" : "border-transparent text-slate-500 dark:text-slate-400"}`}
          >
            <div className="flex items-center gap-2">
              <List className="w-4 h-4" />
              <p className="text-sm font-bold tracking-tight">Incident List</p>
            </div>
          </button>
        </div>
      </div>

      <div className="sticky top-[104px] z-10 bg-white dark:bg-[#101922] px-4 py-4 space-y-3 shadow-sm">
        <div className="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm overflow-hidden mb-6">
          <div className="px-4 py-3 border-b border-slate-100 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-800/50">
            <h3 className="text-xs font-bold uppercase tracking-widest text-slate-400">Security Operations</h3>
          </div>
          <ActionGrid onAction={handleAction} extraActions={true} />
        </div>
        <div className="flex w-full items-stretch rounded-xl h-12 bg-slate-100 dark:bg-slate-800 focus-within:ring-2 focus-within:ring-[#137fec]/50 transition-all">
          <div className="flex items-center justify-center pl-4 text-slate-500">
            <Search className="w-5 h-5" />
          </div>
          <input className="w-full bg-transparent border-none focus:ring-0 text-slate-900 dark:text-slate-100 placeholder:text-slate-500 px-3 text-base" placeholder="Search incidents or zones" />
        </div>
        <div className="flex gap-2 overflow-x-auto pb-1 no-scrollbar">
          {["All Status", "Open", "In-Progress", "Resolved"].map((s) => (
            <button key={s} className={`flex h-9 shrink-0 items-center justify-center gap-2 rounded-full px-4 text-sm font-semibold ${s === "All Status" ? "bg-[#137fec] text-white" : "bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300"}`}>
              {s}
            </button>
          ))}
        </div>
      </div>

      <main className="flex-1 p-4 space-y-4">
        {view === "list" ? (
          <>
            <div className="relative w-full h-40 rounded-xl overflow-hidden bg-slate-200 dark:bg-slate-800">
              <img 
                className="w-full h-full object-cover opacity-80" 
                src="https://lh3.googleusercontent.com/aida-public/AB6AXuCaHQUNmwrNwgTb10t05ckgwQQ2O_wsQKsLUY-dwLTT1d8VBr1KbaVlm2GpOxW43gfIu8WPVDvGQgnwpkhzZk2xF1kzu3z6ER68F0uG0dbctOIjBQMbH7lcuuCyPvqzn-L5gx8o4k6dk4ML-eVz0hOyuY2FO8BQQdvmzRAOSItKV4sgFLK7z3AJLSJZHT8lMUyXd9PP3OVeUE8JYpC0-GSwWsBUbn6STCe7gJKsva1NGvBGUg3GyZCDKu1HGKexd9LzDpcF6cz1GeU" 
                alt="Map"
              />
              <div className="absolute inset-0 flex items-center justify-center">
                <div className="bg-[#137fec]/90 text-white px-3 py-1 rounded-full text-xs font-bold shadow-lg animate-pulse flex items-center gap-1">
                  3 Active Incidents
                </div>
              </div>
            </div>

            {incidents.map((incident) => (
              <motion.div 
                key={incident.id}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl p-4 shadow-sm"
              >
                <div className="flex justify-between items-start mb-3">
                  <div className="flex gap-3">
                    <div className={`size-10 rounded-lg flex items-center justify-center shrink-0 ${incident.color}`}>
                      <incident.icon className="w-5 h-5" />
                    </div>
                    <div>
                      <h3 className="font-bold text-slate-900 dark:text-slate-100">{incident.title}</h3>
                      <p className="text-xs text-slate-500 dark:text-slate-400">{incident.zone} • {incident.time}</p>
                    </div>
                  </div>
                  <span className={`px-2 py-1 rounded text-[10px] font-bold uppercase tracking-wider ${incident.color}`}>
                    {incident.status}
                  </span>
                </div>
                <p className="text-sm text-slate-600 dark:text-slate-300 mb-4">{incident.desc}</p>
                <div className="flex gap-2">
                  <button 
                    onClick={() => handleIncidentAction(incident.title, "Assign Staff")}
                    className="flex-1 bg-[#137fec] text-white py-2.5 rounded-lg text-sm font-bold flex items-center justify-center gap-2"
                  >
                    <UserPlus className="w-4 h-4" />
                    Assign Staff
                  </button>
                  <button 
                    onClick={() => handleIncidentAction(incident.title, "More Options")}
                    className="size-10 flex items-center justify-center rounded-lg border border-slate-200 dark:border-slate-700 text-slate-500"
                  >
                    <MoreHorizontal className="w-5 h-5" />
                  </button>
                </div>
              </motion.div>
            ))}
          </>
        ) : (
          <div className="flex flex-col items-center justify-center h-64 text-slate-500">
            <Map className="w-12 h-12 mb-2 opacity-20" />
            <p className="text-sm">Interactive Map Loading...</p>
          </div>
        )}
      </main>
    </Layout>
  );
}
