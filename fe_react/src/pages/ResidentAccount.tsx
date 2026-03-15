import Layout from "../components/Layout";
import { User, Mail, Phone, MapPin, CreditCard, Shield, Bell, LogOut, ChevronRight, Moon, Sun } from "lucide-react";
import { motion } from "motion/react";
import { useToast } from "../components/Toast";
import { useState, useEffect } from "react";
import { clearSession } from "../lib/api";

export default function ResidentAccount() {
  const { showToast } = useToast();
  const [isDarkMode, setIsDarkMode] = useState(() => {
    if (typeof window !== 'undefined') {
      return document.documentElement.classList.contains('dark');
    }
    return false;
  });

  useEffect(() => {
    const isDark = document.documentElement.classList.contains('dark');
    setIsDarkMode(isDark);
  }, []);

  const handleLogout = () => {
    showToast("Logging out...", "info");
    clearSession();
    setTimeout(() => {
      window.location.href = "/login";
    }, 500);
  };

  const toggleDarkMode = () => {
    const newMode = !isDarkMode;
    setIsDarkMode(newMode);
    if (newMode) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
    showToast(`${newMode ? 'Dark' : 'Light'} mode enabled`, "info");
  };

  const menuItems = [
    { icon: User, label: "Personal Information", color: "text-blue-500 bg-blue-50" },
    { icon: MapPin, label: "My Apartment (Unit 402)", color: "text-green-500 bg-green-50" },
    { icon: CreditCard, label: "Payment Methods", color: "text-orange-500 bg-orange-50" },
    { icon: Shield, label: "Security & Privacy", color: "text-purple-500 bg-purple-50" },
    { icon: Bell, label: "Notification Settings", color: "text-yellow-500 bg-yellow-50" },
  ];

  return (
    <Layout title="My Account" role="resident">
      <div className="p-4">
        <div className="flex flex-col items-center py-8 bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm mb-6">
          <div className="size-24 rounded-full bg-slate-100 dark:bg-slate-800 flex items-center justify-center border-4 border-white dark:border-slate-800 shadow-xl overflow-hidden mb-4">
            <img src="https://api.dicebear.com/7.x/avataaars/svg?seed=resident" alt="Avatar" className="w-full h-full object-cover" />
          </div>
          <h2 className="text-xl font-extrabold text-slate-900 dark:text-slate-100">Alex Johnson</h2>
          <p className="text-xs font-bold text-[#137fec] uppercase tracking-widest mt-1">Tower A • Unit 402</p>
          
          <div className="flex gap-4 mt-6">
            <div className="flex flex-col items-center">
              <span className="text-lg font-extrabold">12</span>
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Bills</span>
            </div>
            <div className="w-px h-8 bg-slate-100 dark:bg-slate-800 self-center"></div>
            <div className="flex flex-col items-center">
              <span className="text-lg font-extrabold">3</span>
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Guests</span>
            </div>
            <div className="w-px h-8 bg-slate-100 dark:bg-slate-800 self-center"></div>
            <div className="flex flex-col items-center">
              <span className="text-lg font-extrabold">0</span>
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Issues</span>
            </div>
          </div>
        </div>

        <div className="space-y-3">
          {menuItems.map((item, index) => (
            <motion.button 
              key={index}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.05 }}
              onClick={() => showToast(`Opening ${item.label}`, "info")}
              className="w-full bg-white dark:bg-slate-900 p-4 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex items-center justify-between active:scale-[0.98] transition-all"
            >
              <div className="flex items-center gap-4">
                <div className={`size-10 rounded-xl flex items-center justify-center ${item.color}`}>
                  <item.icon className="w-5 h-5" />
                </div>
                <span className="text-sm font-bold text-slate-700 dark:text-slate-300">{item.label}</span>
              </div>
              <ChevronRight className="w-5 h-5 text-slate-400" />
            </motion.button>
          ))}

          <button 
            onClick={toggleDarkMode}
            className="w-full bg-white dark:bg-slate-900 p-4 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex items-center justify-between active:scale-[0.98] transition-all"
          >
            <div className="flex items-center gap-4">
              <div className={`size-10 rounded-xl flex items-center justify-center bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400`}>
                {isDarkMode ? <Sun className="w-5 h-5" /> : <Moon className="w-5 h-5" />}
              </div>
              <span className="text-sm font-bold text-slate-700 dark:text-slate-300">Dark Mode</span>
            </div>
            <div className={`w-10 h-5 rounded-full p-1 transition-colors ${isDarkMode ? 'bg-[#137fec]' : 'bg-slate-300'}`}>
              <div className={`size-3 bg-white rounded-full transition-transform ${isDarkMode ? 'translate-x-5' : 'translate-x-0'}`} />
            </div>
          </button>
        </div>

        <button 
          onClick={handleLogout}
          className="w-full mt-8 flex items-center justify-center gap-2 py-4 bg-red-50 dark:bg-red-900/10 text-red-600 rounded-xl font-bold text-sm hover:bg-red-100 transition-all active:scale-[0.98]"
        >
          <LogOut className="w-5 h-5" />
          Sign Out
        </button>
      </div>
    </Layout>
  );
}
