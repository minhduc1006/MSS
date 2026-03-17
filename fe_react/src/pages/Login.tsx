import { useEffect, useState } from "react";
import { Eye, EyeOff, Globe, Lock, Mail, HelpCircle, Building2 } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { useToast } from "../components/Toast";
import { AUTH_API_BASE, ApiError, apiRequest, saveSession, type SessionUser } from "../lib/api";

export default function Login() {
  const navigate = useNavigate();
  const { showToast } = useToast();
  const [role, setRole] = useState<"resident" | "admin" | "staff">("resident");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [rememberMe, setRememberMe] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleLogin = async () => {
    if (!email.trim() || !password.trim()) {
      showToast("Nhập email và mật khẩu trước khi đăng nhập.", "error");
      return;
    }

    setIsSubmitting(true);
    try {
      const user = await apiRequest<SessionUser>(`${AUTH_API_BASE}/auth/login`, {
        method: "POST",
        body: JSON.stringify({
          email: email.trim(),
          password,
          role,
        }),
      });
      if (rememberMe) {
        saveSession(user);
      } else {
        saveSession(user);
      }
      navigate(resolveRoute(user.role), { replace: true });
    } catch (error) {
      showToast(mapLoginError(error), "error");
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleGoogleLogin = async () => {
    try {
      const response = await fetch("/api/auth/url");
      const { url } = await response.json();
      const authWindow = window.open(url, "oauth_popup", "width=600,height=700");
      if (!authWindow) {
        showToast("Please allow popups for Google sign-in.", "error");
      }
    } catch {
      showToast("Unable to start Google sign-in.", "error");
    }
  };

  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      if (event.data?.type === "OAUTH_AUTH_SUCCESS") {
        navigate(resolveRoute(role), { replace: true });
      }
    };
    window.addEventListener("message", handleMessage);
    return () => window.removeEventListener("message", handleMessage);
  }, [navigate, role]);

  return (
    <div className="min-h-screen bg-[#f3f6fb] px-4 py-3 font-['Manrope'] dark:bg-[#101922]">
      <div className="mx-auto w-full max-w-xl">
        <div className="flex justify-end py-1">
          <button className="rounded-full p-3 text-slate-500 transition-colors hover:bg-white hover:text-[#137fec] dark:hover:bg-slate-900">
            <Globe className="h-5 w-5" />
          </button>
        </div>

        <div className="relative overflow-hidden rounded-[28px]">
          <img
            src="https://lh3.googleusercontent.com/aida-public/AB6AXuAbnnPngkff7-HTTW2Z9S-4lSnQa2AzSBvURVLA2GEzheb9tMWO3xwtfriHrZE2Mq9w6W4RkMoz9gXdZ5CAJTGHJdcQejfFjrbejqUfxnQt9w2VZO4OP9P6kHEP48DzxaqIvNfr9ZBjLNIfFfEUsp_8EBQzhF5TTrqTU_75qbayXJ4tCCwyALiiRgVGoUa1vAKLwPQMt2o_JZfWdawr8GsF-cpP8ZKmLEI_Eu40JzKIEdxlArCbfep1r4C4vTfKg768K9NpVKa8GYM"
            alt="Skyline Heights"
            className="h-[220px] w-full object-cover"
          />
          <div className="absolute inset-0 bg-gradient-to-b from-[#0f7aec]/35 to-[#0b3b73]/70" />
          <div className="absolute inset-x-5 bottom-5 rounded-3xl bg-white/92 p-4 shadow-xl backdrop-blur dark:bg-slate-900/92">
            <div className="flex items-center gap-3">
              <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-[#137fec]/12 text-[#137fec]">
                <Building2 className="h-7 w-7" />
              </div>
              <div>
                <h1 className="text-lg font-bold text-slate-900 dark:text-slate-100">Skyline Heights</h1>
                <p className="text-sm text-slate-500 dark:text-slate-400">Contact management for account access support.</p>
              </div>
            </div>
          </div>
        </div>

        <div className="px-2 py-6 text-center">
          <h2 className="text-4xl font-extrabold tracking-tight text-slate-900 dark:text-slate-100">Welcome Back</h2>
          <p className="mt-3 text-base text-slate-500 dark:text-slate-400">Enter your credentials to access the management portal</p>
        </div>

        <div className="mb-5 flex h-12 items-center rounded-2xl bg-slate-200 p-1 dark:bg-slate-800">
          {(["resident", "staff", "admin"] as const).map((item) => (
            <button
              key={item}
              onClick={() => setRole(item)}
              className={`h-full flex-1 rounded-xl text-sm font-semibold transition-all ${
                role === item ? "bg-white text-[#137fec] shadow-sm dark:bg-slate-700" : "text-slate-600 dark:text-slate-400"
              }`}
            >
              {item === "resident" ? "Resident" : item === "staff" ? "Staff" : "Admin"}
            </button>
          ))}
        </div>

        <div className="space-y-4">
          <div>
            <label className="mb-2 block text-sm font-semibold text-slate-800 dark:text-slate-200">Email or Username</label>
            <div className="relative">
              <Mail className="absolute left-4 top-1/2 h-5 w-5 -translate-y-1/2 text-slate-400" />
              <input
                value={email}
                onChange={(event) => setEmail(event.target.value)}
                className="w-full rounded-2xl border border-slate-200 bg-white py-3 pl-12 pr-4 text-slate-900 outline-none focus:border-[#137fec] dark:border-slate-800 dark:bg-slate-900 dark:text-slate-100"
                placeholder="name@apartment.com"
                type="email"
              />
            </div>
          </div>

          <div>
            <label className="mb-2 block text-sm font-semibold text-slate-800 dark:text-slate-200">Password</label>
            <div className="relative">
              <Lock className="absolute left-4 top-1/2 h-5 w-5 -translate-y-1/2 text-slate-400" />
              <input
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                onKeyDown={(event) => {
                  if (event.key === "Enter") {
                    void handleLogin();
                  }
                }}
                className="w-full rounded-2xl border border-slate-200 bg-white py-3 pl-12 pr-12 text-slate-900 outline-none focus:border-[#137fec] dark:border-slate-800 dark:bg-slate-900 dark:text-slate-100"
                type={showPassword ? "text" : "password"}
              />
              <button type="button" onClick={() => setShowPassword((current) => !current)} className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400">
                {showPassword ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
              </button>
            </div>
          </div>

          <div className="flex items-center">
            <label className="flex items-center gap-2 text-sm text-slate-600 dark:text-slate-400">
              <input
                checked={rememberMe}
                onChange={(event) => setRememberMe(event.target.checked)}
                className="h-4 w-4 rounded border-slate-300 text-[#137fec] focus:ring-[#137fec]"
                type="checkbox"
              />
              Remember me
            </label>
            <button onClick={() => navigate("/reset-password")} className="ml-auto text-sm font-semibold text-[#137fec]">
              Forgot password?
            </button>
          </div>

          <button
            disabled={isSubmitting}
            onClick={() => void handleLogin()}
            className="mt-2 w-full rounded-2xl bg-[#137fec] py-4 text-base font-bold text-white shadow-lg shadow-blue-500/20 disabled:opacity-60"
          >
            {isSubmitting ? "Signing In..." : "Sign In"}
          </button>

          <div className="flex items-center gap-3 py-1">
            <div className="h-px flex-1 bg-slate-200 dark:bg-slate-800" />
            <span className="text-xs text-slate-400">or continue with</span>
            <div className="h-px flex-1 bg-slate-200 dark:bg-slate-800" />
          </div>

          <button
            onClick={() => void handleGoogleLogin()}
            className="flex w-full items-center justify-center gap-3 rounded-2xl border border-slate-200 bg-white py-3.5 font-semibold text-slate-900 dark:border-slate-800 dark:bg-slate-900 dark:text-slate-100"
          >
            <div className="flex h-7 w-7 items-center justify-center rounded-full border border-slate-200 bg-white font-extrabold text-[#4285F4]">
              G
            </div>
            Sign In with Google
          </button>
        </div>

        <div className="py-8 text-center text-sm text-slate-500 dark:text-slate-500">
          Don&apos;t have an account?
          <span className="ml-1 font-bold text-[#137fec]">Contact Management</span>
        </div>

        <div className="flex items-center justify-center gap-5 pb-6 text-sm text-slate-400">
          <div className="flex items-center gap-2">
            <HelpCircle className="h-4 w-4" />
            <span>Help Center</span>
          </div>
          <div className="h-4 w-px bg-slate-200 dark:bg-slate-800" />
          <div className="flex items-center gap-2">
            <Globe className="h-4 w-4" />
            <span>English</span>
          </div>
        </div>
      </div>
    </div>
  );
}

function mapLoginError(error: unknown) {
  const message = error instanceof Error ? error.message.toLowerCase().trim() : "";
  const statusCode = error instanceof ApiError ? error.statusCode : undefined;

  if (statusCode === 401 || message.includes("invalid credentials") || message.includes("unauthorized")) {
    return "Tài khoản hoặc mật khẩu không đúng.";
  }
  if (statusCode === 403 || message.includes("access denied") || message.includes("forbidden") || message.includes("permission")) {
    return "Tài khoản không có quyền truy cập vào khu vực này.";
  }
  if (message.includes("failed to fetch") || message.includes("network") || message.includes("timeout")) {
    return "Không thể kết nối tới hệ thống đăng nhập. Vui lòng thử lại.";
  }
  return "Không thể đăng nhập lúc này. Vui lòng thử lại.";
}

function resolveRoute(role: SessionUser["role"]) {
  if (role === "admin") return "/admin";
  if (role === "staff") return "/staff";
  return "/resident";
}
