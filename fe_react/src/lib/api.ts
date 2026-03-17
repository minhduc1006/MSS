export const AUTH_API_BASE = import.meta.env.VITE_AUTH_API_BASE ?? "http://localhost:8081/api";
export const BILLING_API_BASE = import.meta.env.VITE_BILLING_API_BASE ?? "http://localhost:8082/api";

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
