import { useEffect, useState } from "react";
import { Bell, CreditCard, LoaderCircle, LogOut, Moon, Shield, Sun, User } from "lucide-react";
import Layout from "../components/Layout";
import { useToast } from "../components/Toast";
import { AUTH_API_BASE, apiRequest, clearSession, getSession, type AccountResponse } from "../lib/api";

export default function ResidentAccount() {
  const { showToast } = useToast();
  const session = getSession();
  const [isDarkMode, setIsDarkMode] = useState(() => document.documentElement.classList.contains("dark"));
  const [summary, setSummary] = useState<AccountResponse | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isPasswordModalOpen, setIsPasswordModalOpen] = useState(false);
  const [passwordForm, setPasswordForm] = useState({ currentPassword: "", newPassword: "" });
  const [isSavingPassword, setIsSavingPassword] = useState(false);

  useEffect(() => {
    if (session?.role === "resident") {
      void loadAccount();
    } else {
      setIsLoading(false);
      setError("Please sign in as a resident to view account details.");
    }
  }, [session?.id, session?.role]);

  const toggleDarkMode = () => {
    const next = !isDarkMode;
    setIsDarkMode(next);
    document.documentElement.classList.toggle("dark", next);
  };

  const handleLogout = () => {
    clearSession();
    window.location.href = "/login";
  };

  return (
    <Layout title="Account" role="resident">
      <div className="p-4">
        {isLoading ? (
          <Block text="Loading account..." />
        ) : error ? (
          <ErrorBlock message={error} />
        ) : summary ? (
          <>
            <div className="mb-6 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900">
              <div className="flex items-center gap-4">
                <div className="flex h-16 w-16 items-center justify-center overflow-hidden rounded-full bg-slate-100 dark:bg-slate-800">
                  <img src={`https://api.dicebear.com/7.x/avataaars/svg?seed=${summary.user.fullName}`} alt="Avatar" className="h-full w-full object-cover" />
                </div>
                <div className="min-w-0">
                  <h2 className="truncate text-xl font-extrabold">{summary.user.fullName}</h2>
                  <p className="text-sm text-slate-500 dark:text-slate-400">Resident - Unit {summary.user.unitNumber ?? "N/A"}</p>
                  <p className="text-xs text-slate-400">{summary.user.email}</p>
                </div>
              </div>

              <div className="mt-6 grid grid-cols-3 gap-3">
                <MetricCard label="Bills" value={summary.stats.billCount} />
                <MetricCard label="Guests" value={summary.stats.guestCount} />
                <MetricCard label="Issues" value={summary.stats.openIssueCount} />
              </div>
            </div>

            <div className="space-y-3">
              <MenuCard icon={User} title="Profile Details" subtitle={summary.user.email} />
              <MenuCard icon={Shield} title="Change Password" subtitle="Update your account password" onClick={() => setIsPasswordModalOpen(true)} />
              <MenuCard icon={CreditCard} title="Payment Preferences" subtitle="Managed through your bill checkout flow" />
              <MenuCard icon={Bell} title="Notifications" subtitle="Email and in-app alerts" />

              <button
                onClick={toggleDarkMode}
                className="flex w-full items-center justify-between rounded-xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-800 dark:bg-slate-900"
              >
                <div className="flex items-center gap-4">
                  <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-300">
                    {isDarkMode ? <Sun className="h-5 w-5" /> : <Moon className="h-5 w-5" />}
                  </div>
                  <div className="text-left">
                    <p className="text-sm font-bold">Dark Mode</p>
                    <p className="text-xs text-slate-500 dark:text-slate-400">Toggle app appearance</p>
                  </div>
                </div>
                <div className={`h-5 w-10 rounded-full p-1 ${isDarkMode ? "bg-[#137fec]" : "bg-slate-300"}`}>
                  <div className={`h-3 w-3 rounded-full bg-white transition-transform ${isDarkMode ? "translate-x-5" : "translate-x-0"}`} />
                </div>
              </button>
            </div>

            <button
              onClick={handleLogout}
              className="mt-8 flex w-full items-center justify-center gap-2 rounded-xl bg-red-50 py-4 text-sm font-bold text-red-600 dark:bg-red-900/10"
            >
              <LogOut className="h-5 w-5" />
              Sign Out
            </button>
          </>
        ) : null}
      </div>

      {isPasswordModalOpen && (
        <>
          <div className="fixed inset-0 z-[100] bg-black/60 backdrop-blur-sm" onClick={() => setIsPasswordModalOpen(false)} />
          <div className="fixed inset-x-4 bottom-0 z-[110] mx-auto rounded-t-[32px] bg-white p-6 pb-10 shadow-2xl dark:bg-[#101922] sm:max-w-xl lg:inset-x-0 lg:top-1/2 lg:bottom-auto lg:w-full lg:max-w-xl lg:-translate-y-1/2 lg:rounded-[32px] lg:pb-6">
            <h3 className="text-lg font-bold">Change Password</h3>
            <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">Use the same backend password flow as Flutter.</p>

            <div className="mt-4 space-y-4">
              <input
                type="password"
                value={passwordForm.currentPassword}
                onChange={(event) => setPasswordForm((current) => ({ ...current, currentPassword: event.target.value }))}
                placeholder="Current password"
                className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900"
              />
              <input
                type="password"
                value={passwordForm.newPassword}
                onChange={(event) => setPasswordForm((current) => ({ ...current, newPassword: event.target.value }))}
                placeholder="New password"
                className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900"
              />
            </div>

            <button
              disabled={isSavingPassword}
              onClick={() => void changePassword()}
              className="mt-6 flex w-full items-center justify-center gap-2 rounded-2xl bg-[#137fec] py-4 text-sm font-bold text-white disabled:opacity-50"
            >
              {isSavingPassword ? <LoaderCircle className="h-5 w-5 animate-spin" /> : "Change Password"}
            </button>
          </div>
        </>
      )}
    </Layout>
  );

  async function loadAccount() {
    if (!session) return;
    setIsLoading(true);
    setError(null);
    try {
      const data = await apiRequest<AccountResponse>(`${AUTH_API_BASE}/users/${session.id}/account`);
      setSummary(data);
    } catch (loadError) {
      const message = loadError instanceof Error ? loadError.message : "Unable to load account.";
      setError(message);
      showToast(message, "error");
    } finally {
      setIsLoading(false);
    }
  }

  async function changePassword() {
    if (!session) return;
    if (passwordForm.newPassword.trim().length < 8) {
      showToast("New password must have at least 8 characters.", "error");
      return;
    }

    setIsSavingPassword(true);
    try {
      await apiRequest<void>(`${AUTH_API_BASE}/users/${session.id}/change-password`, {
        method: "POST",
        body: JSON.stringify(passwordForm),
      });
      setIsPasswordModalOpen(false);
      setPasswordForm({ currentPassword: "", newPassword: "" });
      showToast("Password changed successfully.", "success");
    } catch (saveError) {
      showToast(saveError instanceof Error ? saveError.message : "Unable to change password.", "error");
    } finally {
      setIsSavingPassword(false);
    }
  }
}

function MenuCard({
  icon: Icon,
  title,
  subtitle,
  onClick,
}: {
  icon: typeof User;
  title: string;
  subtitle: string;
  onClick?: () => void;
}) {
  return (
    <button
      onClick={onClick}
      className="flex w-full items-center justify-between rounded-xl border border-slate-200 bg-white p-4 text-left shadow-sm dark:border-slate-800 dark:bg-slate-900"
    >
      <div className="flex items-center gap-4">
        <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-[#137fec]/10 text-[#137fec]">
          <Icon className="h-5 w-5" />
        </div>
        <div>
          <p className="text-sm font-bold">{title}</p>
          <p className="text-xs text-slate-500 dark:text-slate-400">{subtitle}</p>
        </div>
      </div>
    </button>
  );
}

function MetricCard({ label, value }: { label: string; value: number }) {
  return (
    <div className="rounded-xl bg-slate-50 p-3 text-center dark:bg-slate-800/70">
      <p className="text-lg font-extrabold">{value}</p>
      <p className="text-[10px] font-bold uppercase tracking-widest text-slate-400">{label}</p>
    </div>
  );
}

function Block({ text }: { text: string }) {
  return <div className="rounded-2xl border border-dashed border-slate-300 bg-white p-6 text-center text-sm text-slate-500 dark:border-slate-700 dark:bg-slate-900">{text}</div>;
}

function ErrorBlock({ message }: { message: string }) {
  return <div className="rounded-2xl border border-rose-200 bg-rose-50 p-4 text-sm text-rose-700 dark:border-rose-900/40 dark:bg-rose-900/10 dark:text-rose-300">{message}</div>;
}
