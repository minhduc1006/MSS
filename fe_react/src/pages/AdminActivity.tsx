import { useEffect, useMemo, useState } from "react";
import { Activity, HandCoins, HandPlatter, RefreshCw, UserPlus } from "lucide-react";
import Layout from "../components/Layout";
import { useToast } from "../components/Toast";
import { OPERATIONS_API_BASE, apiRequest, type ActivityItem } from "../lib/api";

export default function AdminActivity() {
  const { showToast } = useToast();
  const [items, setItems] = useState<ActivityItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    void loadActivities();
  }, []);

  const summary = useMemo(() => {
    const billing = items.filter((item) => item.type === "billing").length;
    const maintenance = items.filter((item) => item.type === "maintenance").length;
    const onboarding = items.filter((item) => item.type === "onboarding").length;
    return { billing, maintenance, onboarding };
  }, [items]);

  return (
    <Layout title="Recent Activity" role="admin">
      <div className="p-4 lg:p-6">
        <div className="mb-6 flex items-center justify-between rounded-2xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-800 dark:bg-slate-900">
          <div className="flex items-center gap-3">
            <div className="rounded-xl bg-[#137fec]/10 p-3 text-[#137fec]">
              <Activity className="h-6 w-6" />
            </div>
            <div>
              <h2 className="text-lg font-bold tracking-tight">Admin Activity Feed</h2>
              <p className="text-xs font-medium text-slate-500 dark:text-slate-400">Full operations feed synced from `operations-service`.</p>
            </div>
          </div>
          <button
            onClick={() => void loadActivities()}
            className="inline-flex items-center gap-2 rounded-xl border border-slate-200 px-3 py-2 text-sm font-bold text-slate-700 dark:border-slate-700 dark:text-slate-200"
          >
            <RefreshCw className="h-4 w-4" />
            Refresh
          </button>
        </div>

        <section className="mb-6 grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
          <MetricCard label="Billing" value={summary.billing} icon={HandCoins} tone="text-[#137fec] bg-[#137fec]/10" />
          <MetricCard label="Maintenance" value={summary.maintenance} icon={HandPlatter} tone="text-orange-600 bg-orange-100" />
          <MetricCard label="Onboarding" value={summary.onboarding} icon={UserPlus} tone="text-emerald-600 bg-emerald-100" />
        </section>

        <section className="rounded-2xl border border-slate-200 bg-white shadow-sm dark:border-slate-800 dark:bg-slate-900">
          <div className="border-b border-slate-100 px-4 py-3 dark:border-slate-800">
            <h3 className="text-sm font-bold">Timeline</h3>
          </div>

          <div className="p-4">
            {isLoading ? (
              <div className="rounded-2xl border border-dashed border-slate-300 p-6 text-center text-sm text-slate-500 dark:border-slate-700">
                Loading activity feed...
              </div>
            ) : error ? (
              <div className="rounded-2xl border border-rose-200 bg-rose-50 p-4 text-sm text-rose-700 dark:border-rose-900/40 dark:bg-rose-900/10 dark:text-rose-300">
                {error}
              </div>
            ) : items.length === 0 ? (
              <div className="rounded-2xl border border-dashed border-slate-300 p-6 text-center text-sm text-slate-500 dark:border-slate-700">
                No recent activity is available right now.
              </div>
            ) : (
              <div className="space-y-4">
                {items.map((item) => (
                  <div key={item.id} className="flex gap-4 rounded-2xl border border-slate-200 p-4 dark:border-slate-800">
                    <div className={`mt-1 flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl ${activityTone(item.type)}`}>
                      <Activity className="h-5 w-5" />
                    </div>
                    <div className="min-w-0 flex-1">
                      <div className="flex items-start justify-between gap-3">
                        <h4 className="text-sm font-bold text-slate-900 dark:text-slate-100">{item.title}</h4>
                        <span className="rounded-full bg-slate-100 px-2 py-1 text-[10px] font-bold uppercase tracking-wider text-slate-600 dark:bg-slate-800 dark:text-slate-300">
                          {item.type}
                        </span>
                      </div>
                      <p className="mt-2 text-sm text-slate-600 dark:text-slate-300">{item.description}</p>
                      <p className="mt-3 text-xs font-medium text-slate-400">{formatDateTime(item.createdAt)}</p>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </section>
      </div>
    </Layout>
  );

  async function loadActivities() {
    setIsLoading(true);
    setError(null);
    try {
      const data = await apiRequest<ActivityItem[]>(`${OPERATIONS_API_BASE}/activity`);
      setItems(data);
    } catch (loadError) {
      const message = loadError instanceof Error ? loadError.message : "Unable to load activity feed.";
      setError(message);
      showToast(message, "error");
    } finally {
      setIsLoading(false);
    }
  }
}

function MetricCard({
  label,
  value,
  icon: Icon,
  tone,
}: {
  label: string;
  value: number;
  icon: typeof Activity;
  tone: string;
}) {
  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-800 dark:bg-slate-900">
      <div className="mb-3 flex items-center justify-between">
        <div className={`rounded-xl p-3 ${tone}`}>
          <Icon className="h-5 w-5" />
        </div>
      </div>
      <p className="text-xs font-bold uppercase tracking-widest text-slate-400">{label}</p>
      <p className="mt-2 text-3xl font-extrabold text-slate-900 dark:text-slate-100">{value}</p>
    </div>
  );
}

function activityTone(kind: string) {
  if (kind === "billing") return "bg-[#137fec]/10 text-[#137fec]";
  if (kind === "maintenance") return "bg-orange-100 text-orange-600";
  if (kind === "onboarding") return "bg-emerald-100 text-emerald-600";
  return "bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-300";
}

function formatDateTime(value: string) {
  return new Date(value).toLocaleString("en-US", {
    month: "short",
    day: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}
