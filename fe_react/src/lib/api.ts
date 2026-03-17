export const AUTH_API_BASE = import.meta.env.VITE_AUTH_API_BASE ?? "http://localhost:8081/api";
export const BILLING_API_BASE = import.meta.env.VITE_BILLING_API_BASE ?? "http://localhost:8082/api";
export const FACILITY_API_BASE = import.meta.env.VITE_FACILITY_API_BASE ?? "http://localhost:8083/api";
export const SECURITY_API_BASE = import.meta.env.VITE_SECURITY_API_BASE ?? "http://localhost:8084/api/security";
export const OPERATIONS_API_BASE = import.meta.env.VITE_OPERATIONS_API_BASE ?? "http://localhost:8085/api/operations";

const SESSION_KEY = "mss-session";

export class ApiError extends Error {
  statusCode?: number;

  constructor(message: string, statusCode?: number) {
    super(message);
    this.name = "ApiError";
    this.statusCode = statusCode;
  }
}

export interface SessionUser {
  id: number;
  fullName: string;
  email: string;
  role: "admin" | "resident" | "staff";
  unitNumber: string | null;
  tower: string | null;
  avatarUrl: string | null;
}

export interface ResidentItem {
  id: number;
  fullName: string;
  unitNumber: string;
  tower: string;
  leaseStatus: string;
  email: string;
  status: string;
  avatarUrl: string | null;
}

export interface ActivityItem {
  id: number;
  type: string;
  title: string;
  description: string;
  createdAt: string;
}

export interface StaffItem {
  id: number;
  fullName: string;
  role: string;
  shift: string;
  email: string;
  phone: string;
  status: string;
  avatarUrl: string | null;
}

export interface AccountStats {
  billCount: number;
  guestCount: number;
  openIssueCount: number;
}

export interface AccountResponse {
  user: SessionUser;
  stats: AccountStats;
}

export interface BillItem {
  id: number;
  residentId: number;
  residentName: string;
  residentEmail: string | null;
  unitNumber: string;
  title: string;
  category: string;
  amount: number;
  dueDate: string;
  status: string;
  description: string | null;
  paymentLinkId: string | null;
  payosOrderCode: number | null;
  checkoutUrl: string | null;
}

export interface BillingOverview {
  summary: {
    totalInvoiced: number;
    totalOutstanding: number;
    activeInvoices: number;
  };
  invoices: BillItem[];
}

export interface FacilityLogItem {
  id: number;
  note: string;
  createdByName: string;
  createdAt: string;
  markOperational: boolean;
}

export interface FacilityItem {
  id: number;
  name: string;
  area: string | null;
  status: string;
  health: number;
  lastCheckAt: string | null;
  icon: string | null;
  description: string | null;
  serviceType: string;
  bookingMode: string;
  oneTimePrice: number;
  monthlyPrice: number;
  yearlyPrice: number;
  slotCodes: string[];
  occupiedSlotCodes: string[];
  logs: FacilityLogItem[];
}

export interface FacilitiesResponse {
  facilities: FacilityItem[];
}

export interface BookingItem {
  id: number;
  facilityId: number;
  facilityName: string;
  title: string;
  bookingDate: string;
  timeSlot: string;
  status: string;
  slotCode: string | null;
  planType: string | null;
  amount: number;
}

export interface AnnouncementItem {
  id: number;
  title: string;
  content: string;
  category: string;
  createdAt: string;
}

export interface CustomServiceRequestItem {
  id: number;
  residentId: number;
  residentName: string;
  unitNumber: string;
  title: string;
  description: string;
  zone: string;
  preferredSchedule: string | null;
  status: string;
  assignedStaffId: number | null;
  assignedStaffName: string | null;
  quotedPrice: number | null;
  quoteNote: string | null;
  residentDecisionNote: string | null;
  createdAt: string;
}

export interface InvoiceEmailResponse {
  invoiceId: number;
  recipient: string | null;
  sent: boolean;
  message: string;
}

export interface CreateInvoiceResponse {
  invoice: BillItem;
  email: InvoiceEmailResponse;
}

export interface PaymentSession {
  invoiceId: number;
  orderCode: number;
  paymentLinkId: string;
  checkoutUrl: string;
  status: string;
}

export async function apiRequest<T>(url: string, init?: RequestInit): Promise<T> {
  const response = await fetch(url, {
    ...init,
    headers: {
      "Content-Type": "application/json",
      ...(init?.headers ?? {}),
    },
  });

  if (!response.ok) {
    const errorText = await response.text();
    let message = `Request failed with status ${response.status}`;
    if (errorText) {
      try {
        const parsed = JSON.parse(errorText) as { message?: string; error?: string };
        message = parsed.message ?? parsed.error ?? errorText;
      } catch {
        message = errorText;
      }
    }
    throw new ApiError(message, response.status);
  }

  if (response.status === 204) {
    return undefined as T;
  }

  const contentType = response.headers.get("content-type") ?? "";
  if (!contentType.includes("application/json")) {
    return undefined as T;
  }

  return response.json() as Promise<T>;
}

export function saveSession(user: SessionUser) {
  localStorage.setItem(SESSION_KEY, JSON.stringify(user));
}

export function getSession(): SessionUser | null {
  const raw = localStorage.getItem(SESSION_KEY);
  if (!raw) {
    return null;
  }

  try {
    return JSON.parse(raw) as SessionUser;
  } catch {
    localStorage.removeItem(SESSION_KEY);
    return null;
  }
}

export function clearSession() {
  localStorage.removeItem(SESSION_KEY);
}
