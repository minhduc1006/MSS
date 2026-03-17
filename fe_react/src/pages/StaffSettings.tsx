import Layout from "../components/Layout";
import { Bell, LogOut, Moon, Shield, Sun, User } from "lucide-react";
import { useState } from "react";
import { clearSession } from "../lib/api";

export default function StaffSettings() {
  const [isDarkMode, setIsDarkMode] = useState(() => {
    if (typeof window !== "undefined") {
      return document.documentElement.classList.contains("dark");
    }
    return false;
  });

  const toggleDarkMode = () => {
    const next = !isDarkMode;
    setIsDarkMode(next);
    document.documentElement.classList.toggle("dark", next);
  };

  const handleLogout = () => {
    clearSession();
    window.location.href = "/login";
  };

  const menuItems = [
    { icon: User, label: "My Profile", description: "Staff profile information" },
    { icon: Shield, label: "Security & Privacy", description: "Security preferences" },
    { icon: Bell, label: "Notification Settings", description: "Alert preferences" },
  ];

  return (
    <Layout title="Settings" role="staff">
      <div className="p-4">
        <div className="mb-6 flex flex-col items-center rounded-2xl border border-slate-200 bg-white py-8 shadow-sm dark:border-slate-800 dark:bg-slate-900">
          <div className="mb-4 flex size-24 items-center justify-center overflow-hidden rounded-full border-4 border-white bg-slate-100 shadow-xl dark:border-slate-800 dark:bg-slate-800">
            <img src="https://api.dicebear.com/7.x/avataaars/svg?seed=staff" alt="Avatar" className="h-full w-full object-cover" />
          </div>
          <h2 className="text-xl font-extrabold text-slate-900 dark:text-slate-100">Staff Member</h2>
          <p className="mt-1 text-xs font-bold uppercase tracking-widest text-[#137fec]">Maintenance Team · Level 2</p>
        </div>

        <div className="space-y-3">
          {menuItems.map((item) => (
            <div
              key={item.label}
              className="flex w-full items-center justify-between rounded-xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-800 dark:bg-slate-900"
            >
              <div className="flex items-center gap-4">
                <div className="flex size-10 items-center justify-center rounded-xl bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-300">
                  <item.icon className="h-5 w-5" />
                </div>
                <div>
                  <span className="block text-sm font-bold text-slate-700 dark:text-slate-300">{item.label}</span>
                  <span className="block text-xs text-slate-500 dark:text-slate-400">{item.description}</span>
                </div>
              </div>
            </div>
          ))}

          <button
            onClick={toggleDarkMode}
            className="flex w-full items-center justify-between rounded-xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-800 dark:bg-slate-900"
          >
            <div className="flex items-center gap-4">
              <div className="flex size-10 items-center justify-center rounded-xl bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-400">
                {isDarkMode ? <Sun className="h-5 w-5" /> : <Moon className="h-5 w-5" />}
              </div>
              <span className="text-sm font-bold text-slate-700 dark:text-slate-300">Dark Mode</span>
            </div>
            <div className={`h-5 w-10 rounded-full p-1 transition-colors ${isDarkMode ? "bg-[#137fec]" : "bg-slate-300"}`}>
              <div className={`size-3 rounded-full bg-white transition-transform ${isDarkMode ? "translate-x-5" : "translate-x-0"}`} />
            </div>
          </button>
        </div>

        <button
          onClick={handleLogout}
          className="mt-8 flex w-full items-center justify-center gap-2 rounded-xl bg-red-50 py-4 text-sm font-bold text-red-600 transition-all dark:bg-red-900/10"
        >
          <LogOut className="h-5 w-5" />
          Sign Out
        </button>
      </div>
    </Layout>
  );
}
