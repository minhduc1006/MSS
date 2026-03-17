import { useEffect, useMemo, useState } from "react";
import { AnimatePresence, motion } from "motion/react";
import { Eye, Plus, RefreshCw, Search, Trash2, UserCheck, UserRoundCheck, X } from "lucide-react";
import Layout from "../components/Layout";
import { useToast } from "../components/Toast";
import { AUTH_API_BASE, apiRequest, type StaffItem } from "../lib/api";

const STATUS_FILTERS = ["All", "On Duty", "Off Duty", "Deactivated"] as const;

export default function StaffList() {
  const { showToast } = useToast();
  const [staff, setStaff] = useState<StaffItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [query, setQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState<(typeof STATUS_FILTERS)[number]>("All");
  const [selectedStaff, setSelectedStaff] = useState<StaffItem | null>(null);
  const [editingStaff, setEditingStaff] = useState<StaffItem | null>(null);
  const [createModalOpen, setCreateModalOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [form, setForm] = useState({
    fullName: "",
    jobTitle: "",
    shift: "Day",
    email: "",
    phone: "",
    status: "On Duty",
  });

  useEffect(() => {
    void loadStaff();
  }, []);

  const filteredStaff = useMemo(() => {
    const normalized = query.trim().toLowerCase();
    return staff.filter((member) => {
      const matchesQuery =
        normalized.length === 0 ||
        member.fullName.toLowerCase().includes(normalized) ||
        member.role.toLowerCase().includes(normalized) ||
        member.email.toLowerCase().includes(normalized) ||
        member.phone.toLowerCase().includes(normalized);
      const matchesStatus = statusFilter === "All" || member.status === statusFilter;
      return matchesQuery && matchesStatus;
    });
  }, [query, staff, statusFilter]);

  const onDutyCount = staff.filter((member) => member.status.toLowerCase().includes("on duty")).length;
  const dayShiftCount = staff.filter((member) => member.shift.toLowerCase().includes("day")).length;

  return (
    <Layout title="Staff Directory" role="admin">
      <div className="p-4 lg:p-6">
        <div className="mb-6 flex items-center justify-between rounded-2xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-800 dark:bg-slate-900">
          <div className="flex items-center gap-3">
            <div className="rounded-xl bg-[#137fec]/10 p-3 text-[#137fec]">
              <UserCheck className="h-6 w-6" />
            </div>
            <div>
              <h1 className="text-lg font-bold tracking-tight">Staff Directory</h1>
              <p className="text-xs font-medium text-slate-500 dark:text-slate-400">Operations team management with create, update, activate, and delete.</p>
            </div>
          </div>
          <div className="flex gap-2">
            <button onClick={() => void loadStaff()} className="inline-flex items-center gap-2 rounded-xl border border-slate-200 px-3 py-2 text-sm font-bold text-slate-700 dark:border-slate-700 dark:text-slate-200">
              <RefreshCw className="h-4 w-4" />
              Refresh
            </button>
            <button onClick={() => { setEditingStaff(null); setCreateModalOpen(true); }} className="inline-flex items-center gap-2 rounded-xl bg-[#137fec] px-3 py-2 text-sm font-bold text-white">
              <Plus className="h-4 w-4" />
              Add Staff
            </button>
          </div>
        </div>

        <section className="mb-6 grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
          <MetricCard label="Staff" value={staff.length} />
          <MetricCard label="On Duty" value={onDutyCount} />
          <MetricCard label="Day Shift" value={dayShiftCount} />
        </section>

        <div className="mb-4">
          <div className="relative">
            <Search className="absolute left-4 top-1/2 h-5 w-5 -translate-y-1/2 text-slate-400" />
            <input
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder="Search by staff name, title, email, or phone"
              className="w-full rounded-2xl border border-slate-200 bg-white py-3 pl-12 pr-4 text-sm dark:border-slate-800 dark:bg-slate-900"
            />
          </div>
        </div>

        <div className="mb-6 flex gap-2 overflow-x-auto pb-1 no-scrollbar">
          {STATUS_FILTERS.map((item) => (
            <button
              key={item}
              onClick={() => setStatusFilter(item)}
              className={`rounded-full px-4 py-2 text-sm font-bold ${statusFilter === item ? "bg-[#137fec] text-white" : "border border-slate-200 bg-white text-slate-700 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-200"}`}
            >
              {item}
            </button>
          ))}
        </div>

        {isLoading ? (
          <Block text="Loading staff..." />
        ) : error ? (
          <ErrorBlock message={error} />
        ) : filteredStaff.length === 0 ? (
          <Block text="No staff match your filters." />
        ) : (
          <div className="space-y-3 xl:grid xl:grid-cols-2 xl:gap-4 xl:space-y-0">
            {filteredStaff.map((member) => (
              <motion.div key={member.id} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-800 dark:bg-slate-900">
                <div className="flex items-start justify-between gap-3">
                  <div className="flex items-center gap-3">
                    <img className="size-12 rounded-full bg-slate-100 object-cover" src={member.avatarUrl ?? `https://api.dicebear.com/7.x/avataaars/svg?seed=${member.email}`} alt={member.fullName} />
                    <div>
                      <h3 className="text-sm font-bold">{member.fullName}</h3>
                      <p className="text-xs text-slate-500 dark:text-slate-400">{member.role} · {member.shift} Shift</p>
                      <p className="text-xs text-slate-500 dark:text-slate-400">{member.email}</p>
                    </div>
                  </div>
                  <span className={`rounded-full px-2 py-1 text-[10px] font-bold uppercase tracking-widest ${member.status === "On Duty" ? "bg-emerald-100 text-emerald-600" : member.status === "Deactivated" ? "bg-amber-100 text-amber-600" : "bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-300"}`}>
                    {member.status}
                  </span>
                </div>

                <p className="mt-3 text-xs text-slate-500 dark:text-slate-400">{member.phone}</p>

                <div className="mt-4 grid grid-cols-2 gap-2">
                  <button onClick={() => setSelectedStaff(member)} className="inline-flex items-center justify-center gap-2 rounded-xl border border-slate-200 px-3 py-2 text-sm font-bold text-slate-700 dark:border-slate-700 dark:text-slate-200">
                    <Eye className="h-4 w-4" />
                    View
                  </button>
                  <button onClick={() => startEdit(member)} className="inline-flex items-center justify-center gap-2 rounded-xl bg-[#137fec]/10 px-3 py-2 text-sm font-bold text-[#137fec]">
                    <Plus className="h-4 w-4" />
                    Update
                  </button>
                  {member.status === "Deactivated" ? (
                    <button onClick={() => void activateStaff(member)} className="inline-flex items-center justify-center gap-2 rounded-xl bg-emerald-600 px-3 py-2 text-sm font-bold text-white">
                      <UserRoundCheck className="h-4 w-4" />
                      Activate
                    </button>
                  ) : (
                    <button onClick={() => void deactivateStaff(member)} className="inline-flex items-center justify-center gap-2 rounded-xl bg-red-50 px-3 py-2 text-sm font-bold text-red-600">
                      <Trash2 className="h-4 w-4" />
                      Delete
                    </button>
                  )}
                </div>
              </motion.div>
            ))}
          </div>
        )}
      </div>

      <AnimatePresence>
        {selectedStaff && (
          <>
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={() => setSelectedStaff(null)} className="fixed inset-0 z-[100] bg-black/60 backdrop-blur-sm" />
            <motion.div initial={{ opacity: 0, y: 40 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: 40 }} className="fixed inset-x-4 bottom-0 z-[110] mx-auto rounded-t-[32px] bg-white p-6 pb-10 shadow-2xl dark:bg-[#101922] sm:max-w-xl lg:inset-x-0 lg:top-1/2 lg:bottom-auto lg:w-full lg:max-w-xl lg:-translate-y-1/2 lg:rounded-[32px] lg:pb-6">
              <div className="mb-4 flex items-center justify-between">
                <h3 className="text-lg font-bold">Staff Details</h3>
                <button onClick={() => setSelectedStaff(null)} className="rounded-full p-2 hover:bg-slate-100 dark:hover:bg-slate-800">
                  <X className="h-5 w-5 text-slate-400" />
                </button>
              </div>
              <div className="space-y-2 text-sm text-slate-600 dark:text-slate-300">
                <p><span className="font-bold text-slate-900 dark:text-slate-100">Name:</span> {selectedStaff.fullName}</p>
                <p><span className="font-bold text-slate-900 dark:text-slate-100">Title:</span> {selectedStaff.role}</p>
                <p><span className="font-bold text-slate-900 dark:text-slate-100">Shift:</span> {selectedStaff.shift}</p>
                <p><span className="font-bold text-slate-900 dark:text-slate-100">Email:</span> {selectedStaff.email}</p>
                <p><span className="font-bold text-slate-900 dark:text-slate-100">Phone:</span> {selectedStaff.phone}</p>
                <p><span className="font-bold text-slate-900 dark:text-slate-100">Status:</span> {selectedStaff.status}</p>
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>

      <AnimatePresence>
        {createModalOpen && (
          <>
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={closeModal} className="fixed inset-0 z-[100] bg-black/60 backdrop-blur-sm" />
            <motion.div initial={{ opacity: 0, y: 40 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: 40 }} className="fixed inset-x-4 bottom-0 z-[110] mx-auto rounded-t-[32px] bg-white p-6 pb-10 shadow-2xl dark:bg-[#101922] sm:max-w-xl lg:inset-x-0 lg:top-1/2 lg:bottom-auto lg:w-full lg:max-w-xl lg:-translate-y-1/2 lg:rounded-[32px] lg:pb-6">
              <div className="mb-4 flex items-center justify-between">
                <h3 className="text-lg font-bold">{editingStaff ? "Edit Staff Member" : "Add Staff Member"}</h3>
                <button onClick={closeModal} className="rounded-full p-2 hover:bg-slate-100 dark:hover:bg-slate-800">
                  <X className="h-5 w-5 text-slate-400" />
                </button>
              </div>
              <div className="space-y-4">
                <input value={form.fullName} onChange={(event) => setForm((current) => ({ ...current, fullName: event.target.value }))} placeholder="Full name" className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
                <input value={form.jobTitle} onChange={(event) => setForm((current) => ({ ...current, jobTitle: event.target.value }))} placeholder="Job title" className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
                <div className="grid grid-cols-2 gap-3">
                  <select value={form.shift} onChange={(event) => setForm((current) => ({ ...current, shift: event.target.value }))} className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900">
                    <option>Day</option>
                    <option>Night</option>
                  </select>
                  <select value={form.status} onChange={(event) => setForm((current) => ({ ...current, status: event.target.value }))} className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900">
                    <option>On Duty</option>
                    <option>Off Duty</option>
                    <option>Deactivated</option>
                  </select>
                </div>
                <input value={form.email} onChange={(event) => setForm((current) => ({ ...current, email: event.target.value }))} placeholder="Email" className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
                <input value={form.phone} onChange={(event) => setForm((current) => ({ ...current, phone: event.target.value }))} placeholder="Phone" className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
              </div>
              <button disabled={isSubmitting} onClick={() => void saveStaff()} className="mt-6 w-full rounded-2xl bg-[#137fec] py-4 text-sm font-bold text-white disabled:opacity-50">
                {isSubmitting ? "Saving..." : editingStaff ? "Save Changes" : "Create Staff"}
              </button>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </Layout>
  );

  async function loadStaff() {
    setIsLoading(true);
    setError(null);
    try {
      const data = await apiRequest<StaffItem[]>(`${AUTH_API_BASE}/users/staff`);
      setStaff(data);
    } catch (loadError) {
      const message = loadError instanceof Error ? loadError.message : "Unable to load staff directory.";
      setError(message);
      showToast(message, "error");
    } finally {
      setIsLoading(false);
    }
  }

  function startEdit(member: StaffItem) {
    setEditingStaff(member);
    setForm({
      fullName: member.fullName,
      jobTitle: member.role,
      shift: member.shift,
      email: member.email,
      phone: member.phone,
      status: member.status,
    });
    setCreateModalOpen(true);
  }

  function closeModal() {
    setCreateModalOpen(false);
    setEditingStaff(null);
    setForm({
      fullName: "",
      jobTitle: "",
      shift: "Day",
      email: "",
      phone: "",
      status: "On Duty",
    });
  }

  async function saveStaff() {
    if (!form.fullName.trim() || !form.jobTitle.trim() || !form.email.trim() || !form.phone.trim()) {
      showToast("Fill all staff fields before saving.", "error");
      return;
    }
    setIsSubmitting(true);
    try {
      if (editingStaff) {
        await apiRequest<StaffItem>(`${AUTH_API_BASE}/users/staff/${editingStaff.id}`, {
          method: "PUT",
          body: JSON.stringify({
            fullName: form.fullName.trim(),
            jobTitle: form.jobTitle.trim(),
            shift: form.shift,
            email: form.email.trim(),
            phone: form.phone.trim(),
            status: form.status,
          }),
        });
      } else {
        await apiRequest<StaffItem>(`${AUTH_API_BASE}/users/staff`, {
          method: "POST",
          body: JSON.stringify({
            fullName: form.fullName.trim(),
            jobTitle: form.jobTitle.trim(),
            shift: form.shift,
            email: form.email.trim(),
            phone: form.phone.trim(),
          }),
        });
      }
      closeModal();
      await loadStaff();
      showToast(editingStaff ? "Staff member updated." : "Staff member created.", "success");
    } catch (submitError) {
      showToast(submitError instanceof Error ? submitError.message : "Unable to save staff member.", "error");
    } finally {
      setIsSubmitting(false);
    }
  }

  async function deactivateStaff(member: StaffItem) {
    try {
      await apiRequest<void>(`${AUTH_API_BASE}/users/staff/${member.id}`, { method: "DELETE" });
      await loadStaff();
      showToast(`${member.fullName} deactivated.`, "success");
    } catch (actionError) {
      showToast(actionError instanceof Error ? actionError.message : "Unable to deactivate staff member.", "error");
    }
  }

  async function activateStaff(member: StaffItem) {
    try {
      await apiRequest<void>(`${AUTH_API_BASE}/users/staff/${member.id}/activate`, {
        method: "POST",
        body: JSON.stringify({}),
      });
      await loadStaff();
      showToast(`${member.fullName} activated.`, "success");
    } catch (actionError) {
      showToast(actionError instanceof Error ? actionError.message : "Unable to activate staff member.", "error");
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
