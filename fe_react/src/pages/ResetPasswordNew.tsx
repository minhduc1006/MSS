import { useMemo, useState } from "react";
import { Link, Navigate, useNavigate, useSearchParams } from "react-router-dom";
import { ArrowLeft, Eye, EyeOff, KeyRound } from "lucide-react";
import { useToast } from "../components/Toast";
import { AUTH_API_BASE, apiRequest } from "../lib/api";

export default function ResetPasswordNew() {
  const navigate = useNavigate();
  const { showToast } = useToast();
  const [searchParams] = useSearchParams();
  const email = useMemo(() => searchParams.get("email") ?? "", [searchParams]);
  const resetToken = useMemo(() => searchParams.get("token") ?? "", [searchParams]);
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  if (!email || !resetToken) {
    return <Navigate to="/reset-password" replace />;
  }

  const handleCompleteReset = async () => {
    if (newPassword.length < 8) {
      showToast("Mật khẩu mới phải có ít nhất 8 ký tự.", "error");
      return;
    }
    if (newPassword !== confirmPassword) {
      showToast("Mật khẩu xác nhận không khớp.", "error");
      return;
    }

    setIsSubmitting(true);
    try {
      await apiRequest<void>(`${AUTH_API_BASE}/auth/reset-password/complete`, {
        method: "POST",
        body: JSON.stringify({
          email,
          resetToken,
          newPassword,
        }),
      });
      showToast("Đổi mật khẩu thành công.", "success");
      navigate("/login", { replace: true });
    } catch (error) {
      showToast(error instanceof Error ? error.message : "Không thể đặt lại mật khẩu.", "error");
    } finally {
      setIsSubmitting(false);
    }
  };

  const passwordStrength = newPassword.length >= 12 ? "Strong" : newPassword.length >= 8 ? "Good" : "Weak";

  return (
    <div className="relative flex min-h-screen w-full flex-col overflow-x-hidden max-w-md mx-auto bg-[#f6f7f8] dark:bg-[#101922] shadow-2xl font-['Manrope']">
      <div className="flex items-center p-4 pb-2 justify-between sticky top-0 z-10 bg-[#f6f7f8]/80 dark:bg-[#101922]/80 backdrop-blur-md">
        <Link to="/reset-password" className="text-slate-900 dark:text-slate-100 flex size-12 shrink-0 items-center">
          <ArrowLeft className="w-6 h-6" />
        </Link>
        <h2 className="text-slate-900 dark:text-slate-100 text-lg font-bold leading-tight tracking-[-0.015em] flex-1 text-center pr-12">Security</h2>
      </div>

      <div className="px-4 py-6 space-y-6">
        <div className="size-14 rounded-2xl bg-[#137fec]/10 text-[#137fec] flex items-center justify-center">
          <KeyRound className="w-7 h-7" />
        </div>

        <div>
          <h1 className="text-slate-900 dark:text-slate-100 tracking-tight text-4xl font-extrabold leading-tight">Create New Password</h1>
          <p className="text-slate-600 dark:text-slate-400 text-base leading-8 pt-3">
            OTP đã được xác nhận cho <span className="font-semibold text-slate-900 dark:text-slate-100">{email}</span>. Nhập mật khẩu mới để hoàn tất.
          </p>
        </div>

        <div className="space-y-5">
          <div className="flex flex-col gap-2">
            <label className="text-sm font-semibold text-slate-700 dark:text-slate-300">New Password</label>
            <div className="relative flex items-center">
              <input
                value={newPassword}
                onChange={(event) => setNewPassword(event.target.value)}
                className="w-full px-4 pr-12 py-4 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-[#137fec] focus:border-transparent outline-none text-slate-900 dark:text-slate-100"
                placeholder="Enter new password"
                type={showNewPassword ? "text" : "password"}
              />
              <button type="button" onClick={() => setShowNewPassword(!showNewPassword)} className="absolute right-4 text-slate-400">
                {showNewPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
              </button>
            </div>
          </div>

          <div>
            <div className="flex items-center justify-between text-xs font-bold uppercase tracking-widest text-slate-400 mb-2">
              <span>Password Strength</span>
              <span className="text-[#137fec]">{passwordStrength}</span>
            </div>
            <div className="grid grid-cols-4 gap-2">
              {[0, 1, 2, 3].map((segment) => (
                <div
                  key={segment}
                  className={`h-2 rounded-full ${segment < Math.min(4, Math.ceil(newPassword.length / 3)) ? "bg-[#137fec]" : "bg-slate-200 dark:bg-slate-800"}`}
                />
              ))}
            </div>
          </div>

          <div className="flex flex-col gap-2">
            <label className="text-sm font-semibold text-slate-700 dark:text-slate-300">Confirm New Password</label>
            <div className="relative flex items-center">
              <input
                value={confirmPassword}
                onChange={(event) => setConfirmPassword(event.target.value)}
                className="w-full px-4 pr-12 py-4 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-[#137fec] focus:border-transparent outline-none text-slate-900 dark:text-slate-100"
                placeholder="Confirm new password"
                type={showConfirmPassword ? "text" : "password"}
              />
              <button type="button" onClick={() => setShowConfirmPassword(!showConfirmPassword)} className="absolute right-4 text-slate-400">
                {showConfirmPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
              </button>
            </div>
          </div>

          <div className="rounded-2xl bg-[#137fec]/5 border border-[#137fec]/10 p-4">
            <p className="text-sm font-bold text-slate-900 dark:text-slate-100 mb-2">Password Requirements:</p>
            <ul className="space-y-2 text-sm text-slate-600 dark:text-slate-300">
              <li>Minimum 8 characters</li>
              <li>Use a password different from the old one</li>
              <li>Store it securely after reset</li>
            </ul>
          </div>
        </div>
      </div>

      <div className="mt-auto px-4 pb-8">
        <button
          disabled={isSubmitting}
          onClick={() => void handleCompleteReset()}
          className="w-full bg-[#137fec] hover:bg-[#137fec]/90 text-white font-bold py-4 rounded-xl shadow-lg shadow-[#137fec]/20 transition-all disabled:opacity-60"
        >
          {isSubmitting ? "Updating..." : "Update Password"}
        </button>
        <button
          onClick={() => navigate("/login")}
          className="w-full mt-4 text-center text-slate-500 font-semibold"
        >
          Cancel and return to login
        </button>
      </div>
    </div>
  );
}
