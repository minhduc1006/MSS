import { useEffect, useMemo, useState } from "react";
import Layout from "../components/Layout";
import { useToast } from "../components/Toast";
import {
  AUTH_API_BASE,
  OPERATIONS_API_BASE,
  apiRequest,
  getSession,
  type ComplaintItem,
  type PackageItem,
  type ResidentItem,
  type StaffItem,
  type StaffShiftItem,
} from "../lib/api";

const initialPackageForm = { residentId: "", recordType: "Parcel", carrier: "", itemName: "", trackingCode: "", location: "Front Desk", note: "" };
const initialComplaintForm = { residentId: "", category: "Maintenance", title: "", description: "", priority: "Medium" };
const initialShiftForm = { staffId: "", shiftDate: "", shiftLabel: "Morning", zone: "Tower A Lobby", startTime: "08:00", endTime: "16:00", status: "Scheduled", note: "" };

export default function AdminOperationsHub() {
  const { showToast } = useToast();
  const session = getSession();
  const [packages, setPackages] = useState<PackageItem[]>([]);
  const [complaints, setComplaints] = useState<ComplaintItem[]>([]);
  const [shifts, setShifts] = useState<StaffShiftItem[]>([]);
  const [residents, setResidents] = useState<ResidentItem[]>([]);
  const [staff, setStaff] = useState<StaffItem[]>([]);
  const [assignmentDrafts, setAssignmentDrafts] = useState<Record<number, string>>({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [modal, setModal] = useState<"package" | "complaint" | "shift" | null>(null);
  const [saving, setSaving] = useState(false);
  const [packageForm, setPackageForm] = useState(initialPackageForm);
  const [complaintForm, setComplaintForm] = useState(initialComplaintForm);
  const [shiftForm, setShiftForm] = useState(initialShiftForm);

  useEffect(() => {
    void loadPage();
  }, []);

  const packageResident = useMemo(() => residents.find((item) => item.id === Number(packageForm.residentId)), [packageForm.residentId, residents]);
  const complaintResident = useMemo(() => residents.find((item) => item.id === Number(complaintForm.residentId)), [complaintForm.residentId, residents]);
  const shiftStaff = useMemo(() => staff.find((item) => item.id === Number(shiftForm.staffId)), [shiftForm.staffId, staff]);
  const pendingPackages = packages.filter((item) => !/(picked|claimed)/i.test(item.status)).length;
  const openComplaints = complaints.filter((item) => !["Resolved", "Closed"].includes(item.status)).length;
  const rated = complaints.filter((item) => item.residentRating != null);
  const averageRating = rated.length === 0 ? "--" : `${(rated.reduce((sum, item) => sum + (item.residentRating ?? 0), 0) / rated.length).toFixed(1)}/5`;

  return (
    <Layout title="Operations Hub" role="admin">
      <div className="p-4 lg:p-6">
        <div className="mb-6 flex flex-col gap-4 rounded-3xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-800 dark:bg-slate-900 lg:flex-row lg:items-center lg:justify-between">
          <div className="max-w-2xl">
            <p className="text-xs font-bold uppercase tracking-[0.3em] text-[#137fec]">Operations Control</p>
            <h1 className="mt-2 text-2xl font-extrabold tracking-tight text-slate-900 dark:text-slate-100">Packages, complaints, ratings, and shift roster</h1>
            <p className="mt-2 text-sm text-slate-500 dark:text-slate-400">This screen brings Parcel and Lost & Found, Complaint and Feedback with ratings, and Staff Shift and Duty Roster into React admin.</p>
          </div>
          <div className="flex flex-wrap gap-2">
            <button onClick={() => void loadPage()} className="rounded-2xl border border-slate-200 px-4 py-3 text-sm font-bold dark:border-slate-700">Refresh</button>
            <button onClick={() => setModal("shift")} className="rounded-2xl border border-[#137fec]/20 bg-[#137fec]/10 px-4 py-3 text-sm font-bold text-[#137fec]">Schedule Shift</button>
            <button onClick={() => setModal("package")} className="rounded-2xl border border-slate-200 px-4 py-3 text-sm font-bold dark:border-slate-700">Log Package</button>
            <button onClick={() => setModal("complaint")} className="rounded-2xl bg-[#137fec] px-4 py-3 text-sm font-bold text-white">Log Complaint</button>
          </div>
        </div>

        <section className="mb-6 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <MetricCard label="Pending package desk" value={String(pendingPackages)} note="Awaiting pickup or claim" />
          <MetricCard label="Open complaints" value={String(openComplaints)} note="Need assignment or closure" />
          <MetricCard label="Service rating" value={averageRating} note="Resident feedback on resolved tickets" />
          <MetricCard label="Scheduled shifts" value={String(shifts.filter((item) => item.status === "Scheduled").length)} note="Upcoming duty roster" />
        </section>

        {loading ? <StateBlock text="Loading operations hub..." /> : error ? <ErrorBlock text={error} /> : (
          <div className="space-y-6">
            <section className="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-800 dark:bg-slate-900">
              <div className="mb-4 flex items-center justify-between">
                <div>
                  <h2 className="text-lg font-bold">Parcel and Lost & Found</h2>
                  <p className="text-sm text-slate-500 dark:text-slate-400">Log front-desk intake and close the loop when residents pick items up.</p>
                </div>
                <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-bold uppercase tracking-widest text-slate-600 dark:bg-slate-800 dark:text-slate-300">{packages.length} records</span>
              </div>
              <div className="grid gap-4 xl:grid-cols-2">
                {packages.map((record) => (
                  <div key={record.id} className="rounded-3xl border border-slate-200 bg-slate-50/70 p-4 dark:border-slate-800 dark:bg-slate-950/40">
                    <div className="flex items-start justify-between gap-3">
                      <div>
                        <h3 className="text-lg font-bold">{record.itemName}</h3>
                        <p className="text-sm text-slate-500 dark:text-slate-400">{record.recordType} - {record.carrier ?? "Front Desk"}</p>
                        <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">{record.residentName ? `${record.residentName} - Unit ${record.unitNumber}` : "Resident not linked"}</p>
                      </div>
                      <StatusPill status={record.status} group="package" />
                    </div>
                    <div className="mt-4 grid gap-3 sm:grid-cols-2">
                      <InfoTile label="Location" value={record.location} />
                      <InfoTile label="Tracking" value={record.trackingCode ?? "Not provided"} />
                    </div>
                    {record.note && <p className="mt-4 rounded-2xl bg-white px-3 py-2 text-sm text-slate-600 dark:bg-slate-900 dark:text-slate-300">{record.note}</p>}
                    <div className="mt-4 flex flex-wrap gap-2">
                      {!/received/i.test(record.status) && !/(picked|claimed)/i.test(record.status) && <SmallButton label="Mark received" onClick={() => void updatePackageStatus(record.id, "Received")} />}
                      {!/(picked|claimed)/i.test(record.status) && <SmallButton label={record.recordType === "Lost & Found" ? "Mark claimed" : "Mark picked up"} onClick={() => void updatePackageStatus(record.id, record.recordType === "Lost & Found" ? "Claimed" : "Picked Up")} tone="primary" />}
                    </div>
                  </div>
                ))}
                {packages.length === 0 && <StateBlock text="No package or lost and found records found." />}
              </div>
            </section>
            <section className="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-800 dark:bg-slate-900">
              <div className="mb-4 flex items-center justify-between">
                <div>
                  <h2 className="text-lg font-bold">Complaint and Feedback</h2>
                  <p className="text-sm text-slate-500 dark:text-slate-400">Assign staff, progress tickets, and watch the resident rating signal.</p>
                </div>
                <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-bold uppercase tracking-widest text-slate-600 dark:bg-slate-800 dark:text-slate-300">{complaints.length} tickets</span>
              </div>
              <div className="grid gap-4 xl:grid-cols-2">
                {complaints.map((complaint) => (
                  <div key={complaint.id} className="rounded-3xl border border-slate-200 bg-slate-50/70 p-4 dark:border-slate-800 dark:bg-slate-950/40">
                    <div className="flex items-start justify-between gap-3">
                      <div>
                        <h3 className="text-lg font-bold">{complaint.title}</h3>
                        <p className="text-sm text-slate-500 dark:text-slate-400">{complaint.category} - {complaint.priority}</p>
                        <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">{complaint.residentName} - Unit {complaint.unitNumber}</p>
                      </div>
                      <StatusPill status={complaint.status} group="complaint" />
                    </div>
                    <p className="mt-4 text-sm text-slate-600 dark:text-slate-300">{complaint.description}</p>
                    <div className="mt-4 rounded-2xl bg-white p-3 shadow-sm dark:bg-slate-900">
                      <p className="text-[11px] font-bold uppercase tracking-widest text-slate-400">Assignment</p>
                      <div className="mt-3 flex flex-col gap-2 sm:flex-row">
                        <select value={assignmentDrafts[complaint.id] ?? String(complaint.assignedStaffId ?? "")} onChange={(e) => setAssignmentDrafts((c) => ({ ...c, [complaint.id]: e.target.value }))} className="flex-1 rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-950">
                          <option value="">Select staff</option>
                          {staff.map((member) => <option key={member.id} value={member.id}>{member.fullName} - {member.role}</option>)}
                        </select>
                        <SmallButton label="Assign" onClick={() => void assignComplaint(complaint)} tone="primary" />
                      </div>
                      <p className="mt-2 text-xs text-slate-500 dark:text-slate-400">Current: {complaint.assignedStaffName ?? "Unassigned"}</p>
                    </div>
                    {complaint.residentRating != null && <div className="mt-4 rounded-2xl border border-emerald-200 bg-emerald-50 p-3 text-sm text-emerald-900 dark:border-emerald-900/40 dark:bg-emerald-900/10 dark:text-emerald-200">Rating {complaint.residentRating}/5 {complaint.residentReview ? `- ${complaint.residentReview}` : ""}</div>}
                    <div className="mt-4 flex flex-wrap gap-2">
                      {!["In Progress", "Resolved", "Closed"].includes(complaint.status) && <SmallButton label="Start work" onClick={() => void updateComplaintStatus(complaint.id, "In Progress")} />}
                      {!["Resolved", "Closed"].includes(complaint.status) && <SmallButton label="Resolve" onClick={() => void updateComplaintStatus(complaint.id, "Resolved")} tone="success" />}
                    </div>
                  </div>
                ))}
                {complaints.length === 0 && <StateBlock text="No complaints found." />}
              </div>
            </section>

            <section className="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-800 dark:bg-slate-900">
              <div className="mb-4 flex items-center justify-between">
                <div>
                  <h2 className="text-lg font-bold">Staff Shift and Duty Roster</h2>
                  <p className="text-sm text-slate-500 dark:text-slate-400">Schedule guards, technicians, and support staff by date, shift, and zone.</p>
                </div>
                <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-bold uppercase tracking-widest text-slate-600 dark:bg-slate-800 dark:text-slate-300">{shifts.length} shifts</span>
              </div>
              <div className="grid gap-4 xl:grid-cols-2">
                {shifts.map((shift) => (
                  <div key={shift.id} className="rounded-3xl border border-slate-200 bg-slate-50/70 p-4 dark:border-slate-800 dark:bg-slate-950/40">
                    <div className="flex items-start justify-between gap-3">
                      <div>
                        <h3 className="text-lg font-bold">{shift.staffName}</h3>
                        <p className="text-sm text-slate-500 dark:text-slate-400">{shift.role} - {shift.shiftLabel}</p>
                        <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">{formatDate(shift.shiftDate)} - {shift.zone}</p>
                      </div>
                      <StatusPill status={shift.status} group="shift" />
                    </div>
                    <div className="mt-4 grid gap-3 sm:grid-cols-2">
                      <InfoTile label="Time" value={`${shift.startTime} - ${shift.endTime}`} />
                      <InfoTile label="Zone" value={shift.zone} />
                    </div>
                    {shift.note && <p className="mt-4 rounded-2xl bg-white px-3 py-2 text-sm text-slate-600 dark:bg-slate-900 dark:text-slate-300">{shift.note}</p>}
                    <div className="mt-4 flex flex-wrap gap-2">
                      {shift.status !== "Scheduled" && <SmallButton label="Reschedule" onClick={() => void updateShiftStatus(shift, "Scheduled")} />}
                      {shift.status !== "Completed" && <SmallButton label="Complete" onClick={() => void updateShiftStatus(shift, "Completed")} tone="success" />}
                      {shift.status !== "Cancelled" && <SmallButton label="Cancel" onClick={() => void updateShiftStatus(shift, "Cancelled")} tone="danger" />}
                    </div>
                  </div>
                ))}
                {shifts.length === 0 && <StateBlock text="No shifts found." />}
              </div>
            </section>
          </div>
        )}

        {modal && <div onClick={closeModal} className="fixed inset-0 z-[100] bg-black/60 backdrop-blur-sm" />}
        {modal === "package" && (
          <div className="fixed inset-x-4 bottom-0 z-[110] mx-auto rounded-t-[32px] bg-white p-6 pb-10 shadow-2xl dark:bg-[#101922] sm:max-w-xl lg:inset-x-0 lg:top-1/2 lg:bottom-auto lg:w-full lg:max-w-2xl lg:-translate-y-1/2 lg:rounded-[32px] lg:pb-6">
            <ModalHeader title="Log Parcel or Lost and Found" subtitle="Capture a front-desk intake record." onClose={closeModal} />
            <div className="space-y-4">
              <select value={packageForm.residentId} onChange={(e) => setPackageForm((c) => ({ ...c, residentId: e.target.value }))} className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900">
                <option value="">Resident optional</option>
                {residents.map((item) => <option key={item.id} value={item.id}>{item.fullName} - Unit {item.unitNumber}</option>)}
              </select>
              <div className="grid gap-3 sm:grid-cols-2">
                <select value={packageForm.recordType} onChange={(e) => setPackageForm((c) => ({ ...c, recordType: e.target.value }))} className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900"><option>Parcel</option><option>Lost & Found</option></select>
                <input value={packageForm.carrier} onChange={(e) => setPackageForm((c) => ({ ...c, carrier: e.target.value }))} placeholder="Carrier or source" className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
              </div>
              <input value={packageForm.itemName} onChange={(e) => setPackageForm((c) => ({ ...c, itemName: e.target.value }))} placeholder="Item name" className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
              <div className="grid gap-3 sm:grid-cols-2">
                <input value={packageForm.trackingCode} onChange={(e) => setPackageForm((c) => ({ ...c, trackingCode: e.target.value }))} placeholder="Tracking code" className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
                <input value={packageForm.location} onChange={(e) => setPackageForm((c) => ({ ...c, location: e.target.value }))} placeholder="Location" className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
              </div>
              <textarea value={packageForm.note} onChange={(e) => setPackageForm((c) => ({ ...c, note: e.target.value }))} placeholder="Desk note" className="min-h-24 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
              {packageResident && <InfoPanel title={packageResident.fullName} lines={[`Unit ${packageResident.unitNumber} - ${packageResident.tower}`, packageResident.email]} />}
              <button disabled={saving} onClick={() => void createPackage()} className="w-full rounded-2xl bg-[#137fec] py-4 text-sm font-bold text-white disabled:opacity-50">{saving ? "Saving record..." : "Save package record"}</button>
            </div>
          </div>
        )}
        {modal === "complaint" && (
          <div className="fixed inset-x-4 bottom-0 z-[110] mx-auto rounded-t-[32px] bg-white p-6 pb-10 shadow-2xl dark:bg-[#101922] sm:max-w-xl lg:inset-x-0 lg:top-1/2 lg:bottom-auto lg:w-full lg:max-w-2xl lg:-translate-y-1/2 lg:rounded-[32px] lg:pb-6">
            <ModalHeader title="Log Complaint Ticket" subtitle="Create a complaint on behalf of a resident." onClose={closeModal} />
            <div className="space-y-4">
              <select value={complaintForm.residentId} onChange={(e) => setComplaintForm((c) => ({ ...c, residentId: e.target.value }))} className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900">
                <option value="">Select resident</option>
                {residents.map((item) => <option key={item.id} value={item.id}>{item.fullName} - Unit {item.unitNumber}</option>)}
              </select>
              <div className="grid gap-3 sm:grid-cols-2">
                <select value={complaintForm.category} onChange={(e) => setComplaintForm((c) => ({ ...c, category: e.target.value }))} className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900"><option>Maintenance</option><option>Noise</option><option>Security</option><option>Hygiene</option><option>Other</option></select>
                <select value={complaintForm.priority} onChange={(e) => setComplaintForm((c) => ({ ...c, priority: e.target.value }))} className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900"><option>Low</option><option>Medium</option><option>High</option><option>Urgent</option></select>
              </div>
              <input value={complaintForm.title} onChange={(e) => setComplaintForm((c) => ({ ...c, title: e.target.value }))} placeholder="Complaint title" className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
              <textarea value={complaintForm.description} onChange={(e) => setComplaintForm((c) => ({ ...c, description: e.target.value }))} placeholder="Describe the issue" className="min-h-28 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
              {complaintResident && <InfoPanel title={complaintResident.fullName} lines={[`Unit ${complaintResident.unitNumber} - ${complaintResident.tower}`, "Ticket will be created as Open"]} />}
              <button disabled={saving} onClick={() => void createComplaint()} className="w-full rounded-2xl bg-[#137fec] py-4 text-sm font-bold text-white disabled:opacity-50">{saving ? "Creating complaint..." : "Create complaint"}</button>
            </div>
          </div>
        )}
        {modal === "shift" && (
          <div className="fixed inset-x-4 bottom-0 z-[110] mx-auto rounded-t-[32px] bg-white p-6 pb-10 shadow-2xl dark:bg-[#101922] sm:max-w-xl lg:inset-x-0 lg:top-1/2 lg:bottom-auto lg:w-full lg:max-w-2xl lg:-translate-y-1/2 lg:rounded-[32px] lg:pb-6">
            <ModalHeader title="Schedule Staff Shift" subtitle="Assign a staff member to a date, zone, and duty window." onClose={closeModal} />
            <div className="space-y-4">
              <select value={shiftForm.staffId} onChange={(e) => setShiftForm((c) => ({ ...c, staffId: e.target.value }))} className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900">
                <option value="">Select staff member</option>
                {staff.filter((item) => item.status !== "Deactivated").map((item) => <option key={item.id} value={item.id}>{item.fullName} - {item.role}</option>)}
              </select>
              <div className="grid gap-3 sm:grid-cols-2">
                <input value={shiftForm.shiftDate} onChange={(e) => setShiftForm((c) => ({ ...c, shiftDate: e.target.value }))} type="date" className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
                <select value={shiftForm.shiftLabel} onChange={(e) => setShiftForm((c) => ({ ...c, shiftLabel: e.target.value }))} className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900"><option>Morning</option><option>Afternoon</option><option>Night</option></select>
              </div>
              <div className="grid gap-3 sm:grid-cols-3">
                <input value={shiftForm.zone} onChange={(e) => setShiftForm((c) => ({ ...c, zone: e.target.value }))} placeholder="Zone" className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
                <input value={shiftForm.startTime} onChange={(e) => setShiftForm((c) => ({ ...c, startTime: e.target.value }))} type="time" className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
                <input value={shiftForm.endTime} onChange={(e) => setShiftForm((c) => ({ ...c, endTime: e.target.value }))} type="time" className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
              </div>
              <textarea value={shiftForm.note} onChange={(e) => setShiftForm((c) => ({ ...c, note: e.target.value }))} placeholder="Shift note" className="min-h-24 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
              {shiftStaff && <InfoPanel title={shiftStaff.fullName} lines={[`${shiftStaff.role} - ${shiftStaff.shift}`, `Scheduled by ${session?.fullName ?? "Admin Portal"}`]} />}
              <button disabled={saving} onClick={() => void createShift()} className="w-full rounded-2xl bg-[#137fec] py-4 text-sm font-bold text-white disabled:opacity-50">{saving ? "Scheduling shift..." : "Create shift"}</button>
            </div>
          </div>
        )}
      </div>
    </Layout>
  );

  async function loadPage() {
    setLoading(true);
    setError(null);
    try {
      const [packageData, complaintData, shiftData, residentData, staffData] = await Promise.all([
        apiRequest<PackageItem[]>(`${OPERATIONS_API_BASE}/packages`),
        apiRequest<ComplaintItem[]>(`${OPERATIONS_API_BASE}/complaints`),
        apiRequest<StaffShiftItem[]>(`${OPERATIONS_API_BASE}/shifts`),
        apiRequest<ResidentItem[]>(`${AUTH_API_BASE}/users/residents`),
        apiRequest<StaffItem[]>(`${AUTH_API_BASE}/users/staff`),
      ]);
      setPackages(packageData);
      setComplaints(complaintData);
      setShifts(shiftData);
      setResidents(residentData);
      setStaff(staffData);
    } catch (loadError) {
      const message = loadError instanceof Error ? loadError.message : "Unable to load operations hub.";
      setError(message);
      showToast(message, "error");
    } finally {
      setLoading(false);
    }
  }

  function closeModal() {
    setModal(null);
    setSaving(false);
    setPackageForm(initialPackageForm);
    setComplaintForm(initialComplaintForm);
    setShiftForm(initialShiftForm);
  }

  async function createPackage() {
    if (!packageForm.itemName.trim()) {
      showToast("Item name is required.", "error");
      return;
    }
    setSaving(true);
    try {
      await apiRequest<PackageItem>(`${OPERATIONS_API_BASE}/packages`, {
        method: "POST",
        body: JSON.stringify({
          residentId: packageResident?.id ?? null,
          residentName: packageResident?.fullName ?? null,
          unitNumber: packageResident?.unitNumber ?? null,
          recordType: packageForm.recordType,
          carrier: packageForm.carrier.trim() || null,
          itemName: packageForm.itemName.trim(),
          trackingCode: packageForm.trackingCode.trim() || null,
          location: packageForm.location.trim() || "Front Desk",
          status: packageForm.recordType === "Lost & Found" ? "Logged" : "Received",
          reportedByName: session?.fullName ?? "Front Desk",
          note: packageForm.note.trim() || null,
        }),
      });
      await loadPage();
      closeModal();
      showToast("Package desk record created.", "success");
    } catch (actionError) {
      showToast(actionError instanceof Error ? actionError.message : "Unable to create package record.", "error");
      setSaving(false);
    }
  }

  async function createComplaint() {
    if (!complaintResident || !complaintForm.title.trim() || !complaintForm.description.trim()) {
      showToast("Select a resident and complete complaint details.", "error");
      return;
    }
    setSaving(true);
    try {
      await apiRequest<ComplaintItem>(`${OPERATIONS_API_BASE}/complaints`, {
        method: "POST",
        body: JSON.stringify({
          residentId: complaintResident.id,
          residentName: complaintResident.fullName,
          unitNumber: complaintResident.unitNumber,
          category: complaintForm.category,
          title: complaintForm.title.trim(),
          description: complaintForm.description.trim(),
          priority: complaintForm.priority,
        }),
      });
      await loadPage();
      closeModal();
      showToast("Complaint ticket created.", "success");
    } catch (actionError) {
      showToast(actionError instanceof Error ? actionError.message : "Unable to create complaint.", "error");
      setSaving(false);
    }
  }

  async function createShift() {
    if (!shiftStaff || !shiftForm.shiftDate || !shiftForm.zone.trim()) {
      showToast("Select a staff member and complete shift date and zone.", "error");
      return;
    }
    setSaving(true);
    try {
      await apiRequest<StaffShiftItem>(`${OPERATIONS_API_BASE}/shifts`, {
        method: "POST",
        body: JSON.stringify({
          staffId: shiftStaff.id,
          staffName: shiftStaff.fullName,
          role: shiftStaff.role,
          shiftDate: shiftForm.shiftDate,
          shiftLabel: shiftForm.shiftLabel,
          zone: shiftForm.zone.trim(),
          startTime: shiftForm.startTime,
          endTime: shiftForm.endTime,
          status: shiftForm.status,
          note: shiftForm.note.trim() || null,
        }),
      });
      await loadPage();
      closeModal();
      showToast("Staff shift scheduled.", "success");
    } catch (actionError) {
      showToast(actionError instanceof Error ? actionError.message : "Unable to create shift.", "error");
      setSaving(false);
    }
  }

  async function updatePackageStatus(packageId: number, status: string) {
    try {
      await apiRequest<PackageItem>(`${OPERATIONS_API_BASE}/packages/${packageId}/status`, { method: "POST", body: JSON.stringify({ status }) });
      await loadPage();
      showToast(`Package record moved to ${status}.`, "success");
    } catch (actionError) {
      showToast(actionError instanceof Error ? actionError.message : "Unable to update package status.", "error");
    }
  }

  async function assignComplaint(complaint: ComplaintItem) {
    const staffId = Number(assignmentDrafts[complaint.id] ?? complaint.assignedStaffId);
    const member = staff.find((item) => item.id === staffId);
    if (!member) {
      showToast("Choose a staff member before assigning.", "error");
      return;
    }
    try {
      await apiRequest<ComplaintItem>(`${OPERATIONS_API_BASE}/complaints/${complaint.id}/assign`, {
        method: "POST",
        body: JSON.stringify({ staffId: member.id, staffName: member.fullName }),
      });
      await loadPage();
      showToast(`${complaint.title} assigned to ${member.fullName}.`, "success");
    } catch (actionError) {
      showToast(actionError instanceof Error ? actionError.message : "Unable to assign complaint.", "error");
    }
  }

  async function updateComplaintStatus(complaintId: number, status: string) {
    try {
      await apiRequest<ComplaintItem>(`${OPERATIONS_API_BASE}/complaints/${complaintId}/status`, {
        method: "POST",
        body: JSON.stringify({ status, responseNote: status === "Resolved" ? "Resolved by building operations team." : "Ticket is now in progress." }),
      });
      await loadPage();
      showToast(`Complaint moved to ${status}.`, "success");
    } catch (actionError) {
      showToast(actionError instanceof Error ? actionError.message : "Unable to update complaint status.", "error");
    }
  }

  async function updateShiftStatus(shift: StaffShiftItem, status: string) {
    try {
      await apiRequest<StaffShiftItem>(`${OPERATIONS_API_BASE}/shifts/${shift.id}`, {
        method: "POST",
        body: JSON.stringify({
          staffId: shift.staffId,
          staffName: shift.staffName,
          role: shift.role,
          shiftDate: shift.shiftDate,
          shiftLabel: shift.shiftLabel,
          zone: shift.zone,
          startTime: shift.startTime,
          endTime: shift.endTime,
          status,
          note: shift.note,
        }),
      });
      await loadPage();
      showToast(`${shift.staffName} marked as ${status}.`, "success");
    } catch (actionError) {
      showToast(actionError instanceof Error ? actionError.message : "Unable to update shift status.", "error");
    }
  }
}

function MetricCard({ label, value, note }: { label: string; value: string; note: string }) {
  return <div className="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-800 dark:bg-slate-900"><p className="text-xs font-bold uppercase tracking-widest text-slate-400">{label}</p><p className="mt-3 text-2xl font-extrabold">{value}</p><p className="mt-1 text-xs text-slate-500 dark:text-slate-400">{note}</p></div>;
}

function ModalHeader({ title, subtitle, onClose }: { title: string; subtitle: string; onClose: () => void }) {
  return <div className="mb-6 flex items-center justify-between gap-4"><div><h3 className="text-lg font-bold">{title}</h3><p className="text-sm text-slate-500 dark:text-slate-400">{subtitle}</p></div><button onClick={onClose} className="rounded-full p-2 hover:bg-slate-100 dark:hover:bg-slate-800">x</button></div>;
}

function InfoPanel({ title, lines }: { title: string; lines: string[] }) {
  return <div className="rounded-2xl border border-[#137fec]/15 bg-[#137fec]/5 p-4 text-sm text-slate-600 dark:text-slate-300"><p className="font-bold text-slate-900 dark:text-slate-100">{title}</p>{lines.map((line) => <p key={line} className="mt-1">{line}</p>)}</div>;
}

function InfoTile({ label, value }: { label: string; value: string }) {
  return <div className="rounded-2xl bg-white px-3 py-3 shadow-sm dark:bg-slate-900"><p className="text-[11px] font-bold uppercase tracking-widest text-slate-400">{label}</p><p className="mt-2 text-sm font-bold text-slate-900 dark:text-slate-100">{value}</p></div>;
}

function SmallButton({ label, onClick, tone }: { label: string; onClick: () => void; tone?: "primary" | "danger" | "success" }) {
  const classes = tone === "primary" ? "bg-[#137fec] text-white" : tone === "danger" ? "bg-red-50 text-red-600 dark:bg-red-900/10 dark:text-red-300" : tone === "success" ? "bg-emerald-600 text-white" : "border border-slate-200 text-slate-700 dark:border-slate-700 dark:text-slate-200";
  return <button onClick={onClick} className={`rounded-2xl px-4 py-2 text-sm font-bold ${classes}`}>{label}</button>;
}

function StatusPill({ status, group }: { status: string; group: "package" | "complaint" | "shift" }) {
  const classes = group === "package" ? /(picked|claimed)/i.test(status) ? "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/20 dark:text-emerald-300" : /received/i.test(status) ? "bg-blue-100 text-blue-700 dark:bg-blue-900/20 dark:text-blue-300" : "bg-amber-100 text-amber-700 dark:bg-amber-900/20 dark:text-amber-300" : group === "complaint" ? status === "Resolved" || status === "Closed" ? "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/20 dark:text-emerald-300" : status === "Assigned" || status === "In Progress" ? "bg-blue-100 text-blue-700 dark:bg-blue-900/20 dark:text-blue-300" : "bg-amber-100 text-amber-700 dark:bg-amber-900/20 dark:text-amber-300" : status === "Completed" ? "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/20 dark:text-emerald-300" : status === "Cancelled" ? "bg-rose-100 text-rose-700 dark:bg-rose-900/20 dark:text-rose-300" : "bg-blue-100 text-blue-700 dark:bg-blue-900/20 dark:text-blue-300";
  return <span className={`rounded-full px-3 py-1 text-[10px] font-bold uppercase tracking-widest ${classes}`}>{status}</span>;
}

function StateBlock({ text }: { text: string }) {
  return <div className="rounded-3xl border border-dashed border-slate-300 bg-white p-6 text-center text-sm text-slate-500 dark:border-slate-700 dark:bg-slate-900">{text}</div>;
}

function ErrorBlock({ text }: { text: string }) {
  return <div className="rounded-3xl border border-rose-200 bg-rose-50 p-4 text-sm text-rose-700 dark:border-rose-900/40 dark:bg-rose-900/10 dark:text-rose-300">{text}</div>;
}

function formatDate(value: string) {
  return new Date(value).toLocaleDateString("en-US", { month: "short", day: "2-digit", year: "numeric" });
}
