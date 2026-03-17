import 'package:flutter/material.dart';

enum UserRole { resident, staff, admin }

class NavItem {
  final String label;
  final String route;
  final int index;
  final IconData icon;

  const NavItem({
    required this.label,
    required this.route,
    required this.index,
    required this.icon,
  });
}

class SessionUser {
  final int id;
  final String fullName;
  final String email;
  final UserRole role;
  final String? unitNumber;
  final String? tower;
  final String? avatarUrl;

  const SessionUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.unitNumber,
    this.tower,
    this.avatarUrl,
  });
}

class ActivityItem {
  final int? id;
  final String title;
  final String desc;
  final String time;
  final String kind;

  const ActivityItem({this.id, required this.title, required this.desc, required this.time, required this.kind});
}

class ResidentItem {
  final int? id;
  final String name;
  final String unit;
  final String lease;
  final String email;
  final String status;

  const ResidentItem({this.id, required this.name, required this.unit, required this.lease, required this.email, required this.status});
}

class StaffItem {
  final int? id;
  final String name;
  final String role;
  final String shift;
  final String email;
  final String phone;
  final String status;

  const StaffItem({this.id, required this.name, required this.role, required this.shift, required this.email, required this.phone, required this.status});
}

class AdminContactItem {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String status;

  const AdminContactItem({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
  });
}

class InvoiceItem {
  final int? id;
  final int? residentId;
  final String unit;
  final String resident;
  final double amount;
  final String status;
  final String date;
  final String? title;
  final String? category;
  final String? description;

  const InvoiceItem({
    this.id,
    this.residentId,
    required this.unit,
    required this.resident,
    required this.amount,
    required this.status,
    required this.date,
    this.title,
    this.category,
    this.description,
  });
}

class BillItem {
  final int? id;
  final String title;
  final double amount;
  final String date;
  final String status;
  final String type;
  final String? description;
  final int? residentId;
  final String? residentName;
  final String? unitNumber;

  const BillItem({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.status,
    required this.type,
    this.description,
    this.residentId,
    this.residentName,
    this.unitNumber,
  });
}

class SecurityLog {
  final int? id;
  final String event;
  final String visitor;
  final String time;
  final String status;
  final String? audience;

  const SecurityLog({this.id, required this.event, required this.visitor, required this.time, required this.status, this.audience});
}

class IncidentItem {
  final int? id;
  final String title;
  final String zone;
  final String time;
  final String status;
  final String desc;
  final String? severity;
  final String? assignedStaffName;

  const IncidentItem({
    this.id,
    required this.title,
    required this.zone,
    required this.time,
    required this.status,
    required this.desc,
    this.severity,
    this.assignedStaffName,
  });
}

class FacilityStatusItem {
  final String name;
  final String status;
  final String icon;

  const FacilityStatusItem({required this.name, required this.status, required this.icon});
}

class MaintenanceFacility {
  final int? id;
  final String name;
  final String status;
  final String lastCheck;
  final int health;
  final List<String> logs;
  final String? area;
  final String? icon;
  final String? description;
  final String serviceType;
  final String bookingMode;
  final double oneTimePrice;
  final double monthlyPrice;
  final double yearlyPrice;
  final List<String> slotCodes;
  final List<String> occupiedSlotCodes;

  const MaintenanceFacility({
    this.id,
    required this.name,
    required this.status,
    required this.lastCheck,
    required this.health,
    required this.logs,
    this.area,
    this.icon,
    this.description,
    this.serviceType = 'shared',
    this.bookingMode = 'timeslot',
    this.oneTimePrice = 0,
    this.monthlyPrice = 0,
    this.yearlyPrice = 0,
    this.slotCodes = const [],
    this.occupiedSlotCodes = const [],
  });
}

class BookingItem {
  final int? id;
  final int? facilityId;
  final String title;
  final String time;
  final String location;
  final String status;
  final String? slotCode;
  final String? planType;
  final double amount;

  const BookingItem({
    this.id,
    this.facilityId,
    required this.title,
    required this.time,
    required this.location,
    required this.status,
    this.slotCode,
    this.planType,
    this.amount = 0,
  });
}

class TaskItem {
  final int? id;
  final int? sourceId;
  final String? sourceType;
  final String? assignedStaffName;
  final String title;
  final String zone;
  final String priority;
  final String status;
  final String? category;

  const TaskItem({
    this.id,
    this.sourceId,
    this.sourceType,
    this.assignedStaffName,
    required this.title,
    required this.zone,
    required this.priority,
    required this.status,
    this.category,
  });
}

class CustomServiceRequestItem {
  final int? id;
  final int residentId;
  final String residentName;
  final String unitNumber;
  final String title;
  final String description;
  final String zone;
  final String? preferredSchedule;
  final String status;
  final int? assignedStaffId;
  final String? assignedStaffName;
  final double? quotedPrice;
  final String? quoteNote;
  final String? residentDecisionNote;
  final String createdAt;

  const CustomServiceRequestItem({
    this.id,
    required this.residentId,
    required this.residentName,
    required this.unitNumber,
    required this.title,
    required this.description,
    required this.zone,
    this.preferredSchedule,
    required this.status,
    this.assignedStaffId,
    this.assignedStaffName,
    this.quotedPrice,
    this.quoteNote,
    this.residentDecisionNote,
    required this.createdAt,
  });
}

class BillingOverviewData {
  final double totalInvoiced;
  final double totalOutstanding;
  final int activeInvoices;
  final List<InvoiceItem> invoices;

  const BillingOverviewData({
    required this.totalInvoiced,
    required this.totalOutstanding,
    required this.activeInvoices,
    required this.invoices,
  });
}

class ApartmentUnitItem {
  final int? id;
  final String unitNumber;
  final String tower;
  final String unitType;
  final String occupancyStatus;
  final String? residentName;
  final double balance;

  const ApartmentUnitItem({
    this.id,
    required this.unitNumber,
    required this.tower,
    required this.unitType,
    required this.occupancyStatus,
    this.residentName,
    required this.balance,
  });
}

class ApartmentStatsData {
  final int totalUnits;
  final int occupiedUnits;
  final List<ApartmentUnitItem> units;

  const ApartmentStatsData({
    required this.totalUnits,
    required this.occupiedUnits,
    required this.units,
  });
}

class AnnouncementItem {
  final int? id;
  final String title;
  final String content;
  final String category;
  final String createdAt;

  const AnnouncementItem({
    this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.createdAt,
  });
}

class SecurityOverviewData {
  final List<IncidentItem> incidents;
  final List<SecurityLog> recentLogs;

  const SecurityOverviewData({
    required this.incidents,
    required this.recentLogs,
  });
}

class AccountStatsData {
  final int billCount;
  final int guestCount;
  final int openIssueCount;

  const AccountStatsData({
    required this.billCount,
    required this.guestCount,
    required this.openIssueCount,
  });
}

class AccountSummary {
  final SessionUser user;
  final AccountStatsData stats;

  const AccountSummary({
    required this.user,
    required this.stats,
  });
}

class TaskBundleData {
  final int totalTasks;
  final int completedTasks;
  final List<TaskItem> tasks;

  const TaskBundleData({
    required this.totalTasks,
    required this.completedTasks,
    required this.tasks,
  });
}
