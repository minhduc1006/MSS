import { useEffect, useMemo, useState } from "react";
import { ArrowUpRight, Bolt, Download, Home, LoaderCircle, ParkingCircle, RefreshCw } from "lucide-react";
import Layout from "../components/Layout";
import { useToast } from "../components/Toast";
import { BILLING_API_BASE, apiRequest, getSession, type BillItem, type PaymentSession } from "../lib/api";

export default function ResidentBills() {
  const { showToast } = useToast();
  const session = getSession();
  const [bills, setBills] = useState<BillItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isPayingId, setIsPayingId] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (session?.role === "resident") {
      void loadBills();
    } else {
      setIsLoading(false);
      setError("Please sign in as a resident to view bills.");
    }
  }, [session?.id, session?.role]);

  const pendingBills = useMemo(() => bills.filter((bill) => bill.status !== "Paid"), [bills]);
  const paidBills = useMemo(() => bills.filter((bill) => bill.status === "Paid"), [bills]);
  const utilityBills = useMemo(() => bills.filter(isUtilityBill), [bills]);
  const serviceBills = useMemo(() => bills.filter(isServiceBill), [bills]);
  const otherBills = useMemo(() => bills.filter((bill) => !isUtilityBill(bill) && !isServiceBill(bill)), [bills]);
  const outstandingAmount = pendingBills.reduce((sum, bill) => sum + bill.amount, 0);
  const lastPayment = [...paidBills].sort((left, right) => right.dueDate.localeCompare(left.dueDate))[0];

  return (
    <Layout title="Billing & Payments" role="resident">
      <div className="p-4">
        <div className="ui-hover-lift ui-hover-accent mb-6 flex items-center justify-between rounded-2xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-800 dark:bg-slate-900">
          <div>
            <h2 className="text-lg font-bold">Resident Bills</h2>
            <p className="text-xs font-medium text-slate-500 dark:text-slate-400">Synced with `billing-service` and PayOS checkout flow.</p>
          </div>
          <button
            onClick={() => void loadBills()}
            className="ui-hover-soft ui-hover-accent inline-flex items-center gap-2 rounded-xl border border-slate-200 px-3 py-2 text-sm font-bold text-slate-700 dark:border-slate-700 dark:text-slate-200"
          >
            <RefreshCw className="h-4 w-4" />
            Refresh
          </button>
        </div>

        <section className="mb-6 grid grid-cols-2 gap-4">
          <MetricCard label="Outstanding" value={formatCurrency(outstandingAmount)} note={`${pendingBills.length} active`} />
          <MetricCard label="Last Payment" value={lastPayment ? formatDate(lastPayment.dueDate) : "No payments yet"} note={lastPayment ? formatCurrency(lastPayment.amount) : "Waiting for first payment"} />
        </section>

        <section className="mb-6 grid grid-cols-2 gap-4">
          <MetricCard
            label="Service Fees"
            value={formatCurrency(serviceBills.filter((bill) => bill.status !== "Paid").reduce((sum, bill) => sum + bill.amount, 0))}
            note={`${serviceBills.length} records`}
          />
          <MetricCard
            label="Utility Bills"
            value={formatCurrency(utilityBills.filter((bill) => bill.status !== "Paid").reduce((sum, bill) => sum + bill.amount, 0))}
            note={`${utilityBills.length} records`}
          />
        </section>

        <div className="mb-6 flex gap-3">
          <button
            disabled={pendingBills.length === 0 || isPayingId !== null}
            onClick={() => void payBill(pendingBills[0])}
            className="ui-hover-soft flex-1 rounded-xl bg-[#137fec] px-4 py-3 text-sm font-bold text-white disabled:opacity-50"
          >
            Pay Now
          </button>
          <button
            onClick={() => void exportStatement()}
            className="ui-hover-soft ui-hover-accent inline-flex items-center gap-2 rounded-xl border border-slate-200 px-4 py-3 text-sm font-bold text-slate-700 dark:border-slate-700 dark:text-slate-200"
          >
            <Download className="h-4 w-4" />
            Statement
          </button>
        </div>

        <section>
          <h3 className="mb-3 text-sm font-bold uppercase tracking-widest text-slate-400">Utility Bills</h3>
          {isLoading ? (
            <Block text="Loading resident bills..." />
          ) : error ? (
            <ErrorBlock message={error} />
          ) : (
            <BillList bills={utilityBills} isPayingId={isPayingId} onPay={(bill) => void payBill(bill)} emptyText="No electricity or water bills right now." />
          )}
        </section>

        <section className="mt-6">
          <h3 className="mb-3 text-sm font-bold uppercase tracking-widest text-slate-400">Service Fees</h3>
          {isLoading ? (
            <Block text="Loading service fees..." />
          ) : error ? (
            <ErrorBlock message={error} />
          ) : (
            <BillList bills={serviceBills} isPayingId={isPayingId} onPay={(bill) => void payBill(bill)} emptyText="No service or parking fees right now." />
          )}
        </section>

        {otherBills.length > 0 && (
          <section className="mt-6">
            <h3 className="mb-3 text-sm font-bold uppercase tracking-widest text-slate-400">Other Charges</h3>
            <BillList bills={otherBills} isPayingId={isPayingId} onPay={(bill) => void payBill(bill)} emptyText="No other charges right now." />
          </section>
        )}
      </div>
    </Layout>
  );

  async function loadBills() {
    if (!session) return;
    setIsLoading(true);
    setError(null);
    try {
      const data = await apiRequest<BillItem[]>(`${BILLING_API_BASE}/billing/resident/${session.id}`);
      setBills(data);
    } catch (loadError) {
      const message = loadError instanceof Error ? loadError.message : "Unable to load resident bills.";
      setError(message);
      showToast(message, "error");
    } finally {
      setIsLoading(false);
    }
  }

  async function payBill(bill: BillItem) {
    if (!bill.id) return;
    setIsPayingId(bill.id);
    try {
      const data = await apiRequest<PaymentSession>(`${BILLING_API_BASE}/billing/${bill.id}/checkout`, {
        method: "POST",
        body: JSON.stringify({
          returnUrl: window.location.href,
          cancelUrl: window.location.href,
        }),
      });
      window.open(data.checkoutUrl, "_blank", "noopener,noreferrer");
      showToast("PayOS checkout opened in a new tab.", "success");
    } catch (payError) {
      showToast(payError instanceof Error ? payError.message : "Unable to open checkout.", "error");
    } finally {
      setIsPayingId(null);
    }
  }

  async function exportStatement() {
    if (bills.length === 0) {
      showToast("No bills available to export.", "info");
      return;
    }

    const rows = ["Title,Amount,Due Date,Status"];
    for (const bill of bills) {
      rows.push(`"${bill.title.replaceAll('"', '""')}",${bill.amount},${bill.dueDate},${bill.status}`);
    }
    const blob = new Blob([rows.join("\n")], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = "resident_statement.csv";
    link.click();
    URL.revokeObjectURL(url);
    showToast("Statement downloaded.", "success");
  }
}

function BillList({
  bills,
  isPayingId,
  onPay,
  emptyText,
}: {
  bills: BillItem[];
  isPayingId: number | null;
  onPay: (bill: BillItem) => void;
  emptyText: string;
}) {
  if (bills.length === 0) {
    return <Block text={emptyText} />;
  }

  return (
    <div className="space-y-3">
      {bills.map((bill) => (
        <div key={bill.id} className="ui-hover-lift ui-hover-accent rounded-2xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-800 dark:bg-slate-900">
          <div className="flex items-start gap-3">
            <div className={`flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl ${statusTone(bill.status)}`}>
              {bill.category === "parking" ? <ParkingCircle className="h-5 w-5" /> : isServiceBill(bill) ? <Home className="h-5 w-5" /> : <Bolt className="h-5 w-5" />}
            </div>
            <div className="min-w-0 flex-1">
              <div className="flex items-start justify-between gap-3">
                <div>
                  <h4 className="text-sm font-bold">{bill.title}</h4>
                  <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">{formatDate(bill.dueDate)}</p>
                  {bill.description && <p className="mt-2 text-xs text-slate-500 dark:text-slate-400">{bill.description}</p>}
                </div>
                <div className="text-right">
                  <p className="text-sm font-bold">{formatCurrency(bill.amount)}</p>
                  <span className="mt-2 inline-block rounded-full bg-slate-100 px-2 py-1 text-[10px] font-bold uppercase tracking-widest text-slate-600 dark:bg-slate-800 dark:text-slate-300">
                    {bill.status}
                  </span>
                </div>
              </div>

              {bill.status !== "Paid" && (
                <button
                  disabled={isPayingId === bill.id}
                  onClick={() => onPay(bill)}
                  className="ui-hover-soft mt-4 inline-flex items-center gap-2 rounded-xl bg-[#137fec]/10 px-4 py-2.5 text-sm font-bold text-[#137fec] disabled:opacity-50"
                >
                  {isPayingId === bill.id ? <LoaderCircle className="h-4 w-4 animate-spin" /> : <ArrowUpRight className="h-4 w-4" />}
                  Pay
                </button>
              )}
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}

function MetricCard({ label, value, note }: { label: string; value: string; note: string }) {
  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-800 dark:bg-slate-900">
      <p className="text-xs font-bold uppercase tracking-widest text-slate-400">{label}</p>
      <p className="mt-2 text-2xl font-extrabold">{value}</p>
      <p className="mt-1 text-xs font-medium text-slate-500 dark:text-slate-400">{note}</p>
    </div>
  );
}

function Block({ text }: { text: string }) {
  return <div className="rounded-2xl border border-dashed border-slate-300 bg-white p-6 text-center text-sm text-slate-500 dark:border-slate-700 dark:bg-slate-900">{text}</div>;
}

function ErrorBlock({ message }: { message: string }) {
  return <div className="rounded-2xl border border-rose-200 bg-rose-50 p-4 text-sm text-rose-700 dark:border-rose-900/40 dark:bg-rose-900/10 dark:text-rose-300">{message}</div>;
}

function statusTone(status: string) {
  if (status === "Paid") return "bg-emerald-100 text-emerald-600";
  if (status === "Pending") return "bg-amber-100 text-amber-600";
  return "bg-rose-100 text-rose-600";
}

function isUtilityBill(bill: BillItem) {
  return (bill.category ?? "").toLowerCase() === "utility";
}

function isServiceBill(bill: BillItem) {
  const category = (bill.category ?? "").toLowerCase();
  return category === "service" || category === "maintenance" || category === "parking";
}

function formatCurrency(value: number) {
  return new Intl.NumberFormat("vi-VN", { style: "currency", currency: "VND", maximumFractionDigits: 0 }).format(value);
}

function formatDate(value: string) {
  return new Date(value).toLocaleDateString("en-US", { month: "short", day: "2-digit", year: "numeric" });
}
