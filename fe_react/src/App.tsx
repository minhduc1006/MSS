import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import Landing from "./pages/Landing";
import Login from "./pages/Login";
import ResetPassword from "./pages/ResetPassword";
import ResetPasswordNew from "./pages/ResetPasswordNew";
import AdminDashboard from "./pages/AdminDashboard";
import AdminActivity from "./pages/AdminActivity";
import ResidentDashboard from "./pages/ResidentDashboard";
import ResidentBills from "./pages/ResidentBills";
import ResidentBookings from "./pages/ResidentBookings";
import ResidentSecurity from "./pages/ResidentSecurity";
import ResidentAccount from "./pages/ResidentAccount";
import ResidentList from "./pages/ResidentList";
import Billing from "./pages/Billing";
import AdminLeasing from "./pages/AdminLeasing";
import AdminOperationsHub from "./pages/AdminOperationsHub";
import Security from "./pages/Security";
import Facilities from "./pages/Facilities";
import Apartment from "./pages/Apartment";
import StaffList from "./pages/StaffList";
import StaffDashboard from "./pages/StaffDashboard";
import StaffFacilities from "./pages/StaffFacilities";
import StaffSecurity from "./pages/StaffSecurity";
import StaffSettings from "./pages/StaffSettings";
import { ToastProvider } from "./components/Toast";

export default function App() {
  return (
    <ToastProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<Landing />} />
          <Route path="/login" element={<Login />} />
          <Route path="/reset-password" element={<ResetPassword />} />
          <Route path="/reset-password/new" element={<ResetPasswordNew />} />
          <Route path="/admin" element={<AdminDashboard />} />
          <Route path="/admin/activity" element={<AdminActivity />} />
          <Route path="/admin/residents" element={<ResidentList />} />
          <Route path="/admin/staff" element={<StaffList />} />
          <Route path="/admin/billing" element={<Billing />} />
          <Route path="/admin/leasing" element={<AdminLeasing />} />
          <Route path="/admin/ops" element={<AdminOperationsHub />} />
          <Route path="/admin/facilities" element={<Facilities />} />
          <Route path="/admin/apartment" element={<Apartment />} />
          <Route path="/admin/security" element={<Security />} />
          <Route path="/resident" element={<ResidentDashboard />} />
          <Route path="/resident/bills" element={<ResidentBills />} />
          <Route path="/resident/bookings" element={<ResidentBookings />} />
          <Route path="/resident/security" element={<ResidentSecurity />} />
          <Route path="/resident/account" element={<ResidentAccount />} />
          <Route path="/staff" element={<StaffDashboard />} />
          <Route path="/staff/facilities" element={<StaffFacilities />} />
          <Route path="/staff/security" element={<StaffSecurity />} />
          <Route path="/staff/settings" element={<StaffSettings />} />
          {/* Fallback */}
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </ToastProvider>
  );
}
