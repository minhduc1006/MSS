import { useEffect, useMemo, useState } from "react";
import { AnimatePresence, motion } from "motion/react";
import { Eye, Plus, RefreshCw, Search, Trash2, UserRoundCheck, Users, X } from "lucide-react";
import Layout from "../components/Layout";
import { useToast } from "../components/Toast";
import { AUTH_API_BASE, apiRequest, type ResidentItem } from "../lib/api";

const FILTERS = ["All", "Active", "Deactivated"] as const;

export default function ResidentList() {
  const { showToast } = useToast();
  const [residents, setResidents] = useState<ResidentItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [query, setQuery] = useState("");
  const [filter, setFilter] = useState<(typeof FILTERS)[number]>("All");
  const [selectedResident, setSelectedResident] = useState<ResidentItem | null>(null);
  const [createModalOpen, setCreateModalOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [form, setForm] = useState({
    fullName: "",
    unitNumber: "",
    tower: "Skyview Tower",
    email: "",
  });

  useEffect(() => {
    void loadResidents();
  }, []);

  const filteredResidents = useMemo(() => {
    const normalized = query.trim().toLowerCase();
    return residents.filter((resident) => {
      const matchesQuery =
        normalized.length === 0 ||
        resident.fullName.toLowerCase().includes(normalized) ||
        resident.unitNumber.toLowerCase().includes(normalized) ||
        resident.email.toLowerCase().includes(normalized);
      const matchesFilter = filter === "All" || resident.status === filter;
      return matchesQuery && matchesFilter;
    });
  }, [filter, query, residents]);

  const activeCount = residents.filter((resident) => resident.status === "Active").length;
  const deactivatedCount = residents.filter((resident) => resident.status === "Deactivated").length;

  return (
    <Layout title="Resident Management" role="admin">
      <div className="p-4 lg:p-6">
        <div className="mb-6 flex items-center justify-between rounded-2xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-800 dark:bg-slate-900">
          <div className="flex items-center gap-3">
            <div className="rounded-xl bg-[#137fec]/10 p-3 text-[#137fec]">
              <Users className="h-6 w-6" />
            </div>
            <div>
              <h1 className="text-lg font-bold tracking-tight">Resident Management</h1>
              <p className="text-xs font-medium text-slate-500 dark:text-slate-400">Create and manage resident records like the Flutter admin flow.</p>
            </div>
          </div>
          <div className="flex gap-2">
            <button
              onClick={() => void loadResidents()}
              className="inline-flex items-center gap-2 rounded-xl border border-slate-200 px-3 py-2 text-sm font-bold text-slate-700 dark:border-slate-700 dark:text-slate-200"
            >
              <RefreshCw className="h-4 w-4" />
              Refresh
            </button>
            <button
              onClick={() => setCreateModalOpen(true)}
              className="inline-flex items-center gap-2 rounded-xl bg-[#137fec] px-3 py-2 text-sm font-bold text-white"
            >
              <Plus className="h-4 w-4" />
              Add Resident
            </button>
          </div>
        </div>

        <section className="mb-6 grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
          <MetricCard label="Residents" value={residents.length} />
          <MetricCard label="Active" value={activeCount} />
          <MetricCard label="Deactivated" value={deactivatedCount} />
        </section>

        <div className="mb-4 flex items-center gap-3">
          <div className="relative flex-1">
            <Search className="absolute left-4 top-1/2 h-5 w-5 -translate-y-1/2 text-slate-400" />
            <input
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder="Search resident management by name, unit, or email"
              className="w-full rounded-2xl border border-slate-200 bg-white py-3 pl-12 pr-4 text-sm dark:border-slate-800 dark:bg-slate-900"
            />
          </div>
        </div>

        <div className="mb-6 flex gap-2 overflow-x-auto pb-1 no-scrollbar">
          {FILTERS.map((item) => (
            <button
              key={item}
              onClick={() => setFilter(item)}
              className={`rounded-full px-4 py-2 text-sm font-bold ${filter === item ? "bg-[#137fec] text-white" : "border border-slate-200 bg-white text-slate-700 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-200"}`}
            >
              {item}
            </button>
          ))}
        </div>

        {isLoading ? (
          <Block text="Loading residents..." />
        ) : error ? (
          <ErrorBlock message={error} />
        ) : filteredResidents.length === 0 ? (
          <Block text="No resident management records match the current search/filter." />
        ) : (
          <div className="space-y-3 xl:grid xl:grid-cols-2 xl:gap-4 xl:space-y-0">
            {filteredResidents.map((resident) => (
              <motion.div
                key={resident.id}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-800 dark:bg-slate-900"
              >
                <div className="flex items-start justify-between gap-3">
                  <div className="flex items-center gap-3">
                    <img className="size-12 rounded-full bg-slate-100 object-cover" src={resident.avatarUrl ?? `https://api.dicebear.com/7.x/avataaars/svg?seed=${resident.email}`} alt={resident.fullName} />
                    <div>
                      <h3 className="text-sm font-bold">{resident.fullName}</h3>
                      <p className="text-xs text-slate-500 dark:text-slate-400">Unit {resident.unitNumber} · {resident.leaseStatus}</p>
                      <p className="text-xs text-slate-500 dark:text-slate-400">{resident.email}</p>
                    </div>
                  </div>
                  <span className={`rounded-full px-2 py-1 text-[10px] font-bold uppercase tracking-widest ${resident.status === "Active" ? "bg-emerald-100 text-emerald-600" : "bg-amber-100 text-amber-600"}`}>
                    {resident.status}
                  </span>
                </div>

                <div className="mt-4 flex gap-2">
                  <button
                    onClick={() => setSelectedResident(resident)}
                    className="inline-flex flex-1 items-center justify-center gap-2 rounded-xl border border-slate-200 px-3 py-2 text-sm font-bold text-slate-700 dark:border-slate-700 dark:text-slate-200"
                  >
                    <Eye className="h-4 w-4" />
                    View
                  </button>
                  {resident.status === "Deactivated" ? (
                    <button
                      onClick={() => void activateResident(resident)}
                      className="inline-flex flex-1 items-center justify-center gap-2 rounded-xl bg-emerald-600 px-3 py-2 text-sm font-bold text-white"
                    >
                      <UserRoundCheck className="h-4 w-4" />
                      Activate
                    </button>
                  ) : (
                    <button
                      onClick={() => void deactivateResident(resident)}
                      className="inline-flex flex-1 items-center justify-center gap-2 rounded-xl bg-red-50 px-3 py-2 text-sm font-bold text-red-600"
                    >
                      <Trash2 className="h-4 w-4" />
                      Deactivate
                    </button>
                  )}
                </div>
              </motion.div>
            ))}
          </div>
        )}
      </div>

      <AnimatePresence>
        {selectedResident && (
          <>
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={() => setSelectedResident(null)} className="fixed inset-0 z-[100] bg-black/60 backdrop-blur-sm" />
            <motion.div initial={{ opacity: 0, y: 40 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: 40 }} className="fixed inset-x-4 bottom-0 z-[110] mx-auto rounded-t-[32px] bg-white p-6 pb-10 shadow-2xl dark:bg-[#101922] sm:max-w-xl lg:inset-x-0 lg:top-1/2 lg:bottom-auto lg:w-full lg:max-w-xl lg:-translate-y-1/2 lg:rounded-[32px] lg:pb-6">
              <div className="mb-4 flex items-center justify-between">
                <h3 className="text-lg font-bold">Resident Details</h3>
                <button onClick={() => setSelectedResident(null)} className="rounded-full p-2 hover:bg-slate-100 dark:hover:bg-slate-800">
                  <X className="h-5 w-5 text-slate-400" />
                </button>
              </div>
              <div className="space-y-2 text-sm text-slate-600 dark:text-slate-300">
                <p><span className="font-bold text-slate-900 dark:text-slate-100">Name:</span> {selectedResident.fullName}</p>
                <p><span className="font-bold text-slate-900 dark:text-slate-100">Unit:</span> {selectedResident.unitNumber}</p>
                <p><span className="font-bold text-slate-900 dark:text-slate-100">Tower:</span> {selectedResident.tower}</p>
                <p><span className="font-bold text-slate-900 dark:text-slate-100">Email:</span> {selectedResident.email}</p>
                <p><span className="font-bold text-slate-900 dark:text-slate-100">Lease:</span> {selectedResident.leaseStatus}</p>
                <p><span className="font-bold text-slate-900 dark:text-slate-100">Status:</span> {selectedResident.status}</p>
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>

      <AnimatePresence>
        {createModalOpen && (
          <>
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={() => setCreateModalOpen(false)} className="fixed inset-0 z-[100] bg-black/60 backdrop-blur-sm" />
            <motion.div initial={{ opacity: 0, y: 40 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: 40 }} className="fixed inset-x-4 bottom-0 z-[110] mx-auto rounded-t-[32px] bg-white p-6 pb-10 shadow-2xl dark:bg-[#101922] sm:max-w-xl lg:inset-x-0 lg:top-1/2 lg:bottom-auto lg:w-full lg:max-w-xl lg:-translate-y-1/2 lg:rounded-[32px] lg:pb-6">
              <div className="mb-4 flex items-center justify-between">
                <h3 className="text-lg font-bold">Create Resident</h3>
                <button onClick={() => setCreateModalOpen(false)} className="rounded-full p-2 hover:bg-slate-100 dark:hover:bg-slate-800">
                  <X className="h-5 w-5 text-slate-400" />
                </button>
              </div>
              <div className="space-y-4">
                <input value={form.fullName} onChange={(event) => setForm((current) => ({ ...current, fullName: event.target.value }))} placeholder="Full name" className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
                <input value={form.unitNumber} onChange={(event) => setForm((current) => ({ ...current, unitNumber: event.target.value }))} placeholder="Unit number" className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
                <input value={form.tower} onChange={(event) => setForm((current) => ({ ...current, tower: event.target.value }))} placeholder="Tower" className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
                <input value={form.email} onChange={(event) => setForm((current) => ({ ...current, email: event.target.value }))} placeholder="Email" className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
              </div>
              <button disabled={isSubmitting} onClick={() => void createResident()} className="mt-6 w-full rounded-2xl bg-[#137fec] py-4 text-sm font-bold text-white disabled:opacity-50">
                {isSubmitting ? "Creating..." : "Create Resident"}
              </button>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </Layout>
  );

  async function loadResidents() {
    setIsLoading(true);
    setError(null);
    try {
      const data = await apiRequest<ResidentItem[]>(`${AUTH_API_BASE}/users/residents`);
      setResidents(data);
    } catch (loadError) {
      const message = loadError instanceof Error ? loadError.message : "Unable to load resident management.";
      setError(message);
      showToast(message, "error");
    } finally {
      setIsLoading(false);
    }
  }

  async function createResident() {
    if (!form.fullName.trim() || !form.unitNumber.trim() || !form.tower.trim() || !form.email.trim()) {
      showToast("Fill all resident fields before creating.", "error");
      return;
    }
    setIsSubmitting(true);
    try {
      await apiRequest<ResidentItem>(`${AUTH_API_BASE}/users/residents`, {
        method: "POST",
        body: JSON.stringify(form),
      });
      setCreateModalOpen(false);
      setForm({ fullName: "", unitNumber: "", tower: "Skyview Tower", email: "" });
      await loadResidents();
      showToast("Resident created successfully.", "success");
    } catch (submitError) {
      showToast(submitError instanceof Error ? submitError.message : "Unable to create resident.", "error");
    } finally {
      setIsSubmitting(false);
    }
  }

  async function deactivateResident(resident: ResidentItem) {
    try {
      await apiRequest<void>(`${AUTH_API_BASE}/users/residents/${resident.id}`, { method: "DELETE" });
      await loadResidents();
      showToast(`${resident.fullName} deactivated.`, "success");
    } catch (actionError) {
      showToast(actionError instanceof Error ? actionError.message : "Unable to deactivate resident.", "error");
    }
  }

  async function activateResident(resident: ResidentItem) {
    try {
      await apiRequest<void>(`${AUTH_API_BASE}/users/residents/${resident.id}/activate`, {
        method: "POST",
        body: JSON.stringify({}),
      });
      await loadResidents();
      showToast(`${resident.fullName} activated.`, "success");
    } catch (actionError) {
      showToast(actionError instanceof Error ? actionError.message : "Unable to activate resident.", "error");
    }
  }
}

function MetricCard({ label, value }: { label: string; value: number }) {
  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-800 dark:bg-slate-900">
      <p className="text-xs font-bold uppercase tracking-widest text-slate-400">{label}</p>
      <p className="mt-2 text-3xl font-extrabold">{value}</p>
    </div>
  );
}

function Block({ text }: { text: string }) {
  return <div className="rounded-2xl border border-dashed border-slate-300 bg-white p-6 text-center text-sm text-slate-500 dark:border-slate-700 dark:bg-slate-900">{text}</div>;
}

function ErrorBlock({ message }: { message: string }) {
  return <div className="rounded-2xl border border-rose-200 bg-rose-50 p-4 text-sm text-rose-700 dark:border-rose-900/40 dark:bg-rose-900/10 dark:text-rose-300">{message}</div>;
}
