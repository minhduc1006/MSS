import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import {
  ArrowRight,
  Building2,
  CheckCheck,
  ClipboardList,
  CreditCard,
  Database,
  Download,
  ShieldCheck,
  Sparkles,
} from "lucide-react";
import {
  apiRequest,
  ApartmentStats,
  ApartmentUnitItem,
  BILLING_API_BASE,
  FACILITY_API_BASE,
  FacilitiesResponse,
} from "../lib/api";

type LandingState = {
  units: ApartmentUnitItem[];
  occupiedUnits: number;
  totalUnits: number;
  facilities: FacilitiesResponse["facilities"];
};

const heroImage =
  "https://images.unsplash.com/photo-1460317442991-0ec209397118?auto=format&fit=crop&w=1400&q=80";
const androidDownloadPath = "/downloads/android-apk";

export default function Landing() {
  const [state, setState] = useState<LandingState>({
    units: [],
    occupiedUnits: 0,
    totalUnits: 0,
    facilities: [],
  });
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;

    Promise.all([
      apiRequest<ApartmentStats>(`${BILLING_API_BASE}/apartments`),
      apiRequest<FacilitiesResponse>(`${FACILITY_API_BASE}/facilities`),
    ])
      .then(([apartments, facilities]) => {
        if (cancelled) return;
        setState({
          units: apartments.units,
          occupiedUnits: apartments.occupiedUnits,
          totalUnits: apartments.totalUnits,
          facilities: facilities.facilities,
        });
      })
      .catch((reason) => {
        if (cancelled) return;
        setError(reason instanceof Error ? reason.message : String(reason));
      });

    return () => {
      cancelled = true;
    };
  }, []);

  const availableUnits = useMemo(
    () =>
      state.units.filter(
        (unit) =>
          !["occupied", "deactivated"].includes(
            unit.occupancyStatus.toLowerCase(),
          ),
      ),
    [state.units],
  );

  const operationalFacilities = useMemo(
    () =>
      state.facilities.filter((item) =>
        item.status.toLowerCase().includes("operational"),
      ),
    [state.facilities],
  );

  const occupancyRate =
    state.totalUnits === 0
      ? "0%"
      : `${Math.round((state.occupiedUnits / state.totalUnits) * 100)}%`;

  const metricItems = [
    {
      value: state.totalUnits > 0 ? `${state.totalUnits}+` : "500+",
      label: "Managed units",
    },
    {
      value: occupancyRate,
      label: "Occupancy rate",
    },
    {
      value:
        operationalFacilities.length > 0
          ? `${operationalFacilities.length}/${state.facilities.length || operationalFacilities.length}`
          : "24/7",
      label:
        operationalFacilities.length > 0
          ? "Facilities online"
          : "Service coverage",
    },
  ];

  const standards = [
    {
      icon: Database,
      title: "Resident data foundation",
      desc:
        "Apartment profiles, resident records, tenancy status, and internal references stay organized in one operational source of truth.",
      tone: "bg-white text-slate-900",
      accent: "bg-[#f7cbb8]",
    },
    {
      icon: CreditCard,
      title: "Financial control center",
      desc:
        "Track balances, service fees, utility invoices, and payment follow-up in the same billing workflow.",
      tone: "bg-[#0d5be1] text-white",
      accent: "bg-[#89a7f5]",
    },
    {
      icon: ClipboardList,
      title: "Facility and service coordination",
      desc:
        "Handle amenity booking, resident service requests, and day-to-day operational scheduling with clear ownership.",
      tone: "bg-white text-slate-900",
      accent: "bg-[#d5def0]",
    },
    {
      icon: ShieldCheck,
      title: "Operational oversight",
      desc:
        "Review package desk, complaint handling, staff rosters, and service follow-up from one management workspace.",
      tone: "bg-white text-slate-900",
      accent: "bg-[#a8b8ab]",
    },
  ];

  return (
    <main className="min-h-screen bg-[#eef2f6] text-slate-950">
      <div className="mx-auto max-w-[1280px] px-4 py-4 sm:px-6 lg:px-8">
        <div className="mx-auto max-w-[420px] overflow-hidden rounded-[26px] bg-white shadow-[0_28px_80px_rgba(15,23,42,0.10)] lg:max-w-[1180px] lg:rounded-[36px]">
          <header className="flex items-center justify-between border-b border-slate-200/80 px-5 py-4 lg:px-8">
            <div className="flex items-center gap-3">
              <div className="flex h-9 w-9 items-center justify-center rounded-2xl bg-[#0d5be1] text-white">
                <Building2 className="h-4 w-4" />
              </div>
              <div>
                <p className="text-sm font-bold text-slate-900">
                  Skyline Residences
                </p>
                <p className="text-[11px] font-medium text-slate-500">
                  Apartment Management Platform
                </p>
              </div>
            </div>

            <Link
              to="/login"
              className="rounded-xl bg-[#0d5be1] px-4 py-2 text-xs font-bold text-white transition hover:bg-[#084cbc]"
            >
              Access portal
            </Link>
          </header>

          <section className="relative isolate overflow-hidden px-5 pb-8 pt-6 lg:grid lg:grid-cols-[1.05fr_0.95fr] lg:gap-8 lg:px-8 lg:pb-10 lg:pt-8">
            <div className="relative z-10">
              <p className="text-[10px] font-bold uppercase tracking-[0.28em] text-[#2e63c6]">
                Operations hub
              </p>
              <h1 className="mt-3 text-[2.1rem] font-black leading-[1.02] tracking-[-0.04em] text-slate-950 lg:max-w-[12ch] lg:text-[4.2rem]">
                Centralized Apartment Operations
              </h1>
              <p className="mt-4 max-w-[30ch] text-sm leading-6 text-slate-600 lg:max-w-[48ch] lg:text-base lg:leading-7">
                A connected apartment building platform for management teams
                and residents. Leasing, billing, packages, complaints, and
                facilities stay inside one consistent system.
              </p>

              <div className="mt-6 flex flex-col gap-3 sm:flex-row lg:max-w-[620px]">
                <Link
                  to="/login"
                  className="ui-hover-soft inline-flex items-center justify-center gap-2 rounded-none bg-[#0d5be1] px-4 py-3 text-sm font-bold text-white shadow-[0_14px_28px_rgba(13,91,225,0.22)] transition hover:bg-[#084cbc]"
                >
                  Sign in to portal
                </Link>
                <a
                  href={androidDownloadPath}
                  className="ui-hover-soft inline-flex items-center justify-center gap-2 rounded-none border border-[#0d5be1] bg-[#eff5ff] px-4 py-3 text-sm font-semibold text-[#0d5be1] transition hover:bg-[#dbe9ff]"
                >
                  <Download className="h-4 w-4" />
                  Download Android app
                </a>
                <a
                  href="#workflow"
                  className="ui-hover-soft inline-flex items-center justify-center rounded-none border border-slate-300 bg-white px-4 py-3 text-sm font-semibold text-slate-700 transition hover:border-slate-400"
                >
                  Explore workflows
                </a>
              </div>

              {error && (
                <div className="mt-4 rounded-2xl border border-amber-200 bg-amber-50 px-4 py-3 text-xs leading-5 text-amber-900">
                  Live backend data is temporarily unavailable. The landing page
                  still works, but a few stats are currently showing fallback
                  values.
                </div>
              )}
            </div>

            <div className="relative mt-6 lg:mt-0">
              <div className="absolute inset-x-0 top-4 mx-auto h-[88%] w-[78%] rounded-[30px] bg-[linear-gradient(180deg,rgba(255,255,255,0.06),rgba(255,255,255,0))] blur-3xl" />
              <div
                className="relative h-[340px] overflow-hidden rounded-[30px] bg-cover bg-center lg:h-[520px]"
                style={{ backgroundImage: `url(${heroImage})` }}
              >
                <div className="absolute inset-0 bg-[linear-gradient(180deg,rgba(255,255,255,0.04),rgba(10,15,30,0.16))]" />
              </div>
            </div>
          </section>

          <section className="grid grid-cols-3 gap-0 border-y border-slate-200 bg-[#f8fafc] px-5 py-8 text-center lg:px-8">
            {metricItems.map((item, index) => (
              <div
                key={item.label}
                className={`${index < metricItems.length - 1 ? "border-r border-slate-200" : ""} px-2`}
              >
                <p className="text-[1.9rem] font-black tracking-[-0.05em] text-[#0d3db7] lg:text-[2.8rem]">
                  {item.value}
                </p>
                <p className="mt-2 text-[11px] font-medium text-slate-600 lg:text-sm">
                  {item.label}
                </p>
              </div>
            ))}
          </section>

          <section
            id="workflow"
            className="px-5 py-10 lg:grid lg:grid-cols-[0.75fr_1.25fr] lg:gap-10 lg:px-8 lg:py-14"
          >
            <div className="lg:sticky lg:top-10 lg:self-start">
              <p className="text-[10px] font-bold uppercase tracking-[0.26em] text-[#2e63c6]">
                Core workflows
              </p>
              <h2 className="mt-3 text-[2rem] font-black leading-tight tracking-[-0.04em] text-slate-950">
                Built for real building operations
              </h2>
              <div className="mt-4 h-1.5 w-20 rounded-full bg-[#0d5be1]" />
              <p className="mt-5 max-w-[28ch] text-sm leading-6 text-slate-600 lg:max-w-[32ch]">
                This page stays focused on the parts that matter for an
                apartment management system: resident records, finance,
                facilities, and internal operations.
              </p>
            </div>

            <div className="mt-8 space-y-4 lg:mt-0">
              {standards.map((item) => (
                <article
                  key={item.title}
                  className={`ui-hover-lift relative overflow-hidden rounded-[26px] p-5 shadow-[0_18px_40px_rgba(15,23,42,0.08)] ${item.tone}`}
                >
                  <div
                    className={`absolute inset-x-0 bottom-0 h-2 ${item.accent}`}
                  />
                  <div className="flex items-start gap-4">
                    <div
                      className={`flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl ${item.tone.includes("text-white") ? "bg-white/14 text-white" : "bg-[#eff4fb] text-[#0d5be1]"}`}
                    >
                      <item.icon className="h-5 w-5" />
                    </div>
                    <div>
                      <h3 className="text-lg font-extrabold">{item.title}</h3>
                      <p
                        className={`mt-2 text-sm leading-6 ${item.tone.includes("text-white") ? "text-blue-100/90" : "text-slate-600"}`}
                      >
                        {item.desc}
                      </p>
                    </div>
                  </div>
                </article>
              ))}
            </div>
          </section>

          <section className="bg-[#060d26] px-5 py-12 text-white lg:grid lg:grid-cols-[0.82fr_1.18fr] lg:items-center lg:gap-14 lg:px-8 lg:py-16">
            <div className="mx-auto mb-8 flex w-full max-w-[320px] justify-center lg:mb-0 lg:max-w-[360px]">
              <div className="rounded-[30px] border border-[#203052] bg-[linear-gradient(180deg,#ffd7ca,#f0b39d)] p-3 shadow-[0_22px_50px_rgba(0,0,0,0.35)]">
                <div className="flex h-[356px] w-[190px] items-center justify-center rounded-[24px] border border-black/10 bg-[#fff9f4] p-3">
                  <div className="flex h-full w-full flex-col rounded-[18px] border border-slate-200 bg-white p-3 text-slate-900 shadow-inner">
                    <div className="flex items-center justify-between">
                      <span className="text-[10px] font-bold uppercase tracking-[0.22em] text-slate-400">
                        Portal
                      </span>
                      <Sparkles className="h-3.5 w-3.5 text-[#0d5be1]" />
                    </div>
                    <div className="mt-4 flex-1 rounded-2xl bg-[#f4f7fb] p-3">
                      <p className="text-[11px] font-bold text-slate-500">
                        Operations ticket
                      </p>
                      <p className="mt-2 text-sm font-bold">
                        Complaint Desk
                      </p>
                      <p className="mt-2 text-[11px] leading-5 text-slate-500">
                        Packages, complaints, and staff coordination sit inside
                        one management flow.
                      </p>
                    </div>
                    <div className="mt-4 space-y-2">
                      <div className="rounded-xl bg-[#0d5be1] px-3 py-2.5 text-[11px] font-bold text-white">
                        Leasing
                      </div>
                      <div className="rounded-xl bg-slate-100 px-3 py-2.5 text-[11px] font-semibold text-slate-600">
                        Utility Desk
                      </div>
                      <div className="rounded-xl bg-slate-100 px-3 py-2.5 text-[11px] font-semibold text-slate-600">
                        Support Desk
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div>
              <h2 className="text-[2rem] font-black leading-tight tracking-[-0.04em] text-white lg:text-[2.8rem]">
                A modern internal workspace for building teams
              </h2>
              <p className="mt-4 max-w-[44ch] text-sm leading-7 text-blue-100/78 lg:text-base">
                The platform is designed for everyday execution across leasing,
                utility billing, package desk operations, and complaint
                coordination.
              </p>

              <div className="mt-7 space-y-3">
                {[
                  "Unified notifications across resident, admin, and staff flows",
                  "Direct visibility into billing, booking, and complaint handling",
                  "Structured modules that map to practical apartment operations",
                ].map((item) => (
                  <div key={item} className="flex items-start gap-3">
                    <CheckCheck className="mt-0.5 h-5 w-5 shrink-0 text-[#7aa6ff]" />
                    <p className="text-sm leading-6 text-blue-100/86">{item}</p>
                  </div>
                ))}
              </div>
            </div>
          </section>

          <section className="px-5 py-10 lg:px-8 lg:py-14">
            <div className="ui-hover-lift rounded-[30px] bg-[linear-gradient(180deg,#0d5be1,#0b3fc4)] px-6 py-7 text-white shadow-[0_24px_60px_rgba(13,91,225,0.28)] lg:flex lg:items-center lg:justify-between lg:px-8">
              <div className="max-w-[34rem]">
                <p className="text-[10px] font-bold uppercase tracking-[0.28em] text-blue-100/80">
                  Skyline Residences
                </p>
                <h2 className="mt-3 text-3xl font-black leading-tight tracking-[-0.04em]">
                  Skyline Residences Management Portal
                </h2>
                <p className="mt-4 text-sm leading-7 text-blue-100/86">
                  Use the web portal for internal workflows, or install the
                  mobile app for residents and on-the-go staff access.
                </p>
              </div>

              <div className="mt-6 flex flex-col gap-3 lg:mt-0 lg:items-end">
                <Link
                  to="/login"
                  className="ui-hover-soft inline-flex items-center gap-2 rounded-2xl bg-white px-5 py-3 text-sm font-bold text-[#0d5be1] transition hover:bg-blue-50"
                >
                  Access portal
                  <ArrowRight className="h-4 w-4" />
                </Link>
                <a
                  href={androidDownloadPath}
                  className="ui-hover-soft inline-flex items-center gap-2 rounded-2xl border border-white/20 bg-white/10 px-5 py-3 text-sm font-bold text-white transition hover:bg-white/16"
                >
                  <Download className="h-4 w-4" />
                  Download Android app
                </a>
              </div>
            </div>
          </section>

          <footer className="border-t border-slate-200 px-5 py-6 text-center text-[11px] text-slate-500 lg:px-8">
            <div className="flex flex-wrap items-center justify-center gap-x-4 gap-y-2">
              <span className="inline-flex items-center gap-2 font-semibold text-slate-700">
                <Building2 className="h-3.5 w-3.5" />
                Skyline Residences
              </span>
              <span>
                Live apartment and facility data is connected to the current backend
              </span>
              <span>{availableUnits.length} units currently available for review</span>
            </div>
            <p className="mt-3">
              © 2026 Skyline Residences. Apartment Management Platform.
            </p>
          </footer>
        </div>
      </div>
    </main>
  );
}
