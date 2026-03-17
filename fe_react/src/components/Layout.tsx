import { ReactNode, useState, useEffect } from "react";
import { NavLink } from "react-router-dom";
import { useToast } from "./Toast";
import { 
  LayoutDashboard, Users, ReceiptText, Shield, Settings, Bell, Menu,
  Construction, Building2, LogOut, UserCheck, X, 
  Moon, Sun
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
        { icon: Construction, label: "Services", path: "/resident/bookings" },
        { icon: Shield, label: "Security", path: "/resident/security" },
        { icon: Settings, label: "Account", path: "/resident/account" },
      ];

  const isAdmin = role === "admin";

  return (
    <div
      className={cn(
        "relative min-h-screen w-full overflow-x-hidden font-['Manrope']",
        isAdmin
          ? "bg-slate-100 text-slate-900 dark:bg-[#0b1220] lg:p-4"
          : "max-w-md mx-auto flex flex-col bg-white shadow-2xl dark:bg-[#101922]",
      )}
    >
      {/* Side Menu Drawer */}
      <AnimatePresence>
        {isMenuOpen && (
          <>
            <motion.div 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setIsMenuOpen(false)}
              className={cn(
                "fixed inset-0 z-50 bg-black/60 backdrop-blur-sm",
                !isAdmin && "max-w-md mx-auto",
              )}
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

      <div className={cn(isAdmin && "lg:grid lg:min-h-[calc(100vh-2rem)] lg:grid-cols-[280px_minmax(0,1fr)] lg:gap-4")}>
        {isAdmin && (
          <aside className="hidden lg:flex lg:flex-col lg:rounded-[28px] lg:border lg:border-white/60 lg:bg-white lg:p-5 lg:shadow-[0_18px_60px_rgba(15,23,42,0.08)] dark:border-slate-800 dark:bg-[#101922]">
            <div className="flex items-center gap-3 border-b border-slate-100 pb-5 dark:border-slate-800">
              <div className="flex size-12 items-center justify-center rounded-2xl bg-[#137fec] text-lg font-bold text-white shadow-lg shadow-blue-500/30">S</div>
              <div>
                <h1 className="text-base font-extrabold text-slate-900 dark:text-slate-100">Skyline Heights</h1>
                <p className="text-[11px] font-bold uppercase tracking-[0.28em] text-[#137fec]">Admin Portal</p>
              </div>
            </div>

            <div className="mt-6 space-y-1">
              {navItems.map((item) => (
                <NavLink
                  key={item.path}
                  to={item.path}
                  className={({ isActive }) =>
                    cn(
                      "flex items-center gap-3 rounded-2xl px-4 py-3 text-sm font-semibold transition-all",
                      isActive
                        ? "bg-[#137fec] text-white shadow-lg shadow-blue-500/25"
                        : "text-slate-600 hover:bg-slate-50 dark:text-slate-300 dark:hover:bg-slate-800/80",
                    )
                  }
                >
                  <item.icon className="h-5 w-5" />
                  <span>{item.label}</span>
                </NavLink>
              ))}
            </div>

            <div className="mt-auto space-y-3 pt-6">
              <button
                onClick={toggleDarkMode}
                className="flex w-full items-center justify-between rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-semibold text-slate-700 transition-colors hover:border-[#137fec]/30 dark:border-slate-700 dark:bg-[#101922] dark:text-slate-200"
              >
                <div className="flex items-center gap-3">
                  {isDarkMode ? <Sun className="h-5 w-5" /> : <Moon className="h-5 w-5" />}
                  <span>{isDarkMode ? "Light Mode" : "Dark Mode"}</span>
                </div>
                <div className={cn("h-5 w-10 rounded-full p-1 transition-colors", isDarkMode ? "bg-[#137fec]" : "bg-slate-300")}>
                  <div className={cn("size-3 rounded-full bg-white transition-transform", isDarkMode ? "translate-x-5" : "translate-x-0")} />
                </div>
              </button>
              <button 
                onClick={handleLogout}
                className="flex w-full items-center justify-center gap-2 rounded-2xl bg-red-50 py-3 text-sm font-bold text-red-600 transition-all hover:bg-red-100 dark:bg-red-900/10"
              >
                <LogOut className="h-5 w-5" />
                Sign Out
              </button>
            </div>
          </aside>
        )}

        <div
          className={cn(
            "relative flex min-h-screen flex-col",
            isAdmin
              ? "bg-transparent lg:min-h-[calc(100vh-2rem)]"
              : "bg-white dark:bg-[#101922]",
          )}
        >
          {/* Header */}
          <header
            className={cn(
              "sticky top-0 z-30 flex flex-col backdrop-blur-md",
              isAdmin
                ? "border-b border-slate-200/80 bg-white/85 dark:border-slate-800 dark:bg-[#101922]/85 lg:rounded-[28px] lg:border lg:bg-white/92 lg:px-2"
                : "border-b border-[#137fec]/10 bg-white/80 dark:bg-[#101922]/80",
            )}
          >
            <div className="flex items-center justify-between p-4">
              <button 
                onClick={() => setIsMenuOpen(true)}
                className={cn(
                  "flex size-10 items-center justify-center rounded-full text-slate-900 transition-colors hover:bg-[#137fec]/10 dark:text-slate-100",
                  isAdmin && "lg:hidden",
                )}
              >
                <Menu className="w-6 h-6" />
              </button>
              <div className="min-w-0 flex-1 px-2">
                <h2 className="truncate text-lg font-bold tracking-tight text-slate-900 dark:text-slate-100">{title}</h2>
              </div>
              <div className="flex gap-2">
                <button 
                  onClick={handleNotifications}
                  className="flex size-10 items-center justify-center rounded-full text-[#137fec] transition-colors hover:bg-[#137fec]/10"
                >
                  <Bell className="w-6 h-6" />
                </button>
                <div className="flex size-10 items-center justify-center overflow-hidden rounded-full border border-slate-200 bg-slate-100 dark:border-slate-700 dark:bg-slate-800">
                  <img src={`https://api.dicebear.com/7.x/avataaars/svg?seed=${role}`} alt="Avatar" className="h-full w-full object-cover" />
                </div>
              </div>
            </div>
          </header>

          {/* Main Content */}
          <main className={cn("flex-1 overflow-y-auto", isAdmin ? "pb-8 lg:pt-2" : "pb-24")}>
            {children}
          </main>

          {/* Bottom Navigation */}
          <nav className={cn("fixed bottom-0 left-0 right-0 z-40 flex items-center bg-white/90 px-4 pb-6 pt-2 backdrop-blur-xl dark:bg-[#101922]/90", isAdmin ? "mx-auto max-w-md border-t border-slate-200 dark:border-slate-800 lg:hidden" : "max-w-md mx-auto border-t border-slate-200 dark:border-slate-800")}>
            {(isAdmin ? navItems.slice(0, 4) : navItems).map((item) => (
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
      </div>
    </div>
  );
}
