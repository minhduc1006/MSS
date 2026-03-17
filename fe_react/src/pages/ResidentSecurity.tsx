import { useState } from "react";
import Layout from "../components/Layout";
import { Shield, Lock, Eye, Bell, UserCheck, AlertTriangle, X, QrCode, Camera } from "lucide-react";
import { motion, AnimatePresence } from "motion/react";

export default function ResidentSecurity() {
  const [activeModal, setActiveModal] = useState<string | null>(null);

  const securityLogs = [
    { id: 1, event: "Guest Entry", visitor: "John Doe", time: "10:30 AM", status: "Authorized" },
    { id: 2, event: "Gate Access", visitor: "Resident (Self)", time: "08:15 AM", status: "Success" },
    { id: 3, event: "Delivery", visitor: "Amazon Courier", time: "Yesterday", status: "Authorized" },
  ];

  return (
    <Layout title="Security" role="resident">
      <div className="p-4">
        <div className="grid grid-cols-2 gap-4 mb-6">
          <button 
            onClick={() => setActiveModal("qr")}
            className="p-6 bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm flex flex-col items-center gap-3 active:scale-[0.98] transition-all"
          >
            <div className="size-12 bg-green-100 text-green-600 rounded-xl flex items-center justify-center">
              <UserCheck className="w-6 h-6" />
            </div>
            <span className="text-xs font-bold text-slate-700 dark:text-slate-300">Visitor QR</span>
          </button>
          <button 
            onClick={() => setActiveModal("camera")}
            className="p-6 bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm flex flex-col items-center gap-3 active:scale-[0.98] transition-all"
          >
            <div className="size-12 bg-blue-100 text-[#137fec] rounded-xl flex items-center justify-center">
              <Eye className="w-6 h-6" />
            </div>
            <span className="text-xs font-bold text-slate-700 dark:text-slate-300">Live View</span>
          </button>
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
            EMERGENCY
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

      {/* Modals */}
      <AnimatePresence>
        {activeModal && (
          <>
            <motion.div 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setActiveModal(null)}
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
                    {activeModal === "qr" ? <QrCode className="w-6 h-6" /> : <Camera className="w-6 h-6" />}
                  </div>
                  <div>
                    <h3 className="font-bold text-lg">{activeModal === "qr" ? "Visitor Access" : "Lobby Camera"}</h3>
                    <p className="text-xs text-slate-500 font-medium">{activeModal === "qr" ? "Valid for 24 hours" : "Live Stream"}</p>
                  </div>
                </div>
                <button onClick={() => setActiveModal(null)} className="p-2 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-full transition-colors">
                  <X className="w-5 h-5 text-slate-400" />
                </button>
              </div>

              {activeModal === "qr" ? (
                <div className="flex flex-col items-center py-8">
                  <div className="p-4 bg-white rounded-3xl shadow-xl mb-6">
                    <img src="https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=SkylineHeights-Visitor-402" alt="QR Code" className="w-48 h-48" />
                  </div>
                  <p className="text-sm font-bold text-slate-800 dark:text-slate-100 mb-2">Visitor Code: SH-402-992</p>
                  <p className="text-xs text-slate-500 text-center px-8">Share this code with your guest to allow them entry through the main gate.</p>
                </div>
              ) : (
                <div className="flex flex-col gap-4">
                  <div className="aspect-video bg-black rounded-2xl overflow-hidden relative">
                    <img src="https://picsum.photos/seed/lobby/640/360" alt="Camera Feed" className="w-full h-full object-cover opacity-80" />
                    <div className="absolute top-3 left-3 flex items-center gap-2 px-2 py-1 bg-red-600 rounded text-[8px] font-bold text-white uppercase tracking-widest">
                      <div className="size-1.5 bg-white rounded-full animate-pulse" />
                      Live
                    </div>
                    <div className="absolute bottom-3 right-3 text-[8px] font-bold text-white/70 uppercase tracking-widest">
                      Lobby Entrance • Cam 04
                    </div>
                  </div>
                  <div className="grid grid-cols-2 gap-3">
                    <button className="py-3 bg-slate-100 dark:bg-slate-800 rounded-xl text-xs font-bold text-slate-600 dark:text-slate-400">Switch Camera</button>
                    <button className="py-3 bg-slate-100 dark:bg-slate-800 rounded-xl text-xs font-bold text-slate-600 dark:text-slate-400">Take Snapshot</button>
                  </div>
                </div>
              )}

              <button 
                onClick={() => setActiveModal(null)}
                className="w-full mt-6 py-4 bg-[#137fec] text-white rounded-2xl font-bold text-sm shadow-lg shadow-blue-500/20 active:scale-[0.98] transition-all"
              >
                Done
              </button>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </Layout>
  );
}
