import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { ArrowLeft, LockKeyhole, Mail, ShieldCheck } from "lucide-react";
import { useToast } from "../components/Toast";
import { AUTH_API_BASE, apiRequest } from "../lib/api";

export default function ResetPassword() {
  const navigate = useNavigate();
  const { showToast } = useToast();
  const [email, setEmail] = useState("");
  const [otp, setOtp] = useState("");
  const [otpRequested, setOtpRequested] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleRequestOtp = async () => {
    if (!email.trim()) {
      showToast("Nhập email trước khi gửi OTP.", "error");
      return;
    }

    setIsSubmitting(true);
    try {
      await apiRequest<{ message: string }>(`${AUTH_API_BASE}/auth/reset-password/request-otp`, {
        method: "POST",
        body: JSON.stringify({ email: email.trim() }),
      });
      setOtpRequested(true);
      showToast("OTP đã được gửi về email người dùng.", "success");
    } catch (error) {
      showToast(error instanceof Error ? error.message : "Không thể gửi OTP.", "error");
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleVerifyOtp = async () => {
    if (!email.trim() || !otp.trim()) {
      showToast("Nhập email và OTP để xác nhận.", "error");
      return;
    }

    setIsSubmitting(true);
    try {
      const response = await apiRequest<{ resetToken: string; message: string }>(`${AUTH_API_BASE}/auth/reset-password/verify-otp`, {
        method: "POST",
        body: JSON.stringify({ email: email.trim(), otp: otp.trim() }),
      });
      showToast("OTP hợp lệ. Chuyển sang màn đặt mật khẩu mới.", "success");
      navigate(`/reset-password/new?email=${encodeURIComponent(email.trim())}&token=${encodeURIComponent(response.resetToken)}`);
    } catch (error) {
      showToast(error instanceof Error ? error.message : "OTP không hợp lệ.", "error");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="bg-[#f6f7f8] dark:bg-[#101922] text-slate-900 dark:text-slate-100 antialiased min-h-screen font-['Manrope']">
      <div className="relative flex min-h-screen w-full flex-col overflow-hidden max-w-[430px] mx-auto bg-[#f6f7f8] dark:bg-[#101922] border-x border-slate-200 dark:border-slate-800">
        <div className="flex items-center p-4 pb-2 justify-between sticky top-0 bg-[#f6f7f8]/80 dark:bg-[#101922]/80 backdrop-blur-md z-10">
          <Link to="/login" className="text-slate-900 dark:text-slate-100 flex size-12 shrink-0 items-center justify-start focus:outline-none">
            <ArrowLeft className="w-6 h-6" />
          </Link>
          <h2 className="text-slate-900 dark:text-slate-100 text-lg font-bold leading-tight tracking-[-0.015em] flex-1 text-center pr-12">Email Verification</h2>
        </div>

        <div className="flex-1 overflow-y-auto px-4 py-4 space-y-6">
          <div className="rounded-[28px] overflow-hidden border border-slate-200 dark:border-slate-800 shadow-sm bg-white dark:bg-slate-900">
            <div className="bg-[#137fec] px-8 py-8 text-white">
              <div className="flex items-center gap-4">
                <div className="size-16 rounded-2xl bg-white text-[#137fec] flex items-center justify-center shadow-sm">
                  <LockKeyhole className="w-8 h-8" />
                </div>
                <div>
                  <p className="text-4xl font-extrabold leading-tight">Security Verification</p>
                  <p className="mt-2 text-sm text-blue-100">OTP xác nhận email trước khi đặt lại mật khẩu</p>
                </div>
              </div>
            </div>

            <div className="px-8 py-10">
              <h1 className="text-[2rem] leading-tight font-extrabold text-slate-900 dark:text-slate-100">Password Reset Request</h1>
              <p className="mt-5 text-[1.05rem] leading-9 text-slate-600 dark:text-slate-400">
                Hệ thống sẽ gửi mã OTP về email người dùng. Sau khi xác thực đúng OTP, bạn sẽ được chuyển sang màn hình đặt mật khẩu mới.
              </p>

              <div className="mt-8 space-y-4">
                <div className="rounded-2xl border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-950 px-4 py-4">
                  <label className="text-xs font-bold tracking-[0.2em] uppercase text-slate-400 block mb-3">Email Address</label>
                  <div className="relative">
                    <Mail className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
                    <input
                      value={email}
                      onChange={(event) => setEmail(event.target.value)}
                      className="w-full rounded-xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 py-3 pl-12 pr-4 text-sm focus:ring-[#137fec] focus:border-[#137fec]"
                      placeholder="resident@example.com"
                      type="email"
                    />
                  </div>
                </div>

                {otpRequested && (
                  <div className="rounded-3xl border-2 border-dashed border-[#d7e5f7] bg-[#f8fbff] px-5 py-6 text-center">
                    <p className="text-xs font-extrabold tracking-[0.35em] uppercase text-slate-500 mb-5">Verification Code</p>
                    <input
                      value={otp}
                      onChange={(event) => setOtp(event.target.value.replace(/\D/g, "").slice(0, 6))}
                      className="w-full bg-transparent text-center text-5xl font-extrabold tracking-[0.65em] text-[#ff7a1a] outline-none"
                      placeholder="000000"
                      inputMode="numeric"
                    />
                    <p className="mt-4 text-sm text-slate-500">OTP hết hạn sau 15 phút</p>
                  </div>
                )}

                <div className="rounded-2xl bg-[#137fec]/5 border border-[#137fec]/10 p-4">
                  <div className="flex items-start gap-3">
                    <ShieldCheck className="w-5 h-5 text-[#137fec] mt-0.5" />
                    <p className="text-sm leading-6 text-slate-600 dark:text-slate-300">
                      Email OTP và giao diện app đều giữ tone màu hệ thống hiện tại để đồng bộ với trải nghiệm của người dùng.
                    </p>
                  </div>
                </div>
              </div>

              <div className="mt-8 space-y-3">
                {!otpRequested ? (
                  <button
                    onClick={() => void handleRequestOtp()}
                    disabled={isSubmitting}
                    className="w-full bg-[#137fec] hover:bg-[#137fec]/90 text-white font-bold py-4 rounded-xl transition-all shadow-lg shadow-[#137fec]/20 disabled:opacity-60"
                  >
                    {isSubmitting ? "Sending OTP..." : "Send OTP"}
                  </button>
                ) : (
                  <>
                    <button
                      onClick={() => void handleVerifyOtp()}
                      disabled={isSubmitting}
                      className="w-full bg-[#137fec] hover:bg-[#137fec]/90 text-white font-bold py-4 rounded-xl transition-all shadow-lg shadow-[#137fec]/20 disabled:opacity-60"
                    >
                      {isSubmitting ? "Verifying..." : "Verify OTP"}
                    </button>
                    <button
                      onClick={() => void handleRequestOtp()}
                      disabled={isSubmitting}
                      className="w-full border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-800 text-slate-700 dark:text-slate-200 font-bold py-4 rounded-xl"
                    >
                      Resend OTP
                    </button>
                  </>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
