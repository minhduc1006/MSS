import { useEffect, useMemo, useState } from "react";
import Layout from "../components/Layout";
import ActionGrid from "../components/ActionGrid";
import { useToast } from "../components/Toast";
import { Receipt, Search, CheckCircle, Clock, AlertCircle, Mail, Plus, X } from "lucide-react";
import { motion, AnimatePresence } from "motion/react";
import {
  AUTH_API_BASE,
  BILLING_API_BASE,
  apiRequest,
  type BillingOverview,
  type CreateInvoiceResponse,
  type ResidentItem,
} from "../lib/api";

const initialForm = {
  residentId: "",
  title: "",
  category: "service",
  amount: "",
  dueDate: "",
  description: "",
};

export default function Billing() {
  const { showToast } = useToast();
  const [filter, setFilter] = useState("All");
  const [overview, setOverview] = useState<BillingOverview | null>(null);
  const [residents, setResidents] = useState<ResidentItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [form, setForm] = useState(initialForm);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [editSubmitting, setEditSubmitting] = useState(false);
  const [editInvoiceId, setEditInvoiceId] = useState<number | null>(null);
  const [editForm, setEditForm] = useState({
    residentId: "",
    residentName: "",
    residentEmail: "",
    unitNumber: "",
    title: "",
    category: "service",
    amount: "",
    dueDate: "",
    description: "",
  });

  useEffect(() => {
    void Promise.all([loadOverview(filter), loadResidents()]).finally(() => setIsLoading(false));
  }, []);

  useEffect(() => {
    void loadOverview(filter);
  }, [filter]);

  const handleAction = (action: string) => {
    if (action === "Create") {
      setIsCreateModalOpen(true);
      return;
    }
    showToast(`Billing action "${action}" is available for the next step.`, "info");
  };

  const selectedResident = useMemo(
    () => residents.find((resident) => resident.id === Number(form.residentId)),
    [form.residentId, residents],
  );

  const handleCreateInvoice = async () => {
    if (!selectedResident || !form.title.trim() || !form.amount.trim() || !form.dueDate) {
      showToast("Chọn resident và nhập đủ thông tin hóa đơn.", "error");
      return;
    }

    setIsSubmitting(true);
    try {
      const response = await apiRequest<CreateInvoiceResponse>(`${BILLING_API_BASE}/billing/invoices`, {
        method: "POST",
        body: JSON.stringify({
          residentId: selectedResident.id,
          residentName: selectedResident.fullName,
          residentEmail: selectedResident.email,
          unitNumber: selectedResident.unitNumber,
          title: form.title.trim(),
          category: form.category,
          amount: Number(form.amount),
          dueDate: form.dueDate,
          description: form.description.trim(),
        }),
      });
      await loadOverview(filter);
      setForm(initialForm);
      setIsCreateModalOpen(false);
      showToast(
        response.email.sent
          ? `Đã tạo hóa đơn và gửi email tới ${response.email.recipient}.`
          : `Đã tạo hóa đơn nhưng email chưa gửi được: ${response.email.message}`,
        response.email.sent ? "success" : "info",
      );
    } catch (error) {
      showToast(error instanceof Error ? error.message : "Không thể tạo hóa đơn.", "error");
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleSendInvoiceEmail = async (invoiceId: number) => {
    try {
      const response = await apiRequest<{ sent: boolean; message: string; recipient: string | null }>(
        `${BILLING_API_BASE}/billing/${invoiceId}/send-email`,
        { method: "POST" },
      );
      showToast(
        response.sent
          ? `Đã gửi lại email hóa đơn tới ${response.recipient}.`
          : response.message,
        response.sent ? "success" : "info",
      );
    } catch (error) {
      showToast(error instanceof Error ? error.message : "Không thể gửi lại email.", "error");
    }
  };

  const handleDeleteInvoice = async (invoiceId: number, status: string) => {
    if (status !== "Pending") {
      showToast("Chỉ có thể xóa hóa đơn ở trạng thái Pending.", "info");
      return;
    }
    const confirmed = window.confirm("Bạn có chắc muốn xóa hóa đơn này?");
    if (!confirmed) return;
    try {
      await apiRequest(`${BILLING_API_BASE}/billing/invoices/${invoiceId}`, { method: "DELETE" });
      await loadOverview(filter);
      showToast("Đã xóa hóa đơn Pending.", "success");
    } catch (error) {
      showToast(error instanceof Error ? error.message : "Không thể xóa hóa đơn.", "error");
    }
  };

  const invoices = overview?.invoices ?? [];
  const summary = overview?.summary;

  const openEdit = (invoice: {
    id: number;
    residentId: number;
    residentName: string | null;
    residentEmail: string | null;
    unitNumber: string;
    title: string;
    category: string;
    amount: number;
    dueDate: string;
    description: string | null;
  }) => {
    setEditInvoiceId(invoice.id);
    setEditForm({
      residentId: String(invoice.residentId ?? ""),
      residentName: invoice.residentName ?? "",
      residentEmail: invoice.residentEmail ?? "",
      unitNumber: invoice.unitNumber ?? "",
      title: invoice.title ?? "",
      category: invoice.category ?? "service",
      amount: String(invoice.amount ?? ""),
      dueDate: invoice.dueDate ?? "",
      description: invoice.description ?? "",
    });
    setIsEditModalOpen(true);
  };

  const handleUpdateInvoice = async () => {
    if (!editInvoiceId) {
      showToast("Thiếu mã hóa đơn để cập nhật.", "error");
      return;
    }
    if (!editForm.title.trim() || !editForm.amount.trim() || !editForm.dueDate || !editForm.unitNumber.trim()) {
      showToast("Điền đủ tiêu đề, số tiền, hạn thanh toán, và số căn hộ.", "error");
      return;
    }
    setEditSubmitting(true);
    try {
      await apiRequest(`${BILLING_API_BASE}/billing/invoices/${editInvoiceId}`, {
        method: "PUT",
        body: JSON.stringify({
          residentId: editForm.residentId ? Number(editForm.residentId) : undefined,
          residentName: editForm.residentName?.trim() || undefined,
          residentEmail: editForm.residentEmail?.trim() || undefined,
          unitNumber: editForm.unitNumber.trim(),
          title: editForm.title.trim(),
          category: editForm.category,
          amount: Number(editForm.amount),
          dueDate: editForm.dueDate,
          description: editForm.description?.trim() || undefined,
        }),
      });
      await loadOverview(filter);
      setIsEditModalOpen(false);
      setEditInvoiceId(null);
      showToast("Cập nhật hóa đơn thành công.", "success");
    } catch (error) {
      showToast(error instanceof Error ? error.message : "Không thể cập nhật hóa đơn.", "error");
    } finally {
      setEditSubmitting(false);
    }
  };
  return (
    <Layout title="Billing & Payments" role="admin">
      <div className="p-4 lg:p-6">
        <section className="mb-6 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
          <div className="flex min-w-[140px] flex-1 flex-col gap-1 rounded-xl p-4 bg-white dark:bg-slate-800 shadow-sm border border-[#137fec]/5">
            <p className="text-slate-500 dark:text-slate-400 text-xs font-semibold uppercase tracking-wider">Total Invoiced</p>
            <p className="text-2xl font-extrabold">{formatCurrency(summary?.totalInvoiced ?? 0)}</p>
            <div className="flex items-center gap-1">
              <span className="text-slate-500 text-xs font-bold">Live data</span>
            </div>
          </div>
          <div className="flex min-w-[140px] flex-1 flex-col gap-1 rounded-xl p-4 bg-white dark:bg-slate-800 shadow-sm border border-[#137fec]/5">
            <p className="text-slate-500 dark:text-slate-400 text-xs font-semibold uppercase tracking-wider">Pending</p>
            <p className="text-2xl font-extrabold">{formatCurrency(summary?.totalOutstanding ?? 0)}</p>
            <div className="flex items-center gap-1 text-amber-500">
              <p className="text-xs font-bold">{summary?.activeInvoices ?? 0} Active</p>
            </div>
          </div>
          <div className="flex min-w-[140px] flex-1 flex-col gap-1 rounded-xl border border-[#137fec]/5 bg-white p-4 shadow-sm dark:bg-slate-800">
            <p className="text-slate-500 dark:text-slate-400 text-xs font-semibold uppercase tracking-wider">Collection Ratio</p>
            <p className="text-2xl font-extrabold">
              {summary && summary.totalInvoiced > 0
                ? `${Math.round(((summary.totalInvoiced - summary.totalOutstanding) / summary.totalInvoiced) * 100)}%`
                : "0%"}
            </p>
            <div className="flex items-center gap-1 text-emerald-500">
              <p className="text-xs font-bold">Based on paid value</p>
            </div>
          </div>
          <div className="flex min-w-[140px] flex-1 flex-col gap-1 rounded-xl border border-[#137fec]/5 bg-white p-4 shadow-sm dark:bg-slate-800">
            <p className="text-slate-500 dark:text-slate-400 text-xs font-semibold uppercase tracking-wider">Settled Value</p>
            <p className="text-2xl font-extrabold">{formatCurrency((summary?.totalInvoiced ?? 0) - (summary?.totalOutstanding ?? 0))}</p>
            <div className="flex items-center gap-1">
              <span className="text-slate-500 text-xs font-bold">Collected so far</span>
            </div>
          </div>
        </section>

        <div className="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm overflow-hidden mb-4">
          <div className="px-4 py-3 border-b border-slate-100 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-800/50 flex items-center justify-between">
            <h3 className="text-xs font-bold uppercase tracking-widest text-slate-400">Billing Operations</h3>
            <button
              onClick={() => setIsCreateModalOpen(true)}
              className="inline-flex items-center gap-2 rounded-xl bg-[#137fec] px-3 py-2 text-xs font-bold text-white"
            >
              <Plus className="w-4 h-4" />
              Create Invoice
            </button>
          </div>
          <ActionGrid onAction={handleAction} visibleActions={["Create"]} />
        </div>

        <div className="mb-6 rounded-2xl border border-[#137fec]/10 bg-[#137fec]/5 px-4 py-3 text-xs font-medium text-slate-600 dark:text-slate-300">
          Mỗi hóa đơn mới sẽ tự động gửi email tới resident đã chọn. Nếu SMTP chưa cấu hình, hệ thống vẫn tạo invoice và trả về trạng thái gửi email.
        </div>

        <section>
          <div className="flex gap-2 mb-4 overflow-x-auto no-scrollbar items-center">
            {["All", "Paid", "Pending", "Overdue"].map((item) => (
              <button
                key={item}
                onClick={() => setFilter(item)}
                className={`px-4 py-1.5 rounded-full text-sm font-bold transition-all ${filter === item ? "bg-slate-900 dark:bg-slate-100 text-white dark:text-slate-900" : "bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-400"}`}
              >
                {item}
              </button>
            ))}
          </div>

          <div className="flex flex-col gap-1">
            <h3 className="text-sm font-bold text-slate-500 dark:text-slate-400 mb-2 px-1 uppercase tracking-wider">Recent Invoices</h3>
            {isLoading ? (
              <div className="rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 p-5 text-sm text-slate-500">
                Loading invoices...
              </div>
            ) : invoices.length === 0 ? (
              <div className="rounded-2xl border border-dashed border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-900 p-6 text-center text-sm text-slate-500">
                No invoices found for this filter.
              </div>
            ) : (
              invoices.map((invoice) => {
                const icon = invoice.status === "Paid" ? CheckCircle : invoice.status === "Pending" ? Clock : AlertCircle;
                const color =
                  invoice.status === "Paid"
                    ? "text-emerald-600 bg-emerald-100 dark:bg-emerald-900/30 dark:text-emerald-400"
                    : invoice.status === "Pending"
                      ? "text-amber-600 bg-amber-100 dark:bg-amber-900/30 dark:text-amber-400"
                      : "text-rose-600 bg-rose-100 dark:bg-rose-900/30 dark:text-rose-400";

                return (
                  <motion.div
                    key={invoice.id}
                    initial={{ opacity: 0, scale: 0.95 }}
                    animate={{ opacity: 1, scale: 1 }}
                    className="p-4 mb-3 bg-white dark:bg-slate-800 rounded-xl border border-[#137fec]/5 shadow-sm"
                  >
                    <div className="flex items-start justify-between gap-3">
                      <div className="flex items-center gap-3">
                        <div className={`w-10 h-10 rounded-full flex items-center justify-center ${color}`}>
                          {icon === CheckCircle ? <CheckCircle className="w-5 h-5" /> : icon === Clock ? <Clock className="w-5 h-5" /> : <AlertCircle className="w-5 h-5" />}
                        </div>
                        <div>
                          <p className="font-bold text-sm">Unit {invoice.unitNumber} - {invoice.residentName}</p>
                          <p className="text-xs text-slate-500">{invoice.title}</p>
                          <p className="text-[11px] text-slate-400">Due {formatDate(invoice.dueDate)}</p>
                        </div>
                      </div>
                      <div className="text-right">
                        <p className="font-bold text-sm">{formatCurrency(invoice.amount)}</p>
                        <span className={`inline-block px-2 py-0.5 rounded text-[10px] font-bold uppercase ${color}`}>
                          {invoice.status}
                        </span>
                      </div>
                    </div>
                    <div className="mt-4 flex items-center justify-between gap-3 rounded-xl bg-slate-50 dark:bg-slate-900/70 px-3 py-2">
                      <div className="flex items-center gap-2 min-w-0">
                        <Mail className="w-4 h-4 text-[#137fec] shrink-0" />
                        <span className="truncate text-xs font-medium text-slate-600 dark:text-slate-300">{invoice.residentEmail ?? "No email snapshot"}</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <button
                          onClick={() => openEdit(invoice as any)}
                          className="shrink-0 rounded-lg border border-slate-200 dark:border-slate-700 px-3 py-1.5 text-[11px] font-bold text-slate-700 dark:text-slate-200"
                        >
                          Edit
                        </button>
                        {invoice.status === "Pending" && (
                          <button
                            onClick={() => void handleDeleteInvoice(invoice.id, invoice.status)}
                            className="shrink-0 rounded-lg border border-rose-200 dark:border-rose-800 px-3 py-1.5 text-[11px] font-bold text-rose-600"
                          >
                            Delete
                          </button>
                        )}
                        <button
                          onClick={() => void handleSendInvoiceEmail(invoice.id)}
                          className="shrink-0 rounded-lg border border-slate-200 dark:border-slate-700 px-3 py-1.5 text-[11px] font-bold text-[#137fec]"
                        >
                          Resend Email
                        </button>
                      </div>
                    </div>
                  </motion.div>
                );
              })
            )}
          </div>
        </section>
      </div>

      <AnimatePresence>
        {isEditModalOpen && (
          <>
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setIsEditModalOpen(false)}
              className="fixed inset-0 z-[100] bg-black/60 backdrop-blur-sm"
            />
            <motion.div
              initial={{ opacity: 0, y: 40 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: 40 }}
              transition={{ type: "spring", damping: 25, stiffness: 200 }}
              className="fixed inset-x-4 bottom-0 z-[110] mx-auto rounded-t-[32px] bg-white p-6 pb-10 shadow-2xl dark:bg-[#101922] sm:max-w-xl lg:inset-x-0 lg:top-1/2 lg:bottom-auto lg:w-full lg:max-w-2xl lg:-translate-y-1/2 lg:rounded-[32px] lg:pb-6"
            >
              <div className="flex items-center justify-between mb-6">
                <div>
                  <h3 className="font-bold text-lg">Edit Invoice</h3>
                  <p className="text-xs text-slate-500 font-medium">Chỉnh sửa thông tin hóa đơn và lưu lại thay đổi.</p>
                </div>
                <button onClick={() => setIsEditModalOpen(false)} className="p-2 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-full transition-colors">
                  <X className="w-5 h-5 text-slate-400" />
                </button>
              </div>

              <div className="space-y-4">
                <input
                  value={editForm.title}
                  onChange={(e) => setEditForm((c) => ({ ...c, title: e.target.value }))}
                  className="w-full rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 px-4 py-3 text-sm"
                  placeholder="Invoice title"
                />

                <div className="grid grid-cols-2 gap-3">
                  <select
                    value={editForm.category}
                    onChange={(e) => setEditForm((c) => ({ ...c, category: e.target.value }))}
                    className="w-full rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 px-4 py-3 text-sm"
                  >
                    <option value="service">Service</option>
                    <option value="maintenance">Maintenance</option>
                    <option value="utility">Utility</option>
                    <option value="parking">Parking</option>
                  </select>
                  <input
                    value={editForm.amount}
                    onChange={(e) => setEditForm((c) => ({ ...c, amount: e.target.value }))}
                    className="w-full rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 px-4 py-3 text-sm"
                    placeholder="Amount"
                    type="number"
                    min="0"
                    step="1000"
                  />
                </div>

                <input
                  value={editForm.dueDate}
                  onChange={(e) => setEditForm((c) => ({ ...c, dueDate: e.target.value }))}
                  className="w-full rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 px-4 py-3 text-sm"
                  type="date"
                />

                <input
                  value={editForm.unitNumber}
                  onChange={(e) => setEditForm((c) => ({ ...c, unitNumber: e.target.value }))}
                  className="w-full rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 px-4 py-3 text-sm"
                  placeholder="Unit number"
                />

                <textarea
                  value={editForm.description}
                  onChange={(e) => setEditForm((c) => ({ ...c, description: e.target.value }))}
                  className="w-full min-h-24 rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 px-4 py-3 text-sm"
                  placeholder="Description"
                />
              </div>

              <button
                disabled={editSubmitting}
                onClick={() => void handleUpdateInvoice()}
                className="w-full mt-6 py-4 bg-slate-900 text-white rounded-2xl font-bold text-sm shadow-lg shadow-black/10 active:scale-[0.98] transition-all disabled:opacity-50 dark:bg-slate-100 dark:text-slate-900"
              >
                {editSubmitting ? "Saving..." : "Save Changes"}
              </button>
            </motion.div>
          </>
        )}
        {isCreateModalOpen && (
          <>
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setIsCreateModalOpen(false)}
              className="fixed inset-0 z-[100] bg-black/60 backdrop-blur-sm"
            />
            <motion.div
              initial={{ opacity: 0, y: 40 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: 40 }}
              transition={{ type: "spring", damping: 25, stiffness: 200 }}
              className="fixed inset-x-4 bottom-0 z-[110] mx-auto rounded-t-[32px] bg-white p-6 pb-10 shadow-2xl dark:bg-[#101922] sm:max-w-xl lg:inset-x-0 lg:top-1/2 lg:bottom-auto lg:w-full lg:max-w-2xl lg:-translate-y-1/2 lg:rounded-[32px] lg:pb-6"
            >
              <div className="flex items-center justify-between mb-6">
                <div>
                  <h3 className="font-bold text-lg">Create Invoice</h3>
                  <p className="text-xs text-slate-500 font-medium">Resident will receive the invoice by email automatically.</p>
                </div>
                <button onClick={() => setIsCreateModalOpen(false)} className="p-2 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-full transition-colors">
                  <X className="w-5 h-5 text-slate-400" />
                </button>
              </div>

              <div className="space-y-4">
                <select
                  value={form.residentId}
                  onChange={(event) => setForm((current) => ({ ...current, residentId: event.target.value }))}
                  className="w-full rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 px-4 py-3 text-sm"
                >
                  <option value="">Select resident</option>
                  {residents.map((resident) => (
                    <option key={resident.id} value={resident.id}>
                      {resident.fullName} - Unit {resident.unitNumber}
                    </option>
                  ))}
                </select>

                <input
                  value={form.title}
                  onChange={(event) => setForm((current) => ({ ...current, title: event.target.value }))}
                  className="w-full rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 px-4 py-3 text-sm"
                  placeholder="Invoice title"
                />

                <div className="grid grid-cols-2 gap-3">
                  <select
                    value={form.category}
                    onChange={(event) => setForm((current) => ({ ...current, category: event.target.value }))}
                    className="w-full rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 px-4 py-3 text-sm"
                  >
                    <option value="service">Service</option>
                    <option value="maintenance">Maintenance</option>
                    <option value="utility">Utility</option>
                    <option value="parking">Parking</option>
                  </select>
                  <input
                    value={form.amount}
                    onChange={(event) => setForm((current) => ({ ...current, amount: event.target.value }))}
                    className="w-full rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 px-4 py-3 text-sm"
                    placeholder="Amount"
                    type="number"
                    min="0"
                    step="1000"
                  />
                </div>

                <input
                  value={form.dueDate}
                  onChange={(event) => setForm((current) => ({ ...current, dueDate: event.target.value }))}
                  className="w-full rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 px-4 py-3 text-sm"
                  type="date"
                />

                <textarea
                  value={form.description}
                  onChange={(event) => setForm((current) => ({ ...current, description: event.target.value }))}
                  className="w-full min-h-24 rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 px-4 py-3 text-sm"
                  placeholder="Description"
                />

                {selectedResident && (
                  <div className="rounded-2xl bg-[#137fec]/5 border border-[#137fec]/10 p-4 text-xs text-slate-600 dark:text-slate-300">
                    <p className="font-bold text-slate-900 dark:text-slate-100 mb-1">{selectedResident.fullName}</p>
                    <p>Unit {selectedResident.unitNumber} • {selectedResident.email}</p>
                  </div>
                )}
              </div>

              <button
                disabled={isSubmitting}
                onClick={() => void handleCreateInvoice()}
                className="w-full mt-6 py-4 bg-[#137fec] text-white rounded-2xl font-bold text-sm shadow-lg shadow-blue-500/20 active:scale-[0.98] transition-all disabled:opacity-50"
              >
                {isSubmitting ? "Creating..." : "Create Invoice"}
              </button>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </Layout>
  );

  async function loadOverview(status: string) {
    const query = status === "All" ? "" : `?status=${encodeURIComponent(status)}`;
    const data = await apiRequest<BillingOverview>(`${BILLING_API_BASE}/billing/overview${query}`);
    setOverview(data);
  }

  async function loadResidents() {
    const data = await apiRequest<ResidentItem[]>(`${AUTH_API_BASE}/users/residents`);
    setResidents(data.filter((resident) => resident.status !== "Deactivated"));
  }
}

function formatCurrency(value: number) {
  return new Intl.NumberFormat("vi-VN", { style: "currency", currency: "VND", maximumFractionDigits: 0 }).format(value);
}

function formatDate(value: string) {
  return new Date(value).toLocaleDateString("en-US", { month: "short", day: "2-digit", year: "numeric" });
}
