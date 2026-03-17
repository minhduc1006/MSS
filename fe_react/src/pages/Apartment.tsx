import { useEffect, useMemo, useState } from "react";
import { AnimatePresence, motion } from "motion/react";
import { Building2, Eye, Plus, RefreshCw, Search, Trash2, UserPlus, X } from "lucide-react";
import Layout from "../components/Layout";
import { useToast } from "../components/Toast";
import { BILLING_API_BASE, type ApartmentStats, type ApartmentUnitItem, apiRequest } from "../lib/api";

const FILTERS = ["All", "Occupied", "Vacant", "Assigned", "Deactivated"] as const;

const initialForm = {
  unitNumber: "",
  tower: "Skyview Tower",
  unitType: "Standard",
  occupancyStatus: "Vacant",
  residentName: "",
  balance: "0",
};

export default function Apartment() {
  const { showToast } = useToast();
  const [stats, setStats] = useState<ApartmentStats | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [query, setQuery] = useState("");
  const [filter, setFilter] = useState<(typeof FILTERS)[number]>("All");
  const [selectedUnit, setSelectedUnit] = useState<ApartmentUnitItem | null>(null);
  const [editingUnit, setEditingUnit] = useState<ApartmentUnitItem | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [form, setForm] = useState(initialForm);

  useEffect(() => {
    void loadApartments();
  }, []);

  const units = stats?.units ?? [];
  const filteredUnits = useMemo(() => {
    const normalized = query.trim().toLowerCase();
    return units.filter((unit) => {
      const matchesQuery =
        normalized.length === 0 ||
        unit.unitNumber.toLowerCase().includes(normalized) ||
        unit.tower.toLowerCase().includes(normalized) ||
        unit.unitType.toLowerCase().includes(normalized) ||
        (unit.residentName ?? "").toLowerCase().includes(normalized);
      const matchesFilter = filter === "All" || unit.occupancyStatus === filter;
      return matchesQuery && matchesFilter;
    });
  }, [filter, query, units]);

  const occupiedCount = units.filter((unit) => unit.occupancyStatus === "Occupied").length;
  const assignedCount = units.filter((unit) => unit.occupancyStatus === "Assigned").length;
  const occupancyRate = units.length === 0 ? 0 : Math.round((occupiedCount / units.length) * 100);

  return (
    <Layout title="Apartment Administration" role="admin">
      <div className="p-4 lg:p-6">
        <div className="mb-6 flex items-center justify-between rounded-2xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-800 dark:bg-slate-900">
          <div className="flex items-center gap-3">
            <div className="rounded-xl bg-blue-100 p-3 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400">
              <Building2 className="h-6 w-6" />
            </div>
            <div>
              <h2 className="text-lg font-bold tracking-tight">Apartment Administration</h2>
              <p className="text-xs font-medium text-slate-500 dark:text-slate-400">Create and manage apartment units like the Flutter admin screen.</p>
            </div>
          </div>
          <div className="flex gap-2">
            <button onClick={() => void loadApartments()} className="inline-flex items-center gap-2 rounded-xl border border-slate-200 px-3 py-2 text-sm font-bold text-slate-700 dark:border-slate-700 dark:text-slate-200">
              <RefreshCw className="h-4 w-4" />
              Refresh
            </button>
            <button onClick={() => openCreate()} className="inline-flex items-center gap-2 rounded-xl bg-[#137fec] px-3 py-2 text-sm font-bold text-white">
              <Plus className="h-4 w-4" />
              Create Unit
            </button>
          </div>
        </div>

        <section className="mb-6 grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
          <MetricCard label="Occupancy" value={`${occupancyRate}%`} note={`${occupiedCount}/${units.length} occupied`} />
          <MetricCard label="Assigned" value={`${assignedCount}`} note={`${units.length} total units`} />
          <MetricCard label="Vacant" value={`${units.filter((unit) => unit.occupancyStatus === "Vacant").length}`} note="Ready for assignment" />
        </section>

        <div className="mb-4">
          <div className="relative">
            <Search className="absolute left-4 top-1/2 h-5 w-5 -translate-y-1/2 text-slate-400" />
            <input
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder="Search apartment administration by unit, tower, type, or resident"
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
          <Block text="Loading apartment administration..." />
        ) : error ? (
          <ErrorBlock message={error} />
        ) : filteredUnits.length === 0 ? (
          <Block text="No apartment administration records match the current search/filter." />
        ) : (
          <div className="space-y-3 xl:grid xl:grid-cols-2 xl:gap-4 xl:space-y-0">
            {filteredUnits.map((unit) => (
              <motion.div key={unit.id} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-800 dark:bg-slate-900">
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <h3 className="text-lg font-bold">{unit.unitNumber}</h3>
                    <p className="text-sm text-slate-500 dark:text-slate-400">{unit.tower} · {unit.unitType}</p>
                    <p className="mt-1 text-sm text-slate-600 dark:text-slate-300">{unit.residentName ?? "Available"}</p>
                    <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">{unit.balance === 0 ? "No balance" : `Balance ${formatCurrency(unit.balance)}`}</p>
                  </div>
                  <span className={`rounded-full px-2 py-1 text-[10px] font-bold uppercase tracking-widest ${statusTone(unit.occupancyStatus)}`}>
                    {unit.occupancyStatus}
                  </span>
                </div>

                <div className="mt-4 flex flex-wrap gap-2">
                  <ActionButton icon={Eye} label="View" onClick={() => setSelectedUnit(unit)} />
                  <ActionButton icon={Plus} label="Update" onClick={() => openEdit(unit)} tone="primary" />
                  {unit.occupancyStatus === "Deactivated" ? (
                    <ActionButton icon={UserPlus} label="Activate" onClick={() => void updateStatus(unit, unit.residentName ? "Occupied" : "Vacant")} tone="success" />
                  ) : (
                    <>
                      <ActionButton icon={Trash2} label="Delete" onClick={() => void deactivateUnit(unit)} tone="danger" />
                      <ActionButton icon={UserPlus} label="Assign" onClick={() => openAssign(unit)} />
                    </>
                  )}
                </div>
              </motion.div>
            ))}
          </div>
        )}
      </div>

      <AnimatePresence>
        {selectedUnit && (
          <>
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={() => setSelectedUnit(null)} className="fixed inset-0 z-[100] bg-black/60 backdrop-blur-sm" />
            <motion.div initial={{ opacity: 0, y: 40 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: 40 }} className="fixed inset-x-4 bottom-0 z-[110] mx-auto rounded-t-[32px] bg-white p-6 pb-10 shadow-2xl dark:bg-[#101922] sm:max-w-xl lg:inset-x-0 lg:top-1/2 lg:bottom-auto lg:w-full lg:max-w-xl lg:-translate-y-1/2 lg:rounded-[32px] lg:pb-6">
              <div className="mb-4 flex items-center justify-between">
                <h3 className="text-lg font-bold">Unit Details</h3>
                <button onClick={() => setSelectedUnit(null)} className="rounded-full p-2 hover:bg-slate-100 dark:hover:bg-slate-800">
                  <X className="h-5 w-5 text-slate-400" />
                </button>
              </div>
              <div className="space-y-2 text-sm text-slate-600 dark:text-slate-300">
                <p><span className="font-bold text-slate-900 dark:text-slate-100">Unit:</span> {selectedUnit.unitNumber}</p>
                <p><span className="font-bold text-slate-900 dark:text-slate-100">Tower:</span> {selectedUnit.tower}</p>
                <p><span className="font-bold text-slate-900 dark:text-slate-100">Type:</span> {selectedUnit.unitType}</p>
                <p><span className="font-bold text-slate-900 dark:text-slate-100">Status:</span> {selectedUnit.occupancyStatus}</p>
                <p><span className="font-bold text-slate-900 dark:text-slate-100">Resident:</span> {selectedUnit.residentName ?? "Unassigned"}</p>
                <p><span className="font-bold text-slate-900 dark:text-slate-100">Balance:</span> {formatCurrency(selectedUnit.balance)}</p>
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>

      <AnimatePresence>
        {isModalOpen && (
          <>
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={closeModal} className="fixed inset-0 z-[100] bg-black/60 backdrop-blur-sm" />
            <motion.div initial={{ opacity: 0, y: 40 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: 40 }} className="fixed inset-x-4 bottom-0 z-[110] mx-auto rounded-t-[32px] bg-white p-6 pb-10 shadow-2xl dark:bg-[#101922] sm:max-w-xl lg:inset-x-0 lg:top-1/2 lg:bottom-auto lg:w-full lg:max-w-xl lg:-translate-y-1/2 lg:rounded-[32px] lg:pb-6">
              <div className="mb-4 flex items-center justify-between">
                <h3 className="text-lg font-bold">{editingUnit ? "Update Apartment Unit" : "Create Apartment Unit"}</h3>
                <button onClick={closeModal} className="rounded-full p-2 hover:bg-slate-100 dark:hover:bg-slate-800">
                  <X className="h-5 w-5 text-slate-400" />
                </button>
              </div>
              <div className="space-y-4">
                <input value={form.unitNumber} onChange={(event) => setForm((current) => ({ ...current, unitNumber: event.target.value }))} placeholder="Unit Number" disabled={Boolean(editingUnit)} className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm disabled:opacity-70 dark:border-slate-800 dark:bg-slate-900" />
                <div className="grid grid-cols-2 gap-3">
                  <input value={form.tower} onChange={(event) => setForm((current) => ({ ...current, tower: event.target.value }))} placeholder="Tower" className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
                  <input value={form.unitType} onChange={(event) => setForm((current) => ({ ...current, unitType: event.target.value }))} placeholder="Unit Type" className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
                </div>
                <div className="grid grid-cols-2 gap-3">
                  <select value={form.occupancyStatus} onChange={(event) => setForm((current) => ({ ...current, occupancyStatus: event.target.value }))} className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900">
                    <option>Vacant</option>
                    <option>Occupied</option>
                    <option>Assigned</option>
                    <option>Deactivated</option>
                  </select>
                  <input value={form.balance} onChange={(event) => setForm((current) => ({ ...current, balance: event.target.value }))} placeholder="Balance" type="number" className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
                </div>
                <input value={form.residentName} onChange={(event) => setForm((current) => ({ ...current, residentName: event.target.value }))} placeholder="Resident Name" className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
              </div>
              <button disabled={isSubmitting} onClick={() => void saveUnit()} className="mt-6 w-full rounded-2xl bg-[#137fec] py-4 text-sm font-bold text-white disabled:opacity-50">
                {isSubmitting ? "Saving..." : editingUnit ? "Save Changes" : "Create Unit"}
              </button>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </Layout>
  );

  async function loadApartments() {
    setIsLoading(true);
    setError(null);
    try {
      const data = await apiRequest<ApartmentStats>(`${BILLING_API_BASE}/apartments`);
      setStats(data);
    } catch (loadError) {
      const message = loadError instanceof Error ? loadError.message : "Unable to load apartment administration.";
      setError(message);
      showToast(message, "error");
    } finally {
      setIsLoading(false);
    }
  }

  function openCreate() {
    setEditingUnit(null);
    setForm(initialForm);
    setIsModalOpen(true);
  }

  function openEdit(unit: ApartmentUnitItem) {
    setEditingUnit(unit);
    setForm({
      unitNumber: unit.unitNumber,
      tower: unit.tower,
      unitType: unit.unitType,
      occupancyStatus: unit.occupancyStatus,
      residentName: unit.residentName ?? "",
      balance: String(unit.balance),
    });
    setIsModalOpen(true);
  }

  function openAssign(unit: ApartmentUnitItem) {
    openEdit(unit);
    setForm((current) => ({ ...current, occupancyStatus: "Assigned" }));
  }

  function closeModal() {
    setIsModalOpen(false);
    setEditingUnit(null);
    setForm(initialForm);
  }

  async function saveUnit() {
    if (!form.unitNumber.trim() || !form.tower.trim() || !form.unitType.trim()) {
      showToast("Fill unit number, tower, and unit type before saving.", "error");
      return;
    }
    setIsSubmitting(true);
    try {
      const payload = {
        unitNumber: form.unitNumber.trim(),
        tower: form.tower.trim(),
        unitType: form.unitType.trim(),
        occupancyStatus: form.occupancyStatus,
        residentName: form.residentName.trim() || null,
        balance: Number(form.balance || "0"),
      };
      if (editingUnit) {
        await apiRequest<ApartmentUnitItem>(`${BILLING_API_BASE}/apartments/${editingUnit.id}`, {
          method: "PUT",
          body: JSON.stringify(payload),
        });
      } else {
        await apiRequest<ApartmentUnitItem>(`${BILLING_API_BASE}/apartments`, {
          method: "POST",
          body: JSON.stringify(payload),
        });
      }
      closeModal();
      await loadApartments();
      showToast(editingUnit ? "Apartment unit updated." : "Apartment unit created.", "success");
    } catch (submitError) {
      showToast(submitError instanceof Error ? submitError.message : "Unable to save apartment unit.", "error");
    } finally {
      setIsSubmitting(false);
    }
  }

  async function deactivateUnit(unit: ApartmentUnitItem) {
    try {
      await apiRequest<ApartmentUnitItem>(`${BILLING_API_BASE}/apartments/${unit.id}`, { method: "DELETE" });
      await loadApartments();
      showToast(`Unit ${unit.unitNumber} deactivated.`, "success");
    } catch (actionError) {
      showToast(actionError instanceof Error ? actionError.message : "Unable to deactivate unit.", "error");
    }
  }

  async function updateStatus(unit: ApartmentUnitItem, status: string) {
    try {
      await apiRequest<ApartmentUnitItem>(`${BILLING_API_BASE}/apartments/${unit.id}/status`, {
        method: "POST",
        body: JSON.stringify({ status }),
      });
      await loadApartments();
      showToast(`Unit ${unit.unitNumber} activated.`, "success");
    } catch (actionError) {
      showToast(actionError instanceof Error ? actionError.message : "Unable to update unit status.", "error");
    }
  }
}

function MetricCard({ label, value, note }: { label: string; value: string; note: string }) {
  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-800 dark:bg-slate-900">
      <p className="text-xs font-bold uppercase tracking-widest text-slate-400">{label}</p>
      <p className="mt-2 text-3xl font-extrabold">{value}</p>
      <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">{note}</p>
    </div>
  );
}

function ActionButton({
  icon: Icon,
  label,
  onClick,
  tone,
}: {
  icon: typeof Eye;
  label: string;
  onClick: () => void;
  tone?: "primary" | "danger" | "success";
}) {
  const classes =
    tone === "primary"
      ? "bg-[#137fec]/10 text-[#137fec]"
      : tone === "danger"
        ? "bg-red-50 text-red-600"
        : tone === "success"
          ? "bg-emerald-600 text-white"
          : "border border-slate-200 text-slate-700 dark:border-slate-700 dark:text-slate-200";
  return (
    <button onClick={onClick} className={`inline-flex items-center gap-2 rounded-xl px-3 py-2 text-sm font-bold ${classes}`}>
      <Icon className="h-4 w-4" />
      {label}
    </button>
  );
}

function Block({ text }: { text: string }) {
  return <div className="rounded-2xl border border-dashed border-slate-300 bg-white p-6 text-center text-sm text-slate-500 dark:border-slate-700 dark:bg-slate-900">{text}</div>;
}

function ErrorBlock({ message }: { message: string }) {
  return <div className="rounded-2xl border border-rose-200 bg-rose-50 p-4 text-sm text-rose-700 dark:border-rose-900/40 dark:bg-rose-900/10 dark:text-rose-300">{message}</div>;
}

function statusTone(status: string) {
  if (status === "Occupied") return "bg-emerald-100 text-emerald-600";
  if (status === "Assigned") return "bg-blue-100 text-blue-600";
  if (status === "Vacant") return "bg-amber-100 text-amber-600";
  return "bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-300";
}

function formatCurrency(value: number) {
  return new Intl.NumberFormat("vi-VN", { style: "currency", currency: "VND", maximumFractionDigits: 0 }).format(value);
}
