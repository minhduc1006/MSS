import { useState } from "react";
import Layout from "../components/Layout";
import { Wallet, Calendar, CreditCard, Waves, Dumbbell, Headset, Bell, ChevronRight } from "lucide-react";
import { motion } from "motion/react";
import { useNavigate } from "react-router-dom";

interface Booking {
  id: string;
  type: string;
  title: string;
  time: string;
  icon: any;
}

export default function ResidentDashboard() {
  const navigate = useNavigate();
  const [resident] = useState({
    name: "John Doe",
    unit: "402",
    tower: "Skyview Tower",
    balance: 1250.00,
    dueDate: "Oct 1st",
  });

  const [bookings, setBookings] = useState<Booking[]>([
    { id: "1", type: "lounge", title: "Community Lounge", time: "Today, 6:00 PM - 8:00 PM", icon: Calendar }
  ]);

  const quickActions = [
    { id: "pay", label: "Pay Now", icon: CreditCard, color: "bg-[#137fec] text-white" },
    { id: "pool", label: "Book Pool", icon: Waves, color: "bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 text-slate-700 dark:text-slate-200 shadow-sm" },
    { id: "gym", label: "Book Gym", icon: Dumbbell, color: "bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 text-slate-700 dark:text-slate-200 shadow-sm" },
    { id: "help", label: "Help Desk", icon: Headset, color: "bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 text-slate-700 dark:text-slate-200 shadow-sm" },
  ];

  const handleAction = (id: string) => {
    if (id === "pay") {
      navigate("/resident/bills");
    } else if (id === "pool" || id === "gym") {
      navigate("/resident/bookings");
    } else if (id === "help") {
      navigate("/resident/security");
    }
  };

  return (
    <Layout title="Resident Portal" role="resident">
      <div className="p-4">
        {/* Welcome Header */}
        <div className="flex items-center gap-3 mb-6">
          <div className="size-10 shrink-0 overflow-hidden rounded-full bg-[#137fec]/10 flex items-center justify-center">
            <img 
              className="size-full object-cover" 
              src="https://api.dicebear.com/7.x/avataaars/svg?seed=resident" 
              alt="Resident"
            />
          </div>
          <div>
            <p className="text-xs text-slate-500 dark:text-slate-400 font-medium">Welcome back,</p>
            <h2 className="text-slate-900 dark:text-slate-100 text-lg font-bold leading-tight tracking-tight">{resident.name}</h2>
          </div>
        </div>

        {/* Balance Section */}
        <section className="mb-8">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-bold">Unit {resident.unit} • {resident.tower}</h2>
            <span className="px-2 py-1 bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400 text-xs font-bold rounded">ACTIVE</span>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div className="ui-hover-lift ui-hover-accent flex flex-col gap-2 rounded-xl p-5 border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 shadow-sm">
              <div className="flex items-center gap-2 text-slate-500 dark:text-slate-400">
                <Wallet className="w-4 h-4" />
                <p className="text-xs font-semibold uppercase tracking-wider">Balance</p>
              </div>
              <p className="text-slate-900 dark:text-slate-100 text-2xl font-extrabold">${resident.balance.toLocaleString()}</p>
              <p className="text-red-500 text-xs font-bold">Due in 4 days</p>
            </div>
            <div className="ui-hover-lift ui-hover-accent flex flex-col gap-2 rounded-xl p-5 border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 shadow-sm">
              <div className="flex items-center gap-2 text-slate-500 dark:text-slate-400">
                <Calendar className="w-4 h-4" />
                <p className="text-xs font-semibold uppercase tracking-wider">Next Due</p>
              </div>
              <p className="text-slate-900 dark:text-slate-100 text-2xl font-extrabold">{resident.dueDate}</p>
              <p className="text-slate-500 dark:text-slate-400 text-xs font-medium">Rent & Utilities</p>
            </div>
          </div>
        </section>

        {/* Quick Actions */}
        <section className="mb-8">
          <h3 className="text-base font-bold mb-4">Quick Actions</h3>
          <div className="flex gap-3 overflow-x-auto pb-2 -mx-4 px-4 no-scrollbar">
            {quickActions.map((action) => (
              <button 
                key={action.id}
                onClick={() => handleAction(action.id)}
                className={`ui-hover-soft ${action.id === "pay" ? "" : "ui-hover-accent"} flex flex-col items-center justify-center min-w-[100px] h-24 gap-2 rounded-xl shadow-sm cursor-pointer active:scale-95 transition-all ${action.color}`}
              >
                <action.icon className="w-6 h-6" />
                <span className="text-xs font-bold">{action.label}</span>
              </button>
            ))}
          </div>
        </section>

        {/* Active Bookings */}
        <section className="mb-8">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-base font-bold">Active Bookings</h3>
            <button 
              onClick={() => navigate("/resident/bookings")}
              className="text-[#137fec] text-xs font-bold uppercase tracking-wider"
            >
              View All
            </button>
          </div>
          <div className="flex flex-col gap-3">
            {bookings.length > 0 ? (
              bookings.map((booking) => (
                <motion.div 
                  layout
                  initial={{ opacity: 0, scale: 0.95 }}
                  animate={{ opacity: 1, scale: 1 }}
                  key={booking.id}
                  onClick={() => navigate("/resident/bookings")}
                  className="ui-hover-lift ui-hover-accent flex items-center gap-4 p-4 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl cursor-pointer transition-all"
                >
                  <div className="size-12 rounded-lg bg-[#137fec]/10 text-[#137fec] flex items-center justify-center">
                    <booking.icon className="w-6 h-6" />
                  </div>
                  <div className="flex-1">
                    <h4 className="text-sm font-bold">{booking.title}</h4>
                    <p className="text-xs text-slate-500 dark:text-slate-400">{booking.time}</p>
                  </div>
                  <ChevronRight className="text-slate-300 w-5 h-5" />
                </motion.div>
              ))
            ) : (
              <div className="py-8 text-center border-2 border-dashed border-slate-100 dark:border-slate-800 rounded-2xl">
                <p className="text-sm text-slate-400 font-medium">No active bookings</p>
              </div>
            )}
          </div>
        </section>

        {/* Building News */}
        <section>
          <h3 className="text-base font-bold mb-4">Building News</h3>
          <div className="space-y-4">
            <div className="ui-hover-lift rounded-xl border border-[#137fec]/20 bg-[#137fec]/5 p-4 dark:bg-[#137fec]/10">
              <div className="flex gap-3">
                <div className="size-8 rounded-full bg-[#137fec] text-white flex items-center justify-center shrink-0">
                  <Bell className="w-4 h-4" />
                </div>
                <div>
                  <h4 className="text-sm font-bold text-slate-900 dark:text-slate-100 leading-tight">Elevator maintenance on Monday</h4>
                  <p className="text-xs text-slate-600 dark:text-slate-400 mt-1 leading-relaxed">Elevator B will be out of service from 9 AM to 3 PM for scheduled routine maintenance.</p>
                  <p className="text-[10px] text-slate-400 mt-2 font-medium">2 hours ago</p>
                </div>
              </div>
            </div>
          </div>
        </section>
      </div>

    </Layout>
  );
}
