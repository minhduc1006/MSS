import { ReactNode, useState, useEffect } from "react";
import { NavLink } from "react-router-dom";
import { useToast } from "./Toast";
import { 
  LayoutDashboard, Users, ReceiptText, Shield, Settings, Bell, Menu, 
  Construction, Building2, LogOut, UserCheck, X, User, CreditCard, 
  HelpCircle, Info, Moon, Sun
} from "lucide-react";
import { motion, AnimatePresence } from "motion/react";
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";
import { clearSession } from "../lib/api";

function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

interface LayoutProps {
  children: ReactNode;
  title?: string;
  role?: "admin" | "resident" | "staff";
}

export default function Layout({ children, title = "Skyline Heights", role = "admin" }: LayoutProps) {
  const { showToast } = useToast();
  const [isMenuOpen, setIsMenuOpen] = useState(false);
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

  const handleNotifications = () => {
    showToast("No new notifications", "info");
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

  const navItems = role === "admin" 
    ? [
        { icon: LayoutDashboard, label: "Overview", path: "/admin" },
        { icon: Users, label: "Residents", path: "/admin/residents" },
        { icon: UserCheck, label: "Staff", path: "/admin/staff" },
        { icon: ReceiptText, label: "Billing", path: "/admin/billing" },
        { icon: Construction, label: "Facilities", path: "/admin/facilities" },
        { icon: Building2, label: "Apartment", path: "/admin/apartment" },
        { icon: Shield, label: "Security", path: "/admin/security" },
      ]
    : role === "staff"
    ? [
        { icon: LayoutDashboard, label: "Tasks", path: "/staff" },
        { icon: Construction, label: "Facilities", path: "/staff/facilities" },
        { icon: Shield, label: "Security", path: "/staff/security" },
        { icon: Settings, label: "Settings", path: "/staff/settings" },
      ]
    : [
        { icon: LayoutDashboard, label: "Home", path: "/resident" },
        { icon: ReceiptText, label: "Bills", path: "/resident/bills" },
        { icon: Shield, label: "Security", path: "/resident/security" },
        { icon: Settings, label: "Account", path: "/resident/account" },
      ];

  return (
    <div className="relative flex min-h-screen w-full flex-col overflow-x-hidden max-w-md mx-auto bg-white dark:bg-[#101922] shadow-2xl font-['Manrope']">
      {/* Side Menu Drawer */}
      <AnimatePresence>
        {isMenuOpen && (
          <>
            <motion.div 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setIsMenuOpen(false)}
              className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 max-w-md mx-auto"
            />
            <motion.div 
              initial={{ x: "-100%" }}
              animate={{ x: 0 }}
              exit={{ x: "-100%" }}
              transition={{ type: "spring", damping: 25, stiffness: 200 }}
              className="fixed inset-y-0 left-0 w-4/5 max-w-[320px] bg-white dark:bg-[#101922] z-[60] shadow-2xl flex flex-col"
            >
              <div className="p-6 border-b border-slate-100 dark:border-slate-800 flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="size-10 bg-[#137fec] rounded-xl flex items-center justify-center text-white font-bold text-xl">S</div>
                  <div>
                    <h3 className="font-bold text-slate-900 dark:text-slate-100">Skyline Heights</h3>
                    <p className="text-[10px] font-bold text-[#137fec] uppercase tracking-widest">{role} Portal</p>
                  </div>
                </div>
                <button onClick={() => setIsMenuOpen(false)} className="p-2 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-full transition-colors">
                  <X className="w-5 h-5 text-slate-500" />
                </button>
              </div>

              <div className="flex-1 overflow-y-auto py-4 px-4 space-y-1">
                <div className="px-2 py-2 text-[10px] font-bold text-slate-400 uppercase tracking-widest">Main Menu</div>
                {navItems.map((item) => (
                  <NavLink
                    key={item.path}
                    to={item.path}
                    onClick={() => setIsMenuOpen(false)}
                    className={({ isActive }) => cn(
                      "flex items-center gap-3 px-4 py-3 rounded-xl transition-all font-semibold text-sm",
                      isActive 
                        ? "bg-[#137fec]/10 text-[#137fec]" 
                        : "text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800"
                    )}
                  >
                    <item.icon className="w-5 h-5" />
                    {item.label}
                  </NavLink>
                ))}

                <div className="h-px bg-slate-100 dark:bg-slate-800 my-4 mx-2"></div>
                <div className="px-2 py-2 text-[10px] font-bold text-slate-400 uppercase tracking-widest">Preferences</div>
                
                <button 
                  onClick={toggleDarkMode}
                  className="w-full flex items-center justify-between px-4 py-3 rounded-xl text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800 font-semibold text-sm transition-all"
                >
                  <div className="flex items-center gap-3">
                    {isDarkMode ? <Sun className="w-5 h-5" /> : <Moon className="w-5 h-5" />}
                    {isDarkMode ? "Light Mode" : "Dark Mode"}
                  </div>
                  <div className={cn(
                    "w-10 h-5 rounded-full p-1 transition-colors",
                    isDarkMode ? "bg-[#137fec]" : "bg-slate-300"
                  )}>
                    <div className={cn(
                      "size-3 bg-white rounded-full transition-transform",
                      isDarkMode ? "translate-x-5" : "translate-x-0"
                    )} />
                  </div>
                </button>

                <button className="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800 font-semibold text-sm transition-all">
                  <HelpCircle className="w-5 h-5" />
                  Support Center
                </button>
                <button className="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800 font-semibold text-sm transition-all">
                  <Info className="w-5 h-5" />
                  About App
                </button>
              </div>

              <div className="p-6 border-t border-slate-100 dark:border-slate-800">
                <button 
                  onClick={handleLogout}
                  className="w-full flex items-center justify-center gap-2 py-3 bg-red-50 dark:bg-red-900/10 text-red-600 rounded-xl font-bold text-sm hover:bg-red-100 transition-all active:scale-[0.98]"
                >
                  <LogOut className="w-5 h-5" />
                  Sign Out
                </button>
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>

      {/* Header */}
      <header className="sticky top-0 z-30 flex flex-col bg-white/80 dark:bg-[#101922]/80 backdrop-blur-md border-b border-[#137fec]/10">
        <div className="flex items-center p-4 justify-between">
          <button 
            onClick={() => setIsMenuOpen(true)}
            className="text-slate-900 dark:text-slate-100 flex size-10 items-center justify-center rounded-full hover:bg-[#137fec]/10 cursor-pointer transition-colors"
          >
            <Menu className="w-6 h-6" />
          </button>
          <h2 className="text-lg font-bold tracking-tight flex-1 px-2 text-slate-900 dark:text-slate-100">{title}</h2>
          <div className="flex gap-2">
            <button 
              onClick={handleNotifications}
              className="flex size-10 items-center justify-center rounded-full hover:bg-[#137fec]/10 text-[#137fec] transition-colors"
            >
              <Bell className="w-6 h-6" />
            </button>
            <div className="size-10 rounded-full bg-slate-100 dark:bg-slate-800 flex items-center justify-center border border-slate-200 dark:border-slate-700 overflow-hidden">
              <img src={`https://api.dicebear.com/7.x/avataaars/svg?seed=${role}`} alt="Avatar" className="w-full h-full object-cover" />
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 pb-24 overflow-y-auto">
        {children}
      </main>

      {/* Bottom Navigation */}
      <nav className="fixed bottom-0 left-0 right-0 max-w-md mx-auto flex items-center bg-white/90 dark:bg-[#101922]/90 backdrop-blur-xl border-t border-slate-200 dark:border-slate-800 px-4 pb-6 pt-2 z-40">
        {navItems.slice(0, 4).map((item) => (
          <NavLink
            key={item.path}
            to={item.path}
            className={({ isActive }) => cn(
              "flex flex-1 flex-col items-center justify-center gap-1 transition-all",
              isActive ? "text-[#137fec]" : "text-slate-400 dark:text-slate-500"
            )}
          >
            {({ isActive }) => (
              <>
                <item.icon className={cn("w-6 h-6 transition-transform", isActive && "scale-110")} />
                <p className="text-[10px] font-bold uppercase tracking-wider">{item.label}</p>
              </>
            )}
          </NavLink>
        ))}
      </nav>
    </div>
  );
}
