import { useEffect, useMemo, useState } from "react";
import { AnimatePresence, motion } from "motion/react";
import {
  Annoyed,
  Bell,
  CalendarDays,
  Car,
  CheckCircle2,
  Clock3,
  HandPlatter,
  RefreshCw,
  Send,
  Sparkles,
  X,
} from "lucide-react";
import Layout from "../components/Layout";
import { useToast } from "../components/Toast";
import {
  BILLING_API_BASE,
  FACILITY_API_BASE,
  OPERATIONS_API_BASE,
  apiRequest,
  getSession,
  type AnnouncementItem,
  type BookingItem,
  type CreateInvoiceResponse,
  type CustomServiceRequestItem,
  type FacilitiesResponse,
  type FacilityItem,
} from "../lib/api";

const TIME_SLOTS = [
  "08:00 AM - 10:00 AM",
  "10:00 AM - 12:00 PM",
  "02:00 PM - 04:00 PM",
  "04:00 PM - 06:00 PM",
  "06:00 PM - 08:00 PM",
];

const initialRequestForm = {
  title: "",
  description: "",
  zone: "",
  preferredSchedule: "",
};

export default function ResidentBookings() {
  const { showToast } = useToast();
  const session = getSession();
  const [facilities, setFacilities] = useState<FacilityItem[]>([]);
  const [bookings, setBookings] = useState<BookingItem[]>([]);
  const [announcements, setAnnouncements] = useState<AnnouncementItem[]>([]);
  const [requests, setRequests] = useState<CustomServiceRequestItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedFacility, setSelectedFacility] = useState<FacilityItem | null>(null);
  const [selectedDate, setSelectedDate] = useState(todayInputValue());
  const [selectedTimeSlot, setSelectedTimeSlot] = useState(TIME_SLOTS[0]);
  const [selectedPlan, setSelectedPlan] = useState<"monthly" | "yearly">("monthly");
  const [selectedSlotCode, setSelectedSlotCode] = useState<string>("");
  const [isSubmittingBooking, setIsSubmittingBooking] = useState(false);
  const [isRequestModalOpen, setIsRequestModalOpen] = useState(false);
  const [requestForm, setRequestForm] = useState(initialRequestForm);
  const [isSubmittingRequest, setIsSubmittingRequest] = useState(false);

  useEffect(() => {
    if (session?.role === "resident") {
      setRequestForm((current) => ({ ...current, zone: session.unitNumber ?? "" }));
      void loadData();
    } else {
      setIsLoading(false);
      setError("Please sign in as a resident to use service bookings.");
    }
  }, [session?.id, session?.role, session?.unitNumber]);

  const activeBookings = bookings.filter((booking) => !booking.status.toLowerCase().includes("cancel"));
  const confirmedBookings = bookings.filter((booking) => booking.status.toLowerCase().includes("confirm"));
  const residentServices = useMemo(
    () => facilities.filter((facility) => facility.status.toLowerCase() !== "retired"),
    [facilities],
  );

  return (
    <Layout title="Resident Services" role="resident">
      <div className="p-4">
        <div className="mb-6 flex items-center justify-between rounded-2xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-800 dark:bg-slate-900">
          <div>
            <h2 className="text-lg font-bold">Bookings, services, and announcements</h2>
            <p className="text-xs font-medium text-slate-500 dark:text-slate-400">React is now using the same resident service flow family as Flutter.</p>
          </div>
          <button
            onClick={() => void loadData()}
            className="inline-flex items-center gap-2 rounded-xl border border-slate-200 px-3 py-2 text-sm font-bold text-slate-700 dark:border-slate-700 dark:text-slate-200"
          >
            <RefreshCw className="h-4 w-4" />
            Refresh
          </button>
        </div>

        <section className="mb-6 grid grid-cols-2 gap-4">
          <StatCard label="Active Bookings" value={activeBookings.length} note={`${bookings.length} reservations`} icon={CalendarDays} tone="text-[#137fec] bg-[#137fec]/10" />
          <StatCard label="Confirmed Slots" value={confirmedBookings.length} note="Ready to use" icon={CheckCircle2} tone="text-amber-600 bg-amber-100" />
        </section>

        <div className="mb-4 rounded-2xl border border-[#137fec]/15 bg-[#137fec]/5 p-4 text-sm text-slate-600 dark:text-slate-300">
          Use the cards below to create facility bookings, parking subscriptions, and custom in-unit service requests just like the Flutter resident app.
        </div>

        <div className="mb-6 rounded-2xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-800 dark:bg-slate-900">
          <div className="mb-3 flex items-start gap-3">
            <div className="rounded-xl bg-orange-100 p-3 text-orange-600">
              <HandPlatter className="h-5 w-5" />
            </div>
            <div className="min-w-0 flex-1">
              <h3 className="text-sm font-bold">Custom Service Request</h3>
              <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">Ask for any in-unit service that is not listed in the standard services below.</p>
            </div>
          </div>
          <button
            onClick={() => setIsRequestModalOpen(true)}
            className="inline-flex items-center gap-2 rounded-xl bg-[#137fec] px-4 py-3 text-sm font-bold text-white"
          >
            <Sparkles className="h-4 w-4" />
            Request Custom Service
          </button>
        </div>

        {isLoading ? (
          <LoadingBlock />
        ) : error ? (
          <ErrorBlock message={error} />
        ) : (
          <>
            <section className="mb-6">
              <h3 className="mb-3 text-sm font-bold uppercase tracking-widest text-slate-400">Resident Services</h3>
              <div className="space-y-3">
                {residentServices.map((facility) => (
                  <button
                    key={facility.id}
                    onClick={() => openBookingModal(facility)}
                    className="w-full rounded-2xl border border-slate-200 bg-white p-4 text-left shadow-sm transition-all hover:border-[#137fec] dark:border-slate-800 dark:bg-slate-900"
                  >
                    <div className="flex items-start justify-between gap-3">
                      <div>
                        <div className="flex items-center gap-2">
                          <span className="rounded-xl bg-slate-100 px-3 py-2 text-[11px] font-bold uppercase tracking-widest text-slate-600 dark:bg-slate-800 dark:text-slate-300">
                            {facility.bookingMode === "parking" ? "Parking" : "Service"}
                          </span>
                          <span className={`rounded-full px-2 py-1 text-[10px] font-bold uppercase ${facility.status.toLowerCase() === "operational" ? "bg-emerald-100 text-emerald-600" : "bg-amber-100 text-amber-600"}`}>
                            {facility.status}
                          </span>
                        </div>
                        <h4 className="mt-3 text-sm font-bold text-slate-900 dark:text-slate-100">{facility.name}</h4>
                        <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">{facility.area ?? "Building service"} · Health {facility.health}%</p>
                        <p className="mt-2 text-xs font-semibold text-[#137fec]">{priceLabel(facility)}</p>
                      </div>
                      {facility.bookingMode === "parking" ? <Car className="h-5 w-5 text-slate-400" /> : <CalendarDays className="h-5 w-5 text-slate-400" />}
                    </div>
                  </button>
                ))}
              </div>
            </section>

            <section className="mb-6">
              <h3 className="mb-3 text-sm font-bold uppercase tracking-widest text-slate-400">My Bookings</h3>
              <div className="space-y-3">
                {bookings.length === 0 ? (
                  <EmptyBlock text="No reservations yet." />
                ) : (
                  bookings.map((booking) => (
                    <div key={booking.id} className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-800 dark:bg-slate-900">
                      <div className="flex items-start justify-between gap-3">
                        <div>
                          <h4 className="text-sm font-bold">{booking.title}</h4>
                          <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">{booking.facilityName}</p>
                          <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">{formatDate(booking.bookingDate)} · {booking.timeSlot}</p>
                          {booking.slotCode && <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">Slot {booking.slotCode}</p>}
                        </div>
                        <div className="text-right">
                          <span className="rounded-full bg-slate-100 px-2 py-1 text-[10px] font-bold uppercase tracking-widest text-slate-600 dark:bg-slate-800 dark:text-slate-300">
                            {booking.status}
                          </span>
                          <p className="mt-3 text-sm font-bold">{formatCurrency(booking.amount)}</p>
                        </div>
                      </div>
                    </div>
                  ))
                )}
              </div>
            </section>

            <section className="mb-6">
              <h3 className="mb-3 text-sm font-bold uppercase tracking-widest text-slate-400">My Custom Requests</h3>
              <div className="space-y-3">
                {requests.length === 0 ? (
                  <EmptyBlock text="No custom service requests yet." />
                ) : (
                  requests.map((request) => {
                    const canRespond = request.status.toLowerCase().includes("quoted");
                    return (
                      <div key={request.id} className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-800 dark:bg-slate-900">
                        <div className="flex items-start justify-between gap-3">
                          <div>
                            <h4 className="text-sm font-bold">{request.title}</h4>
                            <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">{request.unitNumber} · {request.zone}</p>
                            <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">{formatDateTime(request.createdAt)}</p>
                          </div>
                          <span className="rounded-full bg-slate-100 px-2 py-1 text-[10px] font-bold uppercase tracking-widest text-slate-600 dark:bg-slate-800 dark:text-slate-300">
                            {request.status}
                          </span>
                        </div>
                        <p className="mt-3 text-sm text-slate-600 dark:text-slate-300">{request.description}</p>
                        {request.quotedPrice != null && (
                          <div className="mt-3 rounded-xl bg-[#137fec]/5 px-3 py-3 text-sm text-slate-700 dark:text-slate-200">
                            <p className="font-bold text-[#137fec]">{formatCurrency(request.quotedPrice)}</p>
                            {request.quoteNote && <p className="mt-1 text-xs">{request.quoteNote}</p>}
                          </div>
                        )}
                        {canRespond && (
                          <div className="mt-4 flex gap-2">
                            <button
                              onClick={() => void respondToQuote(request.id, "confirm")}
                              className="flex-1 rounded-xl bg-[#137fec] px-4 py-2.5 text-sm font-bold text-white"
                            >
                              Confirm Quote
                            </button>
                            <button
                              onClick={() => void respondToQuote(request.id, "reject")}
                              className="flex-1 rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-bold text-slate-700 dark:border-slate-700 dark:text-slate-200"
                            >
                              Reject Quote
                            </button>
                          </div>
                        )}
                      </div>
                    );
                  })
                )}
              </div>
            </section>

            <section>
              <h3 className="mb-3 text-sm font-bold uppercase tracking-widest text-slate-400">Announcements</h3>
              <div className="space-y-3">
                {announcements.length === 0 ? (
                  <EmptyBlock text="No building announcements yet." />
                ) : (
                  announcements.map((announcement) => (
                    <div key={announcement.id} className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-800 dark:bg-slate-900">
                      <div className="flex gap-3">
                        <div className="rounded-xl bg-[#137fec]/10 p-3 text-[#137fec]">
                          <Bell className="h-5 w-5" />
                        </div>
                        <div>
                          <div className="flex items-center gap-2">
                            <h4 className="text-sm font-bold">{announcement.title}</h4>
                            <span className="rounded-full bg-slate-100 px-2 py-1 text-[10px] font-bold uppercase tracking-widest text-slate-600 dark:bg-slate-800 dark:text-slate-300">
                              {announcement.category}
                            </span>
                          </div>
                          <p className="mt-2 text-sm text-slate-600 dark:text-slate-300">{announcement.content}</p>
                          <p className="mt-3 text-xs text-slate-400">{formatDateTime(announcement.createdAt)}</p>
                        </div>
                      </div>
                    </div>
                  ))
                )}
              </div>
            </section>
          </>
        )}
      </div>

      <AnimatePresence>
        {selectedFacility && (
          <>
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setSelectedFacility(null)}
              className="fixed inset-0 z-[100] bg-black/60 backdrop-blur-sm"
            />
            <motion.div
              initial={{ opacity: 0, y: 40 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: 40 }}
              className="fixed inset-x-4 bottom-0 z-[110] mx-auto rounded-t-[32px] bg-white p-6 pb-10 shadow-2xl dark:bg-[#101922] sm:max-w-xl lg:inset-x-0 lg:top-1/2 lg:bottom-auto lg:w-full lg:max-w-2xl lg:-translate-y-1/2 lg:rounded-[32px] lg:pb-6"
            >
              <div className="mb-6 flex items-center justify-between">
                <div>
                  <h3 className="text-lg font-bold">{selectedFacility.name}</h3>
                  <p className="text-xs font-medium text-slate-500 dark:text-slate-400">{selectedFacility.area ?? "Building service"} · {priceLabel(selectedFacility)}</p>
                </div>
                <button onClick={() => setSelectedFacility(null)} className="rounded-full p-2 hover:bg-slate-100 dark:hover:bg-slate-800">
                  <X className="h-5 w-5 text-slate-400" />
                </button>
              </div>

              <div className="space-y-4">
                <input
                  type="date"
                  value={selectedDate}
                  onChange={(event) => setSelectedDate(event.target.value)}
                  className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900"
                />

                {selectedFacility.bookingMode === "parking" ? (
                  <>
                    <div className="grid grid-cols-2 gap-3">
                      <button
                        onClick={() => setSelectedPlan("monthly")}
                        className={`rounded-2xl border px-4 py-3 text-left text-sm font-bold ${selectedPlan === "monthly" ? "border-[#137fec] bg-[#137fec]/5 text-[#137fec]" : "border-slate-200 dark:border-slate-700"}`}
                      >
                        Monthly
                        <p className="mt-1 text-xs font-medium text-inherit">{formatCurrency(selectedFacility.monthlyPrice)}</p>
                      </button>
                      <button
                        onClick={() => setSelectedPlan("yearly")}
                        className={`rounded-2xl border px-4 py-3 text-left text-sm font-bold ${selectedPlan === "yearly" ? "border-[#137fec] bg-[#137fec]/5 text-[#137fec]" : "border-slate-200 dark:border-slate-700"}`}
                      >
                        Yearly
                        <p className="mt-1 text-xs font-medium text-inherit">{formatCurrency(selectedFacility.yearlyPrice)}</p>
                      </button>
                    </div>

                    <div className="grid grid-cols-3 gap-2 sm:grid-cols-4">
                      {selectedFacility.slotCodes.map((slot) => {
                        const occupied = selectedFacility.occupiedSlotCodes.includes(slot);
                        return (
                          <button
                            key={slot}
                            disabled={occupied}
                            onClick={() => setSelectedSlotCode(slot)}
                            className={`rounded-xl px-3 py-3 text-sm font-bold ${occupied ? "cursor-not-allowed bg-slate-100 text-slate-400 dark:bg-slate-800" : selectedSlotCode === slot ? "bg-[#137fec] text-white" : "border border-slate-200 dark:border-slate-700"}`}
                          >
                            {slot}
                          </button>
                        );
                      })}
                    </div>
                  </>
                ) : (
                  <div className="space-y-3">
                    {TIME_SLOTS.map((slot) => (
                      <button
                        key={slot}
                        onClick={() => setSelectedTimeSlot(slot)}
                        className={`flex w-full items-center justify-between rounded-2xl border px-4 py-3 text-sm font-bold ${selectedTimeSlot === slot ? "border-[#137fec] bg-[#137fec]/5 text-[#137fec]" : "border-slate-200 text-slate-700 dark:border-slate-700 dark:text-slate-200"}`}
                      >
                        <span className="inline-flex items-center gap-2">
                          <Clock3 className="h-4 w-4" />
                          {slot}
                        </span>
                        {selectedTimeSlot === slot && <CheckCircle2 className="h-5 w-5" />}
                      </button>
                    ))}
                  </div>
                )}
              </div>

              <button
                disabled={isSubmittingBooking || !canSubmitBooking(selectedFacility, selectedSlotCode)}
                onClick={() => void submitBooking()}
                className="mt-6 w-full rounded-2xl bg-[#137fec] px-4 py-4 text-sm font-bold text-white disabled:opacity-50"
              >
                {isSubmittingBooking ? "Creating booking..." : "Confirm Booking"}
              </button>
            </motion.div>
          </>
        )}
      </AnimatePresence>

      <AnimatePresence>
        {isRequestModalOpen && (
          <>
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setIsRequestModalOpen(false)}
              className="fixed inset-0 z-[100] bg-black/60 backdrop-blur-sm"
            />
            <motion.div
              initial={{ opacity: 0, y: 40 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: 40 }}
              className="fixed inset-x-4 bottom-0 z-[110] mx-auto rounded-t-[32px] bg-white p-6 pb-10 shadow-2xl dark:bg-[#101922] sm:max-w-xl lg:inset-x-0 lg:top-1/2 lg:bottom-auto lg:w-full lg:max-w-2xl lg:-translate-y-1/2 lg:rounded-[32px] lg:pb-6"
            >
              <div className="mb-6 flex items-center justify-between">
                <div>
                  <h3 className="text-lg font-bold">Request Custom Service</h3>
                  <p className="text-xs font-medium text-slate-500 dark:text-slate-400">Resident request goes to operations for assignment and quote.</p>
                </div>
                <button onClick={() => setIsRequestModalOpen(false)} className="rounded-full p-2 hover:bg-slate-100 dark:hover:bg-slate-800">
                  <X className="h-5 w-5 text-slate-400" />
                </button>
              </div>

              <div className="space-y-4">
                <input value={requestForm.title} onChange={(event) => setRequestForm((current) => ({ ...current, title: event.target.value }))} placeholder="Service title" className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
                <input value={requestForm.zone} onChange={(event) => setRequestForm((current) => ({ ...current, zone: event.target.value }))} placeholder="Unit / zone" className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
                <input value={requestForm.preferredSchedule} onChange={(event) => setRequestForm((current) => ({ ...current, preferredSchedule: event.target.value }))} placeholder="Preferred schedule" className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
                <textarea value={requestForm.description} onChange={(event) => setRequestForm((current) => ({ ...current, description: event.target.value }))} placeholder="Describe your request" className="min-h-28 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm dark:border-slate-800 dark:bg-slate-900" />
              </div>

              <button
                disabled={isSubmittingRequest}
                onClick={() => void submitCustomRequest()}
                className="mt-6 w-full rounded-2xl bg-[#137fec] px-4 py-4 text-sm font-bold text-white disabled:opacity-50"
              >
                {isSubmittingRequest ? "Submitting..." : "Submit Request"}
              </button>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </Layout>
  );

  function openBookingModal(facility: FacilityItem) {
    setSelectedFacility(facility);
    setSelectedDate(todayInputValue());
    setSelectedTimeSlot(TIME_SLOTS[0]);
    setSelectedPlan("monthly");
    setSelectedSlotCode("");
  }

  async function loadData() {
    if (!session) return;
    setIsLoading(true);
    setError(null);
    try {
      const [facilityData, bookingData, announcementData, requestData] = await Promise.all([
        apiRequest<FacilitiesResponse>(`${FACILITY_API_BASE}/facilities`),
        apiRequest<BookingItem[]>(`${FACILITY_API_BASE}/bookings/resident/${session.id}`),
        apiRequest<AnnouncementItem[]>(`${FACILITY_API_BASE}/announcements`),
        apiRequest<CustomServiceRequestItem[]>(`${OPERATIONS_API_BASE}/custom-service-requests/resident/${session.id}`),
      ]);
      setFacilities(facilityData.facilities);
      setBookings(bookingData);
      setAnnouncements(announcementData);
      setRequests(requestData);
    } catch (loadError) {
      const message = loadError instanceof Error ? loadError.message : "Unable to load resident services.";
      setError(message);
      showToast(message, "error");
    } finally {
      setIsLoading(false);
    }
  }

  async function submitBooking() {
    if (!session || !selectedFacility) return;
    if (!canSubmitBooking(selectedFacility, selectedSlotCode)) {
      showToast("Choose an available parking slot first.", "info");
      return;
    }

    setIsSubmittingBooking(true);
    try {
      const timeSlot = selectedFacility.bookingMode === "parking"
        ? selectedPlan === "yearly"
          ? "Yearly Subscription"
          : "Monthly Subscription"
        : selectedTimeSlot;
      const amount = bookingPrice(selectedFacility, selectedPlan);

      await apiRequest<BookingItem>(`${FACILITY_API_BASE}/bookings/resident/${session.id}`, {
        method: "POST",
        body: JSON.stringify({
          facilityId: selectedFacility.id,
          bookingDate: selectedDate,
          timeSlot,
          slotCode: selectedFacility.bookingMode === "parking" ? selectedSlotCode : null,
          planType: selectedFacility.bookingMode === "parking" ? selectedPlan : null,
        }),
      });

      if (amount > 0) {
        await apiRequest<CreateInvoiceResponse>(`${BILLING_API_BASE}/billing/invoices`, {
          method: "POST",
          body: JSON.stringify({
            residentId: session.id,
            residentName: session.fullName,
            residentEmail: session.email,
            unitNumber: session.unitNumber ?? "N/A",
            title: `${selectedFacility.name} Booking`,
            category: selectedFacility.bookingMode === "parking" ? "parking" : "service",
            amount,
            dueDate: selectedDate,
            description: selectedFacility.bookingMode === "parking"
              ? `${selectedPlan} parking booking for slot ${selectedSlotCode}`
              : `${selectedFacility.name} booking for ${selectedTimeSlot}`,
          }),
        });
      }

      setSelectedFacility(null);
      await loadData();
      showToast("Booking created successfully.", "success");
    } catch (submitError) {
      showToast(submitError instanceof Error ? submitError.message : "Unable to create booking.", "error");
    } finally {
      setIsSubmittingBooking(false);
    }
  }

  async function submitCustomRequest() {
    if (!session) return;
    if (!requestForm.title.trim() || !requestForm.description.trim() || !requestForm.zone.trim()) {
      showToast("Fill in title, description, and zone before submitting.", "error");
      return;
    }

    setIsSubmittingRequest(true);
    try {
      await apiRequest<CustomServiceRequestItem>(`${OPERATIONS_API_BASE}/custom-service-requests`, {
        method: "POST",
        body: JSON.stringify({
          residentId: session.id,
          residentName: session.fullName,
          unitNumber: session.unitNumber ?? "N/A",
          title: requestForm.title.trim(),
          description: requestForm.description.trim(),
          zone: requestForm.zone.trim(),
          preferredSchedule: requestForm.preferredSchedule.trim() || null,
        }),
      });
      setIsRequestModalOpen(false);
      setRequestForm({ ...initialRequestForm, zone: session.unitNumber ?? "" });
      await loadData();
      showToast("Custom service request submitted.", "success");
    } catch (submitError) {
      showToast(submitError instanceof Error ? submitError.message : "Unable to submit request.", "error");
    } finally {
      setIsSubmittingRequest(false);
    }
  }

  async function respondToQuote(requestId: number, decision: "confirm" | "reject") {
    try {
      await apiRequest<CustomServiceRequestItem>(`${OPERATIONS_API_BASE}/custom-service-requests/${requestId}/resident-decision`, {
        method: "POST",
        body: JSON.stringify({ decision, note: null }),
      });
      await loadData();
      showToast(decision === "confirm" ? "Custom service quote confirmed." : "Quote rejected.", "success");
    } catch (submitError) {
      showToast(submitError instanceof Error ? submitError.message : "Unable to respond to quote.", "error");
    }
  }
}

function StatCard({
  label,
  value,
  note,
  icon: Icon,
  tone,
}: {
  label: string;
  value: number;
  note: string;
  icon: typeof CalendarDays;
  tone: string;
}) {
  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-800 dark:bg-slate-900">
      <div className={`mb-3 inline-flex rounded-xl p-3 ${tone}`}>
        <Icon className="h-5 w-5" />
      </div>
      <p className="text-xs font-bold uppercase tracking-widest text-slate-400">{label}</p>
      <p className="mt-2 text-3xl font-extrabold">{value}</p>
      <p className="mt-1 text-xs font-medium text-slate-500 dark:text-slate-400">{note}</p>
    </div>
  );
}

function LoadingBlock() {
  return (
    <div className="rounded-2xl border border-dashed border-slate-300 bg-white p-6 text-center text-sm text-slate-500 dark:border-slate-700 dark:bg-slate-900">
      Loading services and bookings...
    </div>
  );
}

function ErrorBlock({ message }: { message: string }) {
  return (
    <div className="rounded-2xl border border-rose-200 bg-rose-50 p-4 text-sm text-rose-700 dark:border-rose-900/40 dark:bg-rose-900/10 dark:text-rose-300">
      {message}
    </div>
  );
}

function EmptyBlock({ text }: { text: string }) {
  return (
    <div className="rounded-2xl border border-dashed border-slate-300 bg-white p-6 text-center text-sm text-slate-500 dark:border-slate-700 dark:bg-slate-900">
      {text}
    </div>
  );
}

function priceLabel(facility: FacilityItem) {
  if (facility.bookingMode === "parking") {
    return `Monthly ${formatCurrency(facility.monthlyPrice)} · Yearly ${formatCurrency(facility.yearlyPrice)}`;
  }
  return facility.oneTimePrice > 0 ? `Per booking ${formatCurrency(facility.oneTimePrice)}` : "Free booking";
}

function bookingPrice(facility: FacilityItem, selectedPlan: "monthly" | "yearly") {
  if (facility.bookingMode === "parking") {
    return selectedPlan === "yearly" ? facility.yearlyPrice : facility.monthlyPrice;
  }
  return facility.oneTimePrice;
}

function canSubmitBooking(facility: FacilityItem, selectedSlotCode: string) {
  return facility.bookingMode !== "parking" || Boolean(selectedSlotCode);
}

function formatCurrency(value: number | null) {
  return new Intl.NumberFormat("vi-VN", {
    style: "currency",
    currency: "VND",
    maximumFractionDigits: 0,
  }).format(value ?? 0);
}

function formatDate(value: string) {
  return new Date(value).toLocaleDateString("en-US", { month: "short", day: "2-digit", year: "numeric" });
}

function formatDateTime(value: string) {
  return new Date(value).toLocaleString("en-US", {
    month: "short",
    day: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

function todayInputValue() {
  return new Date().toISOString().slice(0, 10);
}
