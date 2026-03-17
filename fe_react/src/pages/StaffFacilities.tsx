import { useState } from "react";
import Layout from "../components/Layout";
import { Construction, Search, Filter } from "lucide-react";
import { motion } from "motion/react";

export default function StaffFacilities() {
  const [facilities] = useState([
    { id: 1, name: "Swimming Pool", status: "Operational", lastCheck: "2h ago", health: 98 },
    { id: 2, name: "Gymnasium", status: "Maintenance", lastCheck: "1d ago", health: 65 },
    { id: 3, name: "Elevator B2", status: "Operational", lastCheck: "5h ago", health: 92 },
    { id: 4, name: "Lobby Lighting", status: "Issue Reported", lastCheck: "10m ago", health: 40 },
  ]);

  return (
    <Layout title="Facilities" role="staff">
      <div className="p-4">
        <div className="mb-6 flex items-center gap-3">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
            <input
              type="text"
              placeholder="Search facility..."
              className="w-full rounded-xl border border-slate-200 bg-white py-2 pl-10 pr-4 text-sm outline-none focus:ring-2 focus:ring-[#137fec] dark:border-slate-800 dark:bg-slate-900"
            />
          </div>
          <div className="rounded-xl border border-slate-200 bg-white p-2 dark:border-slate-800 dark:bg-slate-900">
            <Filter className="h-5 w-5 text-slate-500" />
          </div>
        </div>

        <div className="space-y-4">
          {facilities.map((facility) => (
            <motion.div
              key={facility.id}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              className="flex flex-col gap-4 rounded-2xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-800 dark:bg-slate-900"
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div
                    className={`flex size-10 items-center justify-center rounded-xl ${
                      facility.status === "Operational"
                        ? "bg-green-100 text-green-600"
                        : facility.status === "Maintenance"
                          ? "bg-orange-100 text-orange-600"
                          : "bg-red-100 text-red-600"
                    }`}
                  >
                    <Construction className="h-5 w-5" />
                  </div>
                  <div>
                    <h4 className="text-sm font-bold">{facility.name}</h4>
                    <p className="text-[10px] font-medium text-slate-500 dark:text-slate-400">Last checked: {facility.lastCheck}</p>
                  </div>
                </div>
                <span
                  className={`rounded-full px-2 py-1 text-[9px] font-bold uppercase tracking-tighter ${
                    facility.status === "Operational"
                      ? "bg-green-50 text-green-600"
                      : facility.status === "Maintenance"
                        ? "bg-orange-50 text-orange-600"
                        : "bg-red-50 text-red-600"
                  }`}
                >
                  {facility.status}
                </span>
              </div>

              <div className="space-y-1.5">
                <div className="flex items-center justify-between text-[10px] font-bold uppercase tracking-widest text-slate-400">
                  <span>Facility Health</span>
                  <span className={facility.health > 80 ? "text-green-500" : facility.health > 50 ? "text-orange-500" : "text-red-500"}>
                    {facility.health}%
                  </span>
                </div>
                <div className="h-1.5 w-full overflow-hidden rounded-full bg-slate-100 dark:bg-slate-800">
                  <motion.div
                    initial={{ width: 0 }}
                    animate={{ width: `${facility.health}%` }}
                    className={`h-full rounded-full ${
                      facility.health > 80 ? "bg-green-500" : facility.health > 50 ? "bg-orange-500" : "bg-red-500"
                    }`}
                  />
                </div>
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </Layout>
  );
}
