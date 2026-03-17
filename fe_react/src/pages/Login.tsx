import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { Mail, Lock, Eye, EyeOff, HelpCircle, Globe, ArrowLeft } from "lucide-react";
import { useToast } from "../components/Toast";
import { AUTH_API_BASE, ApiError, apiRequest, saveSession, type SessionUser } from "../lib/api";

export default function Login() {
  const navigate = useNavigate();
  const { showToast } = useToast();
  const [role, setRole] = useState<"resident" | "admin" | "staff">("resident");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
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
      saveSession(user);
      showToast("Đăng nhập thành công.", "success");
      navigate(resolveRoute(user.role), { replace: true });
    } catch (error) {
      showToast(mapLoginError(error), "error");
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleGoogleLogin = async () => {
    showToast("Redirecting to Google...", "info");
    try {
      const response = await fetch("/api/auth/url");
      const { url } = await response.json();
      const authWindow = window.open(url, "oauth_popup", "width=600,height=700");
      if (!authWindow) {
        alert("Please allow popups for this site to connect your account.");
      }
    } catch (error) {
      console.error("OAuth error:", error);
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
    <div className="relative flex min-h-screen w-full flex-col overflow-x-hidden bg-[#f6f7f8] max-w-md mx-auto shadow-2xl font-['Manrope'] dark:bg-[#101922]">
      <div className="sticky top-0 z-10 flex items-center justify-between p-4 pb-2">
        <Link to="/" className="flex size-12 shrink-0 items-center text-slate-900 dark:text-slate-100">
          <ArrowLeft className="h-6 w-6" />
        </Link>
        <h2 className="flex-1 pr-12 text-center text-lg font-bold leading-tight tracking-[-0.015em] text-slate-900 dark:text-slate-100">
          Login
        </h2>
      </div>

      <div className="px-4 py-3">
        <div
          className="min-h-[200px] w-full overflow-hidden rounded-xl bg-[#137fec]/10 bg-cover bg-center bg-no-repeat"
          style={{
            backgroundImage:
              'url("https://lh3.googleusercontent.com/aida-public/AB6AXuAbnnPngkff7-HTTW2Z9S-4lSnQa2AzSBvURVLA2GEzheb9tMWO3xwtfriHrZE2Mq9w6W4RkMoz9gXdZ5CAJTGHJdcQejfFjrbejqUfxnQt9w2VZO4OP9P6kHEP48DzxaqIvNfr9ZBjLNIfFfEUsp_8EBQzhF5TTrqTU_75qbayXJ4tCCwyALiiRgVGoUa1vAKLwPQMt2o_JZfWdawr8GsF-cpP8ZKmLEI_Eu40JzKIEdxlArCbfep1r4C4vTfKg768K9NpVKa8GYM")',
          }}
        />
      </div>

      <div className="px-6 py-4">
        <h1 className="text-center text-3xl font-extrabold leading-tight tracking-tight text-slate-900 dark:text-slate-100">
          Welcome Back
        </h1>
        <p className="pt-2 text-center text-base font-normal leading-normal text-slate-600 dark:text-slate-400">
          Enter your credentials to access the management portal
        </p>
      </div>

      <div className="px-6 py-2">
        <div className="flex h-12 w-full items-center justify-center rounded-xl bg-slate-200 p-1 dark:bg-slate-800">
          {(["resident", "staff", "admin"] as const).map((item) => (
            <button
              key={item}
              onClick={() => setRole(item)}
              className={`h-full grow rounded-lg px-2 text-[13px] font-semibold leading-normal transition-all ${
                role === item
                  ? "bg-white text-[#137fec] shadow-sm dark:bg-slate-700"
                  : "text-slate-600 dark:text-slate-400"
              }`}
            >
              {item.charAt(0).toUpperCase() + item.slice(1)}
            </button>
          ))}
        </div>
      </div>

      <div className="flex flex-col gap-4 px-6 py-4">
        <div className="flex flex-col gap-1.5">
          <label className="ml-1 text-sm font-semibold text-slate-700 dark:text-slate-300">Email</label>
          <div className="relative flex items-center">
            <Mail className="absolute left-4 h-5 w-5 text-slate-400" />
            <input
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              className="w-full rounded-xl border border-slate-200 bg-white py-3 pl-12 pr-4 text-slate-900 outline-none focus:border-transparent focus:ring-2 focus:ring-[#137fec] dark:border-slate-800 dark:bg-slate-900 dark:text-slate-100"
              placeholder="name@apartment.com"
              type="email"
            />
          </div>
        </div>

        <div className="flex flex-col gap-1.5">
          <label className="ml-1 text-sm font-semibold text-slate-700 dark:text-slate-300">Password</label>
          <div className="relative flex items-center">
            <Lock className="absolute left-4 h-5 w-5 text-slate-400" />
            <input
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              onKeyDown={(event) => {
                if (event.key === "Enter") {
                  void handleLogin();
                }
              }}
              className="w-full rounded-xl border border-slate-200 bg-white py-3 pl-12 pr-12 text-slate-900 outline-none focus:border-transparent focus:ring-2 focus:ring-[#137fec] dark:border-slate-800 dark:bg-slate-900 dark:text-slate-100"
              placeholder="••••••••"
              type={showPassword ? "text" : "password"}
            />
            <button
              type="button"
              onClick={() => setShowPassword(!showPassword)}
              className="absolute right-4 cursor-pointer text-slate-400"
            >
              {showPassword ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
            </button>
          </div>
        </div>

        <div className="flex items-center justify-between px-1">
          <label className="group flex cursor-pointer items-center gap-2">
            <input
              className="h-4 w-4 rounded border-slate-300 bg-white text-[#137fec] focus:ring-[#137fec] dark:border-slate-700 dark:bg-slate-900"
              type="checkbox"
            />
            <span className="text-sm font-medium text-slate-600 transition-colors group-hover:text-[#137fec] dark:text-slate-400">
              Remember me
            </span>
          </label>
          <Link className="text-sm font-semibold text-[#137fec] hover:underline" to="/reset-password">
            Forgot password?
          </Link>
        </div>

        <button
          disabled={isSubmitting}
          onClick={() => void handleLogin()}
          className="mt-4 w-full rounded-xl bg-[#137fec] py-4 font-bold text-white shadow-lg shadow-[#137fec]/20 transition-all active:scale-[0.98] hover:bg-[#137fec]/90 disabled:opacity-60 disabled:active:scale-100"
        >
          {isSubmitting ? "Signing In..." : "Sign In"}
        </button>

        <div className="my-2 flex items-center gap-3">
          <div className="h-px flex-1 bg-slate-200 dark:bg-slate-800" />
          <span className="text-xs font-bold uppercase tracking-widest text-slate-400">or</span>
          <div className="h-px flex-1 bg-slate-200 dark:bg-slate-800" />
        </div>

        <button
          onClick={handleGoogleLogin}
          className="flex w-full items-center justify-center gap-3 rounded-xl border border-slate-200 bg-white py-4 font-bold text-slate-900 shadow-sm transition-all active:scale-[0.98] hover:bg-slate-50 dark:border-slate-800 dark:bg-slate-900 dark:text-slate-100 dark:hover:bg-slate-800"
        >
          <img
            src="https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg"
            className="h-5 w-5"
            alt="Google"
          />
          Sign In with Google
        </button>
      </div>

      <div className="mt-auto px-6 py-8 text-center">
        <p className="text-sm text-slate-500 dark:text-slate-500">
          Don&apos;t have an account?
          <a className="ml-1 font-bold text-[#137fec] hover:underline" href="#">
            Contact Management
          </a>
        </p>
      </div>

      <div className="flex justify-center gap-4 pb-8">
        <div className="flex cursor-pointer items-center gap-1 text-slate-400 transition-colors hover:text-[#137fec]">
          <HelpCircle className="h-4 w-4" />
          <span className="text-xs font-semibold">Help Center</span>
        </div>
        <div className="h-4 w-px self-center bg-slate-200 dark:bg-slate-800" />
        <div className="flex cursor-pointer items-center gap-1 text-slate-400 transition-colors hover:text-[#137fec]">
          <Globe className="h-4 w-4" />
          <span className="text-xs font-semibold">English</span>
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
  if (role === "admin") {
    return "/admin";
  }
  if (role === "staff") {
    return "/staff";
  }
  return "/resident";
}
