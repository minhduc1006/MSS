import Layout from "../components/Layout";
import { Construction } from "lucide-react";

const facilities = [
  { name: "Swimming Pool", status: "Open", icon: "Pool" },
  { name: "Fitness Center", status: "Maintenance", icon: "Gym" },
  { name: "Community Hall", status: "Open", icon: "Hall" },
];

export default function Facilities() {
  return (
    <Layout title="Facility & Service" role="admin">
      <div className="p-4 lg:p-6">
        <div className="mb-6 flex items-center gap-3 rounded-2xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-800 dark:bg-slate-900">
          <div className="rounded-xl bg-orange-100 p-3 dark:bg-orange-900/30">
            <Construction className="h-6 w-6 text-orange-600 dark:text-orange-400" />
          </div>
          <div>
            <h2 className="text-lg font-bold tracking-tight">Facility Management</h2>
            <p className="text-xs font-medium text-slate-500 dark:text-slate-400">Manage building services and amenities</p>
          </div>
        </div>
        <div className="mt-6 space-y-4">
          <h3 className="px-1 text-sm font-bold">Active Facilities</h3>
          <div className="grid gap-4 xl:grid-cols-2">
            {facilities.map((facility) => (
              <div
                key={facility.name}
                className="flex items-center justify-between rounded-xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-800 dark:bg-slate-900"
              >
                <div className="flex items-center gap-3">
                  <span className="rounded-lg bg-slate-100 px-3 py-2 text-xs font-bold uppercase tracking-wider text-slate-600 dark:bg-slate-800 dark:text-slate-300">
                    {facility.icon}
                  </span>
                  <span className="text-sm font-bold">{facility.name}</span>
                </div>
                <span
                  className={`rounded-full px-2 py-1 text-[10px] font-bold uppercase ${
                    facility.status === "Open" ? "bg-emerald-100 text-emerald-600" : "bg-amber-100 text-amber-600"
                  }`}
                >
                  {facility.status}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </Layout>
  );
}
