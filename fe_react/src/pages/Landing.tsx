import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
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

const fallbackHighlights = [
  "Lease and tenancy tracking",
  "Utility billing visibility",
  "Package and complaint operations",
  "Resident-facing service workflows",
];

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
      : `${((state.occupiedUnits / state.totalUnits) * 100).toFixed(1)}%`;

  return (
    <main className="min-h-screen bg-[radial-gradient(circle_at_top_left,_rgba(20,82,161,0.16),_transparent_34%),linear-gradient(180deg,#f6f8fb_0%,#eef3f8_46%,#f8fafc_100%)] text-slate-900">
      <section className="mx-auto max-w-6xl px-6 py-8 sm:px-10">
        <header className="flex flex-wrap items-center justify-between gap-4 rounded-[28px] border border-white/70 bg-white/80 px-6 py-4 shadow-[0_20px_60px_rgba(15,23,42,0.08)] backdrop-blur">
          <div>
            <p className="text-xs font-extrabold uppercase tracking-[0.28em] text-sky-700">
              Skyline Heights
            </p>
            <h1 className="mt-1 text-lg font-extrabold text-slate-950">
              Apartment Building Management System
            </h1>
          </div>
          <div className="flex items-center gap-3">
            <Link
              to="/login"
              className="rounded-full border border-slate-200 px-5 py-3 text-sm font-bold text-slate-700 transition hover:border-sky-300 hover:text-sky-700"
            >
              Resident Portal
            </Link>
            <a
              href="#availability"
              className="rounded-full bg-sky-700 px-5 py-3 text-sm font-bold text-white shadow-[0_16px_35px_rgba(3,105,161,0.22)] transition hover:bg-sky-800"
            >
              Explore Units
            </a>
          </div>
        </header>

        <div className="mt-8 grid gap-6 lg:grid-cols-[1.3fr_0.7fr]">
          <div className="rounded-[36px] border border-slate-200/70 bg-white px-7 py-8 shadow-[0_24px_70px_rgba(15,23,42,0.08)]">
            <div className="inline-flex rounded-full bg-sky-50 px-4 py-2 text-xs font-extrabold uppercase tracking-[0.24em] text-sky-700">
              Public Leasing Overview
            </div>
            <h2 className="mt-5 max-w-3xl text-4xl font-extrabold leading-tight text-slate-950 sm:text-5xl">
              See the building before you decide to rent.
            </h2>
            <p className="mt-5 max-w-2xl text-base leading-8 text-slate-600">
              This public landing page lets prospective residents review unit
              availability, occupancy health, amenity operations, and the
              service standards already running inside the building.
            </p>
            <div className="mt-7 flex flex-wrap gap-3">
              {fallbackHighlights.map((item) => (
                <span
                  key={item}
                  className="rounded-full border border-slate-200 bg-slate-50 px-4 py-2 text-sm font-semibold text-slate-700"
                >
                  {item}
                </span>
              ))}
            </div>
          </div>

          <div className="grid gap-4">
            <MetricCard label="Occupancy" value={occupancyRate} note={`${state.occupiedUnits}/${state.totalUnits} units in use`} />
            <MetricCard label="Available Units" value={`${availableUnits.length}`} note="Vacant or assignable units" />
            <MetricCard label="Operational Facilities" value={`${operationalFacilities.length}`} note={`${state.facilities.length} total service assets`} />
          </div>
        </div>

        <section id="availability" className="mt-10 grid gap-6 lg:grid-cols-[0.9fr_1.1fr]">
          <div className="rounded-[32px] border border-slate-200 bg-[#0f172a] p-7 text-white shadow-[0_24px_70px_rgba(15,23,42,0.24)]">
            <p className="text-xs font-extrabold uppercase tracking-[0.28em] text-sky-200">
              Why This Building
            </p>
            <h3 className="mt-4 text-3xl font-extrabold leading-tight">
              A building run like an actual operations platform, not a brochure.
            </h3>
            <div className="mt-6 space-y-4 text-sm leading-7 text-slate-300">
              <p>
                Prospective renters can see whether the building is stable,
                staffed, and actively maintained before committing.
              </p>
              <p>
                Inside the resident platform, the management team already tracks
                leases, utility submissions, service complaints, package
                handling, and duty rosters.
              </p>
            </div>
            {error && (
              <div className="mt-6 rounded-2xl border border-amber-400/30 bg-amber-500/10 px-4 py-3 text-sm text-amber-100">
                Live backend metrics are temporarily unavailable. Showing the
                page with fallback messaging instead.
              </div>
            )}
          </div>

          <div className="rounded-[32px] border border-slate-200 bg-white p-7 shadow-[0_22px_60px_rgba(15,23,42,0.08)]">
            <div className="flex items-center justify-between gap-4">
              <div>
                <p className="text-xs font-extrabold uppercase tracking-[0.28em] text-slate-400">
                  Unit Snapshot
                </p>
                <h3 className="mt-2 text-2xl font-extrabold text-slate-950">
                  Current unit availability
                </h3>
              </div>
              <Link
                to="/login"
                className="rounded-full bg-slate-950 px-4 py-2 text-xs font-bold uppercase tracking-[0.2em] text-white"
              >
                Request Access
              </Link>
            </div>
            <div className="mt-6 grid gap-4 sm:grid-cols-2">
              {availableUnits.slice(0, 6).map((unit) => (
                <article
                  key={unit.id}
                  className="rounded-[24px] border border-slate-200 bg-slate-50 p-5"
                >
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <p className="text-xl font-extrabold text-slate-950">
                        Unit {unit.unitNumber}
                      </p>
                      <p className="mt-1 text-sm text-slate-500">
                        {unit.tower} • {unit.unitType}
                      </p>
                    </div>
                    <span className="rounded-full bg-emerald-50 px-3 py-1 text-xs font-bold uppercase tracking-[0.18em] text-emerald-700">
                      {unit.occupancyStatus}
                    </span>
                  </div>
                  <p className="mt-5 text-sm font-semibold text-slate-600">
                    Current balance:{" "}
                    <span className="text-slate-950">
                      {formatMoney(unit.balance)}
                    </span>
                  </p>
                </article>
              ))}
              {availableUnits.length === 0 && (
                <div className="rounded-[24px] border border-dashed border-slate-300 bg-slate-50 p-5 text-sm text-slate-500 sm:col-span-2">
                  No currently vacant units were returned by the live backend.
                </div>
              )}
            </div>
          </div>
        </section>

        <section className="mt-10 rounded-[32px] border border-slate-200 bg-white p-7 shadow-[0_22px_60px_rgba(15,23,42,0.08)]">
          <div className="flex flex-wrap items-end justify-between gap-4">
            <div>
              <p className="text-xs font-extrabold uppercase tracking-[0.28em] text-slate-400">
                Amenity Health
              </p>
              <h3 className="mt-2 text-2xl font-extrabold text-slate-950">
                Operational facilities and resident services
              </h3>
            </div>
            <p className="max-w-xl text-sm leading-7 text-slate-500">
              The same backend that powers the resident app also exposes shared
              facilities, service health, and maintenance visibility here.
            </p>
          </div>
          <div className="mt-6 grid gap-4 md:grid-cols-3">
            {state.facilities.slice(0, 6).map((facility) => (
              <article
                key={facility.id}
                className="rounded-[24px] border border-slate-200 bg-slate-50 p-5"
              >
                <div className="flex items-center justify-between gap-3">
                  <p className="text-lg font-extrabold text-slate-950">
                    {facility.name}
                  </p>
                  <span className="rounded-full bg-sky-50 px-3 py-1 text-[11px] font-bold uppercase tracking-[0.16em] text-sky-700">
                    {facility.status}
                  </span>
                </div>
                <p className="mt-2 text-sm text-slate-500">{facility.area}</p>
                <p className="mt-4 text-sm leading-7 text-slate-600">
                  {facility.description || "Resident-ready shared amenity and service zone."}
                </p>
              </article>
            ))}
          </div>
        </section>
      </section>
    </main>
  );
}

function MetricCard({
  label,
  value,
  note,
}: {
  label: string;
  value: string;
  note: string;
}) {
  return (
    <article className="rounded-[28px] border border-slate-200 bg-white px-6 py-5 shadow-[0_18px_45px_rgba(15,23,42,0.08)]">
      <p className="text-xs font-extrabold uppercase tracking-[0.28em] text-slate-400">
        {label}
      </p>
      <p className="mt-3 text-4xl font-extrabold text-slate-950">{value}</p>
      <p className="mt-3 text-sm leading-7 text-slate-500">{note}</p>
    </article>
  );
}

function formatMoney(value: number) {
  return `${new Intl.NumberFormat("vi-VN").format(Math.round(value))} VND`;
}
