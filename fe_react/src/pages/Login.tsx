import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { Mail, Lock, Eye, EyeOff, HelpCircle, Globe, ArrowLeft } from "lucide-react";
import { useToast } from "../components/Toast";
import { AUTH_API_BASE, apiRequest, saveSession, type SessionUser } from "../lib/api";

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
      showToast(error instanceof Error ? error.message : "Không thể đăng nhập.", "error");
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
      <div className="flex items-center p-4 pb-2 justify-between sticky top-0 z-10">
        <Link to="/" className="text-slate-900 dark:text-slate-100 flex size-12 shrink-0 items-center">
          <ArrowLeft className="w-6 h-6" />
        </Link>
        <h2 className="text-slate-900 dark:text-slate-100 text-lg font-bold leading-tight tracking-[-0.015em] flex-1 text-center pr-12">Login</h2>
      </div>

      <div className="px-4 py-3">
        <div
          className="w-full bg-center bg-no-repeat bg-cover flex flex-col justify-end overflow-hidden bg-[#137fec]/10 rounded-xl min-h-[200px]"
          style={{ backgroundImage: 'url("https://lh3.googleusercontent.com/aida-public/AB6AXuAbnnPngkff7-HTTW2Z9S-4lSnQa2AzSBvURVLA2GEzheb9tMWO3xwtfriHrZE2Mq9w6W4RkMoz9gXdZ5CAJTGHJdcQejfFjrbejqUfxnQt9w2VZO4OP9P6kHEP48DzxaqIvNfr9ZBjLNIfFfEUsp_8EBQzhF5TTrqTU_75qbayXJ4tCCwyALiiRgVGoUa1vAKLwPQMt2o_JZfWdawr8GsF-cpP8ZKmLEI_Eu40JzKIEdxlArCbfep1r4C4vTfKg768K9NpVKa8GYM")' }}
        />
      </div>

      <div className="px-6 py-4">
        <h1 className="text-slate-900 dark:text-slate-100 tracking-tight text-3xl font-extrabold leading-tight text-center">Welcome Back</h1>
        <p className="text-slate-600 dark:text-slate-400 text-base font-normal leading-normal pt-2 text-center">Enter your credentials to access the management portal</p>
      </div>

      <div className="px-6 py-2">
        <div className="flex h-12 w-full items-center justify-center rounded-xl bg-slate-200 dark:bg-slate-800 p-1">
          {(["resident", "staff", "admin"] as const).map((item) => (
            <button
              key={item}
              onClick={() => setRole(item)}
              className={`flex grow items-center justify-center overflow-hidden rounded-lg px-2 text-[13px] font-semibold leading-normal transition-all h-full ${role === item ? "bg-white dark:bg-slate-700 shadow-sm text-[#137fec]" : "text-slate-600 dark:text-slate-400"}`}
            >
              {item.charAt(0).toUpperCase() + item.slice(1)}
            </button>
          ))}
        </div>
      </div>

      <div className="px-6 py-4 flex flex-col gap-4">
        <div className="flex flex-col gap-1.5">
          <label className="text-sm font-semibold text-slate-700 dark:text-slate-300 ml-1">Email</label>
          <div className="relative flex items-center">
            <Mail className="absolute left-4 text-slate-400 w-5 h-5" />
            <input
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              className="w-full pl-12 pr-4 py-3 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-[#137fec] focus:border-transparent outline-none text-slate-900 dark:text-slate-100"
              placeholder="name@apartment.com"
              type="email"
            />
          </div>
        </div>

        <div className="flex flex-col gap-1.5">
          <label className="text-sm font-semibold text-slate-700 dark:text-slate-300 ml-1">Password</label>
          <div className="relative flex items-center">
            <Lock className="absolute left-4 text-slate-400 w-5 h-5" />
            <input
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              onKeyDown={(event) => {
                if (event.key === "Enter") {
                  void handleLogin();
                }
              }}
              className="w-full pl-12 pr-12 py-3 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-[#137fec] focus:border-transparent outline-none text-slate-900 dark:text-slate-100"
              placeholder="••••••••"
              type={showPassword ? "text" : "password"}
            />
            <button
              type="button"
              onClick={() => setShowPassword(!showPassword)}
              className="absolute right-4 text-slate-400 cursor-pointer"
            >
              {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
            </button>
          </div>
        </div>

        <div className="flex items-center justify-between px-1">
          <label className="flex items-center gap-2 cursor-pointer group">
            <input className="w-4 h-4 rounded border-slate-300 dark:border-slate-700 text-[#137fec] focus:ring-[#137fec] bg-white dark:bg-slate-900" type="checkbox" />
            <span className="text-sm text-slate-600 dark:text-slate-400 group-hover:text-[#137fec] transition-colors font-medium">Remember me</span>
          </label>
          <Link className="text-sm font-semibold text-[#137fec] hover:underline" to="/reset-password">
            Forgot password?
          </Link>
        </div>

        <button
          disabled={isSubmitting}
          onClick={() => void handleLogin()}
          className="w-full bg-[#137fec] hover:bg-[#137fec]/90 text-white font-bold py-4 rounded-xl shadow-lg shadow-[#137fec]/20 transition-all mt-4 active:scale-[0.98] disabled:opacity-60 disabled:active:scale-100"
        >
          {isSubmitting ? "Signing In..." : "Sign In"}
        </button>

        <div className="flex items-center gap-3 my-2">
          <div className="h-px flex-1 bg-slate-200 dark:bg-slate-800"></div>
          <span className="text-xs font-bold text-slate-400 uppercase tracking-widest">or</span>
          <div className="h-px flex-1 bg-slate-200 dark:bg-slate-800"></div>
        </div>

        <button
          onClick={handleGoogleLogin}
          className="w-full bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 hover:bg-slate-50 dark:hover:bg-slate-800 text-slate-900 dark:text-slate-100 font-bold py-4 rounded-xl shadow-sm transition-all active:scale-[0.98] flex items-center justify-center gap-3"
        >
          <img src="https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg" className="w-5 h-5" alt="Google" />
          Sign In with Google
        </button>
      </div>

      <div className="mt-auto px-6 py-8 text-center">
        <p className="text-slate-500 dark:text-slate-500 text-sm">
          Don&apos;t have an account?
          <a className="text-[#137fec] font-bold hover:underline ml-1" href="#">
            Contact Management
          </a>
        </p>
      </div>

      <div className="flex justify-center gap-4 pb-8">
        <div className="flex items-center gap-1 text-slate-400 hover:text-[#137fec] cursor-pointer transition-colors">
          <HelpCircle className="w-4 h-4" />
          <span className="text-xs font-semibold">Help Center</span>
        </div>
        <div className="w-px h-4 bg-slate-200 dark:bg-slate-800 self-center"></div>
        <div className="flex items-center gap-1 text-slate-400 hover:text-[#137fec] cursor-pointer transition-colors">
          <Globe className="w-4 h-4" />
          <span className="text-xs font-semibold">English</span>
        </div>
      </div>
    </div>
  );
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
