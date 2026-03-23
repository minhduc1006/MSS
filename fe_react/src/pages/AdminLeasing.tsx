import { useEffect, useMemo, useState } from "react";
import Layout from "../components/Layout";
import { useToast } from "../components/Toast";
import {
  AUTH_API_BASE,
  BILLING_API_BASE,
  apiRequest,
  getSession,
  type ResidentItem,
  type TenancyItem,
  type TenancyOverview,
  type UtilityMeterItem,
  type UtilityMeterOverview,
} from "../lib/api";

const initialLeaseForm = { residentId: "", leaseType: "Long Term", startDate: "", endDate: "", monthlyRent: "", securityDeposit: "", notes: "" };
const initialMeterForm = { residentId: "", meterType: "Electricity", billingMonth: "", previousReading: "", currentReading: "", unitPrice: "", note: "" };

export default function AdminLeasing() {
  const { showToast } = useToast();
  const session = getSession();
  const [tenancies, setTenancies] = useState<TenancyOverview | null>(null);
  const [utilities, setUtilities] = useState<UtilityMeterOverview | null>(null);
  const [residents, setResidents] = useState<ResidentItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [modal, setModal] = useState<"lease" | "meter" | null>(null);
  const [saving, setSaving] = useState(false);
  const [leaseForm, setLeaseForm] = useState(initialLeaseForm);
  const [meterForm, setMeterForm] = useState(initialMeterForm);

  useEffect(() => {
    void loadPage();
  }, []);

  const leaseResident = useMemo(() => residents.find((item) => item.id === Number(leaseForm.residentId)), [leaseForm.residentId, residents]);
  const meterResident = useMemo(() => residents.find((item) => item.id === Number(meterForm.residentId)), [meterForm.residentId, residents]);
  const leases = tenancies?.leases ?? [];
  const meters = utilities?.meters ?? [];
  const expiringSoon = leases.filter((item) => item.status === "Active" && daysUntil(item.endDate) <= 30 && daysUntil(item.endDate) >= 0).length;

  return (
    <Layout title="Leasing & Utilities" role="admin">
      <div className="p-4 lg:p-6">
        <div className="mb-6 flex flex-col gap-4 rounded-3xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-800 dark:bg-slate-900 lg:flex-row lg:items-center lg:justify-between">
          <div className="max-w-2xl">
            <p className="text-xs font-bold uppercase tracking-[0.3em] text-[#137fec]">Revenue Control</p>
            <h1 className="mt-2 text-2xl font-extrabold tracking-tight text-slate-900 dark:text-slate-100">Leases and utility readings on the web admin</h1>
            <p className="mt-2 text-sm text-slate-500 dark:text-slate-400">This screen matches the Flutter admin flow: create lease contracts, submit meter readings, approve them, and generate invoices.</p>
          </div>
          <div className="flex flex-wrap gap-2">
            <button onClick={() => void loadPage()} className="rounded-2xl border border-slate-200 px-4 py-3 text-sm font-bold dark:border-slate-700">Refresh</button>
            <button onClick={() => setModal("meter")} className="rounded-2xl border border-[#137fec]/20 bg-[#137fec]/10 px-4 py-3 text-sm font-bold text-[#137fec]">Log Utility</button>
            <button onClick={() => setModal("lease")} className="rounded-2xl bg-[#137fec] px-4 py-3 text-sm font-bold text-white">Create Lease</button>
          </div>
        </div>

        <section className="mb-6 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <MetricCard label="Active leases" value={String(tenancies?.activeLeases ?? 0)} note={`${expiringSoon} expiring in 30 days`} />
          <MetricCard label="Recurring revenue" value={formatCurrency(tenancies?.monthlyRecurringRevenue ?? 0)} note="Monthly contracted rent" />
          <MetricCard label="Pending readings" value={String(utilities?.pendingSubmissions ?? 0)} note="Waiting for approval" />
          <MetricCard label="Utility billed" value={formatCurrency(utilities?.totalBilled ?? 0)} note="Total submitted usage amount" />
        </section>

        {loading ? <StateBlock text="Loading leasing administration..." /> : error ? <ErrorBlock text={error} /> : (
          <div className="space-y-6">
            <section className="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-800 dark:bg-slate-900">
              <div className="mb-4 flex items-center justify-between">
                <div>
                  <h2 className="text-lg font-bold">Tenancy Portfolio</h2>
                  <p className="text-sm text-slate-500 dark:text-slate-400">Control contract terms, rent, deposit, and lease status by unit.</p>
                </div>
                <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-bold uppercase tracking-widest text-slate-600 dark:bg-slate-800 dark:text-slate-300">{leases.length} leases</span>
              </div>
              <div className="grid gap-4 xl:grid-cols-2">
                {leases.map((lease) => (
                  <div key={lease.id} className="rounded-3xl border border-slate-200 bg-slate-50/70 p-4 dark:border-slate-800 dark:bg-slate-950/40">
                    <div className="flex items-start justify-between gap-3">
                      <div>
                        <h3 className="text-lg font-bold">Unit {lease.unitNumber}</h3>
                        <p className="text-sm text-slate-500 dark:text-slate-400">{lease.residentName} · {lease.leaseType}</p>
                        <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">{formatDate(lease.startDate)} to {formatDate(lease.endDate)}</p>
                      </div>
                      <StatusPill status={lease.status} group="lease" />
                    </div>
                    <div className="mt-4 grid gap-3 sm:grid-cols-2">
                      <InfoTile label="Monthly rent" value={formatCurrency(lease.monthlyRent)} />
                      <InfoTile label="Deposit" value={formatCurrency(lease.securityDeposit)} />
                    </div>
                    {lease.notes && <p className="mt-4 rounded-2xl bg-white px-3 py-2 text-sm text-slate-600 dark:bg-slate-900 dark:text-slate-300">{lease.notes}</p>}
                    <div className="mt-4 flex flex-wrap gap-2">
                      {lease.status !== "Active" && <SmallButton label="Activate" onClick={() => void updateLeaseStatus(lease, "Active")} tone="primary" />}
                      {lease.status !== "Ending Soon" && <SmallButton label="Mark ending" onClick={() => void updateLeaseStatus(lease, "Ending Soon")} />}
                      {lease.status !== "Expired" && <SmallButton label="Expire" onClick={() => void updateLeaseStatus(lease, "Expired")} />}
                      {lease.status !== "Terminated" && <SmallButton label="Terminate" onClick={() => void updateLeaseStatus(lease, "Terminated")} tone="danger" />}
                    </div>
                  </div>
                ))}
                {leases.length === 0 && <StateBlock text="No leases found." />}
              </div>
            </section>

            <section className="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-800 dark:bg-slate-900">
              <div className="mb-4 flex items-center justify-between">
                <div>
                  <h2 className="text-lg font-bold">Utility Submissions</h2>
                  <p className="text-sm text-slate-500 dark:text-slate-400">Approve readings and generate utility invoices without leaving the page.</p>
                </div>
                <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-bold uppercase tracking-widest text-slate-600 dark:bg-slate-800 dark:text-slate-300">{meters.length} readings</span>
              </div>
              <div className="grid gap-4 xl:grid-cols-2">
                {meters.map((meter) => (
                  <div key={meter.id} className="rounded-3xl border border-slate-200 bg-slate-50/70 p-4 dark:border-slate-800 dark:bg-slate-950/40">
                    <div className="flex items-start justify-between gap-3">
                      <div>
                        <h3 className="text-lg font-bold">{meter.meterType} · Unit {meter.unitNumber}</h3>
                        <p className="text-sm text-slate-500 dark:text-slate-400">{meter.residentName ?? "Unknown resident"} · {meter.billingMonth}</p>
                        <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">Submitted by {meter.submittedByName}</p>
                      </div>
                      <StatusPill status={meter.status} group="meter" />
                    </div>
                    <div className="mt-4 grid gap-3 sm:grid-cols-3">
                      <InfoTile label="Usage" value={`${meter.usageAmount}`} />
                      <InfoTile label="Price" value={formatCurrency(meter.unitPrice)} />
                      <InfoTile label="Total" value={formatCurrency(meter.totalAmount)} />
                    </div>
                    {meter.note && <p className="mt-4 rounded-2xl bg-white px-3 py-2 text-sm text-slate-600 dark:bg-slate-900 dark:text-slate-300">{meter.note}</p>}
                    <div className="mt-4 flex flex-wrap gap-2">
                      {meter.status !== "Approved" && meter.status !== "Invoiced" && <SmallButton label="Approve" onClick={() => void updateMeterStatus(meter.id, "Approved")} tone="primary" />}
                      {meter.status !== "Needs Review" && meter.status !== "Invoiced" && <SmallButton label="Needs review" onClick={() => void updateMeterStatus(meter.id, "Needs Review")} />}
                      {meter.status !== "Invoiced" && <SmallButton label="Generate invoice" onClick={() => void generateInvoice(meter)} tone="success" />}
                    </div>
                  </div>
                ))}
                {meters.length === 0 && <StateBlock text="No utility readings found." />}
              </div>
            </section>
          </div>
        )}

        {modal && <div onClick={closeModal} className="fixed inset-0 z-[100] bg-black/60 backdrop-blur-sm" />}
        {modal === "lease" && (
          <div className="fixed inset-x-4 bottom-0 z-[110] mx-auto rounded-t-[32px] bg-white p-6 pb-10 shadow-2xl dark:bg-[#101922] sm:max-w-xl lg:inset-x-0 lg:top-1/2 lg:bottom-auto lg:w-full lg:max-w-2xl lg:-translate-y-1/2 lg:rounded-[32px] lg:pb-6">
            <ModalHeader title="Create Lease Contract" subtitle="Create a lease linked to a resident and apartment." onClose={closeModal} />
            <div className="space-y-4">
              <select value={leaseForm.residentId} onChange={(e) => setLeaseForm((c) => ({ ...c, residentId: e.target.value }))} className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900">
                <option value="">Select resident</option>
                {residents.filter((item) => item.status !== "Deactivated").map((item) => <option key={item.id} value={item.id}>{item.fullName} - Unit {item.unitNumber}</option>)}
              </select>
              <div className="grid gap-3 sm:grid-cols-2">
                <select value={leaseForm.leaseType} onChange={(e) => setLeaseForm((c) => ({ ...c, leaseType: e.target.value }))} className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900"><option>Long Term</option><option>Short Term</option><option>Owner Occupied</option></select>
                <input value={leaseForm.monthlyRent} onChange={(e) => setLeaseForm((c) => ({ ...c, monthlyRent: e.target.value }))} type="number" min="0" step="100000" placeholder="Monthly rent" className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
              </div>
              <div className="grid gap-3 sm:grid-cols-2">
                <input value={leaseForm.startDate} onChange={(e) => setLeaseForm((c) => ({ ...c, startDate: e.target.value }))} type="date" className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
                <input value={leaseForm.endDate} onChange={(e) => setLeaseForm((c) => ({ ...c, endDate: e.target.value }))} type="date" className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
              </div>
              <input value={leaseForm.securityDeposit} onChange={(e) => setLeaseForm((c) => ({ ...c, securityDeposit: e.target.value }))} type="number" min="0" step="100000" placeholder="Security deposit" className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
              <textarea value={leaseForm.notes} onChange={(e) => setLeaseForm((c) => ({ ...c, notes: e.target.value }))} placeholder="Lease notes" className="min-h-24 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
              {leaseResident && <InfoPanel title={leaseResident.fullName} lines={[`Unit ${leaseResident.unitNumber} · ${leaseResident.tower}`, leaseResident.email]} />}
              <button disabled={saving} onClick={() => void createLease()} className="w-full rounded-2xl bg-[#137fec] py-4 text-sm font-bold text-white disabled:opacity-50">{saving ? "Creating lease..." : "Create lease"}</button>
            </div>
          </div>
        )}
        {modal === "meter" && (
          <div className="fixed inset-x-4 bottom-0 z-[110] mx-auto rounded-t-[32px] bg-white p-6 pb-10 shadow-2xl dark:bg-[#101922] sm:max-w-xl lg:inset-x-0 lg:top-1/2 lg:bottom-auto lg:w-full lg:max-w-2xl lg:-translate-y-1/2 lg:rounded-[32px] lg:pb-6">
            <ModalHeader title="Submit Utility Reading" subtitle="Log electricity or water usage for billing review." onClose={closeModal} />
            <div className="space-y-4">
              <select value={meterForm.residentId} onChange={(e) => setMeterForm((c) => ({ ...c, residentId: e.target.value }))} className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900">
                <option value="">Select resident</option>
                {residents.filter((item) => item.status !== "Deactivated").map((item) => <option key={item.id} value={item.id}>{item.fullName} - Unit {item.unitNumber}</option>)}
              </select>
              <div className="grid gap-3 sm:grid-cols-2">
                <select value={meterForm.meterType} onChange={(e) => setMeterForm((c) => ({ ...c, meterType: e.target.value }))} className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900"><option>Electricity</option><option>Water</option><option>Gas</option></select>
                <input value={meterForm.billingMonth} onChange={(e) => setMeterForm((c) => ({ ...c, billingMonth: e.target.value }))} type="month" className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
              </div>
              <div className="grid gap-3 sm:grid-cols-3">
                <input value={meterForm.previousReading} onChange={(e) => setMeterForm((c) => ({ ...c, previousReading: e.target.value }))} type="number" min="0" placeholder="Previous" className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
                <input value={meterForm.currentReading} onChange={(e) => setMeterForm((c) => ({ ...c, currentReading: e.target.value }))} type="number" min="0" placeholder="Current" className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
                <input value={meterForm.unitPrice} onChange={(e) => setMeterForm((c) => ({ ...c, unitPrice: e.target.value }))} type="number" min="0" step="100" placeholder="Unit price" className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
              </div>
              <textarea value={meterForm.note} onChange={(e) => setMeterForm((c) => ({ ...c, note: e.target.value }))} placeholder="Inspector note" className="min-h-24 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
              {meterResident && <InfoPanel title={meterResident.fullName} lines={[`Unit ${meterResident.unitNumber} - ${meterResident.tower}`, `Submitted by ${session?.fullName ?? "Admin Portal"}`]} />}
              <button disabled={saving} onClick={() => void createMeter()} className="w-full rounded-2xl bg-[#137fec] py-4 text-sm font-bold text-white disabled:opacity-50">{saving ? "Submitting reading..." : "Submit reading"}</button>
            </div>
          </div>
        )}
      </div>
    </Layout>
  );

  async function loadPage() {
    setLoading(true);
    setError(null);
    try {
      const [tenancyData, utilityData, residentData] = await Promise.all([
        apiRequest<TenancyOverview>(`${BILLING_API_BASE}/tenancies`),
        apiRequest<UtilityMeterOverview>(`${BILLING_API_BASE}/utilities/meters`),
        apiRequest<ResidentItem[]>(`${AUTH_API_BASE}/users/residents`),
      ]);
      setTenancies(tenancyData);
      setUtilities(utilityData);
      setResidents(residentData);
    } catch (loadError) {
      const message = loadError instanceof Error ? loadError.message : "Unable to load leasing administration.";
      setError(message);
      showToast(message, "error");
    } finally {
      setLoading(false);
    }
  }

  function closeModal() {
    setModal(null);
    setSaving(false);
    setLeaseForm(initialLeaseForm);
    setMeterForm(initialMeterForm);
  }

  async function createLease() {
    if (!leaseResident || !leaseForm.startDate || !leaseForm.endDate || !leaseForm.monthlyRent || !leaseForm.securityDeposit) {
      showToast("Select a resident and fill all lease details.", "error");
      return;
    }
    setSaving(true);
    try {
      await apiRequest<TenancyItem>(`${BILLING_API_BASE}/tenancies`, {
        method: "POST",
        body: JSON.stringify({
          residentId: leaseResident.id,
          residentName: leaseResident.fullName,
          residentEmail: leaseResident.email,
          unitNumber: leaseResident.unitNumber,
          tower: leaseResident.tower,
          leaseType: leaseForm.leaseType,
          startDate: leaseForm.startDate,
          endDate: leaseForm.endDate,
          monthlyRent: Number(leaseForm.monthlyRent),
          securityDeposit: Number(leaseForm.securityDeposit),
          status: "Active",
          notes: leaseForm.notes.trim() || null,
        }),
      });
      await loadPage();
      closeModal();
      showToast("Lease contract created.", "success");
    } catch (actionError) {
      showToast(actionError instanceof Error ? actionError.message : "Unable to create lease.", "error");
      setSaving(false);
    }
  }

  async function createMeter() {
    const previousReading = Number(meterForm.previousReading);
    const currentReading = Number(meterForm.currentReading);
    if (!meterResident || !meterForm.billingMonth || Number.isNaN(previousReading) || Number.isNaN(currentReading) || !meterForm.unitPrice) {
      showToast("Select a resident and complete all utility fields.", "error");
      return;
    }
    if (currentReading < previousReading) {
      showToast("Current reading must be greater than or equal to previous reading.", "error");
      return;
    }
    setSaving(true);
    try {
      await apiRequest<UtilityMeterItem>(`${BILLING_API_BASE}/utilities/meters`, {
        method: "POST",
        body: JSON.stringify({
          residentId: meterResident.id,
          residentName: meterResident.fullName,
          residentEmail: meterResident.email,
          unitNumber: meterResident.unitNumber,
          meterType: meterForm.meterType,
          billingMonth: meterForm.billingMonth,
          previousReading,
          currentReading,
          unitPrice: Number(meterForm.unitPrice),
          submittedByName: session?.fullName ?? "Admin Portal",
          status: "Submitted",
          note: meterForm.note.trim() || null,
        }),
      });
      await loadPage();
      closeModal();
      showToast("Utility reading submitted.", "success");
    } catch (actionError) {
      showToast(actionError instanceof Error ? actionError.message : "Unable to submit utility reading.", "error");
      setSaving(false);
    }
  }

  async function updateLeaseStatus(lease: TenancyItem, status: string) {
    try {
      await apiRequest<TenancyItem>(`${BILLING_API_BASE}/tenancies/${lease.id}/status`, {
        method: "POST",
        body: JSON.stringify({ status }),
      });
      await loadPage();
      showToast(`Lease ${lease.unitNumber} moved to ${status}.`, "success");
    } catch (actionError) {
      showToast(actionError instanceof Error ? actionError.message : "Unable to update lease status.", "error");
    }
  }

  async function updateMeterStatus(meterId: number, status: string) {
    try {
      await apiRequest<UtilityMeterItem>(`${BILLING_API_BASE}/utilities/meters/${meterId}/status`, {
        method: "POST",
        body: JSON.stringify({ status }),
      });
      await loadPage();
      showToast(`Utility reading moved to ${status}.`, "success");
    } catch (actionError) {
      showToast(actionError instanceof Error ? actionError.message : "Unable to update utility status.", "error");
    }
  }

  async function generateInvoice(meter: UtilityMeterItem) {
    try {
      const bill = await apiRequest<{ title: string }>(`${BILLING_API_BASE}/utilities/meters/${meter.id}/generate-invoice`, { method: "POST" });
      await loadPage();
      showToast(`Invoice generated: ${bill.title}.`, "success");
    } catch (actionError) {
      showToast(actionError instanceof Error ? actionError.message : "Unable to generate utility invoice.", "error");
    }
  }
}

function MetricCard({ label, value, note }: { label: string; value: string; note: string }) {
  return <div className="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-800 dark:bg-slate-900"><p className="text-xs font-bold uppercase tracking-widest text-slate-400">{label}</p><p className="mt-3 text-2xl font-extrabold">{value}</p><p className="mt-1 text-xs text-slate-500 dark:text-slate-400">{note}</p></div>;
}

function ModalHeader({ title, subtitle, onClose }: { title: string; subtitle: string; onClose: () => void }) {
  return <div className="mb-6 flex items-center justify-between gap-4"><div><h3 className="text-lg font-bold">{title}</h3><p className="text-sm text-slate-500 dark:text-slate-400">{subtitle}</p></div><button onClick={onClose} className="rounded-full p-2 hover:bg-slate-100 dark:hover:bg-slate-800">x</button></div>;
}

function InfoPanel({ title, lines }: { title: string; lines: string[] }) {
  return <div className="rounded-2xl border border-[#137fec]/15 bg-[#137fec]/5 p-4 text-sm text-slate-600 dark:text-slate-300"><p className="font-bold text-slate-900 dark:text-slate-100">{title}</p>{lines.map((line) => <p key={line} className="mt-1">{line}</p>)}</div>;
}

function InfoTile({ label, value }: { label: string; value: string }) {
  return <div className="rounded-2xl bg-white px-3 py-3 shadow-sm dark:bg-slate-900"><p className="text-[11px] font-bold uppercase tracking-widest text-slate-400">{label}</p><p className="mt-2 text-sm font-bold text-slate-900 dark:text-slate-100">{value}</p></div>;
}

function SmallButton({ label, onClick, tone }: { label: string; onClick: () => void; tone?: "primary" | "danger" | "success" }) {
  const classes = tone === "primary" ? "bg-[#137fec] text-white" : tone === "danger" ? "bg-red-50 text-red-600 dark:bg-red-900/10 dark:text-red-300" : tone === "success" ? "bg-emerald-600 text-white" : "border border-slate-200 text-slate-700 dark:border-slate-700 dark:text-slate-200";
  return <button onClick={onClick} className={`rounded-2xl px-4 py-2 text-sm font-bold ${classes}`}>{label}</button>;
}

function StatusPill({ status, group }: { status: string; group: "lease" | "meter" }) {
  const classes = group === "lease" ? status === "Active" ? "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/20 dark:text-emerald-300" : status === "Ending Soon" ? "bg-amber-100 text-amber-700 dark:bg-amber-900/20 dark:text-amber-300" : status === "Expired" ? "bg-slate-200 text-slate-700 dark:bg-slate-800 dark:text-slate-300" : "bg-rose-100 text-rose-700 dark:bg-rose-900/20 dark:text-rose-300" : status === "Approved" ? "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/20 dark:text-emerald-300" : status === "Invoiced" ? "bg-blue-100 text-blue-700 dark:bg-blue-900/20 dark:text-blue-300" : status === "Needs Review" ? "bg-rose-100 text-rose-700 dark:bg-rose-900/20 dark:text-rose-300" : "bg-amber-100 text-amber-700 dark:bg-amber-900/20 dark:text-amber-300";
  return <span className={`rounded-full px-3 py-1 text-[10px] font-bold uppercase tracking-widest ${classes}`}>{status}</span>;
}

function StateBlock({ text }: { text: string }) {
  return <div className="rounded-3xl border border-dashed border-slate-300 bg-white p-6 text-center text-sm text-slate-500 dark:border-slate-700 dark:bg-slate-900">{text}</div>;
}

function ErrorBlock({ text }: { text: string }) {
  return <div className="rounded-3xl border border-rose-200 bg-rose-50 p-4 text-sm text-rose-700 dark:border-rose-900/40 dark:bg-rose-900/10 dark:text-rose-300">{text}</div>;
}

function formatCurrency(value: number) {
  return new Intl.NumberFormat("vi-VN", { style: "currency", currency: "VND", maximumFractionDigits: 0 }).format(value);
}

function formatDate(value: string) {
  return new Date(value).toLocaleDateString("en-US", { month: "short", day: "2-digit", year: "numeric" });
}

function daysUntil(value: string) {
  return Math.floor((new Date(value).getTime() - Date.now()) / (1000 * 60 * 60 * 24));
}
