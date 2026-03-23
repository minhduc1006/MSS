package com.mss.operations.service;

import com.mss.operations.model.ActivityLog;
import com.mss.operations.model.ComplaintTicket;
import com.mss.operations.model.PackageRecord;
import com.mss.operations.model.StaffTask;
import com.mss.operations.model.StaffShift;
import com.mss.operations.repository.ActivityLogRepository;
import com.mss.operations.repository.ComplaintTicketRepository;
import com.mss.operations.repository.PackageRecordRepository;
import com.mss.operations.repository.StaffTaskRepository;
import com.mss.operations.repository.StaffShiftRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Component
public class OperationsSeeder implements CommandLineRunner {
    private final ActivityLogRepository activityRepository;
    private final StaffTaskRepository taskRepository;
    private final PackageRecordRepository packageRecordRepository;
    private final ComplaintTicketRepository complaintTicketRepository;
    private final StaffShiftRepository staffShiftRepository;

    public OperationsSeeder(
        ActivityLogRepository activityRepository,
        StaffTaskRepository taskRepository,
        PackageRecordRepository packageRecordRepository,
        ComplaintTicketRepository complaintTicketRepository,
        StaffShiftRepository staffShiftRepository
    ) {
        this.activityRepository = activityRepository;
        this.taskRepository = taskRepository;
        this.packageRecordRepository = packageRecordRepository;
        this.complaintTicketRepository = complaintTicketRepository;
        this.staffShiftRepository = staffShiftRepository;
    }

    @Override
    public void run(String... args) {
        if (activityRepository.count() == 0) {
            activity("billing", "Billing generated for Unit 402", "Monthly maintenance fee processed.", LocalDateTime.now().minusMinutes(2));
            activity("maintenance", "Maintenance Request: Leak", "Unit 105 reported a kitchen sink leak.", LocalDateTime.now().minusMinutes(45));
            activity("onboarding", "New Resident Onboarded", "John Doe moved into Unit 402.", LocalDateTime.now().minusHours(3));
            task(8L, "Check Fire Extinguishers", "Tower A, Floor 1-10", "High", "Pending", "Safety");
            task(8L, "Lobby Cleaning Supervision", "Main Entrance", "Medium", "In Progress", "Operations");
            task(8L, "Pool Water Quality Test", "Amenity Deck", "Low", "Completed", "Facility");
            task(9L, "Repair Gate Lock", "P2 Parking - Gate 4", "High", "In Progress", "Maintenance");
            task(10L, "Concierge Desk Support", "Main Lobby", "Medium", "Completed", "Guest Service");
        }
        if (packageRecordRepository.count() == 0) {
            packageRecord(2L, "John Doe", "402", "Parcel", "GHN", "Amazon Smart Display", "PKG-402-1001", "Mailroom Shelf A", "Ready for Pickup", "Front Desk", LocalDateTime.now().minusHours(4), null, "Resident notified.");
            packageRecord(4L, "Sarah Jenkins", "115A", "Parcel", "J&T Express", "Office Chair Box", "PKG-115A-2023", "Receiving Bay", "Arrived", "Receiving Clerk", LocalDateTime.now().minusHours(1), null, "Large parcel requires trolley support.");
            packageRecord(null, null, null, "Lost & Found", null, "Silver access card", "LF-203", "Security Office", "Claim Pending", "Security Team", LocalDateTime.now().minusDays(1), null, "Found near Tower B elevator.");
        }
        if (complaintTicketRepository.count() == 0) {
            complaint(2L, "John Doe", "402", "Noise", "Late-night noise from adjacent unit", "Repeated loud music after 11 PM for the past three nights.", "High", "Open", null, null, null, null, null, LocalDateTime.now().minusHours(9), null);
            complaint(4L, "Sarah Jenkins", "115A", "Cleaning", "Trash room needs extra cleaning", "The trash room on Level 1 has odor and needs immediate cleaning.", "Medium", "Resolved", 8L, "David Miller", "Cleaning vendor dispatched and area sanitized.", 5, "Fast response from the team.", LocalDateTime.now().minusDays(2), LocalDateTime.now().minusDays(1));
        }
        if (staffShiftRepository.count() == 0) {
            shift(8L, "David Miller", "Facility Technician", LocalDate.now(), "Day", "Amenity Deck", "07:30", "16:30", "On Duty", "Inspect water systems and resident service requests.");
            shift(9L, "Sarah Connor", "Security Supervisor", LocalDate.now(), "Night", "Main Lobby", "18:00", "06:00", "Scheduled", "Lead gate monitoring and visitor screening.");
            shift(10L, "Robert Wilson", "Concierge", LocalDate.now().plusDays(1), "Swing", "Reception", "12:00", "20:00", "Scheduled", "Cover package handover and help desk desk.");
        }
    }

    private void activity(String type, String title, String description, LocalDateTime at) {
        ActivityLog log = new ActivityLog();
        log.setType(type);
        log.setTitle(title);
        log.setDescription(description);
        log.setCreatedAt(at);
        activityRepository.save(log);
    }

    private void task(Long staffId, String title, String zone, String priority, String status, String category) {
        StaffTask task = new StaffTask();
        task.setAssignedStaffId(staffId);
        task.setAssignedStaffName(staffId == 8L ? "David Miller" : staffId == 9L ? "Sarah Connor" : "Robert Wilson");
        task.setTitle(title);
        task.setZone(zone);
        task.setPriority(priority);
        task.setStatus(status);
        task.setCategory(category);
        taskRepository.save(task);
    }

    private void packageRecord(
        Long residentId,
        String residentName,
        String unitNumber,
        String recordType,
        String carrier,
        String itemName,
        String trackingCode,
        String location,
        String status,
        String reportedByName,
        LocalDateTime receivedAt,
        LocalDateTime pickedUpAt,
        String note
    ) {
        PackageRecord record = new PackageRecord();
        record.setResidentId(residentId);
        record.setResidentName(residentName);
        record.setUnitNumber(unitNumber);
        record.setRecordType(recordType);
        record.setCarrier(carrier);
        record.setItemName(itemName);
        record.setTrackingCode(trackingCode);
        record.setLocation(location);
        record.setStatus(status);
        record.setReportedByName(reportedByName);
        record.setReceivedAt(receivedAt);
        record.setPickedUpAt(pickedUpAt);
        record.setNote(note);
        packageRecordRepository.save(record);
    }

    private void complaint(
        Long residentId,
        String residentName,
        String unitNumber,
        String category,
        String title,
        String description,
        String priority,
        String status,
        Long assignedStaffId,
        String assignedStaffName,
        String responseNote,
        Integer residentRating,
        String residentReview,
        LocalDateTime createdAt,
        LocalDateTime resolvedAt
    ) {
        ComplaintTicket ticket = new ComplaintTicket();
        ticket.setResidentId(residentId);
        ticket.setResidentName(residentName);
        ticket.setUnitNumber(unitNumber);
        ticket.setCategory(category);
        ticket.setTitle(title);
        ticket.setDescription(description);
        ticket.setPriority(priority);
        ticket.setStatus(status);
        ticket.setAssignedStaffId(assignedStaffId);
        ticket.setAssignedStaffName(assignedStaffName);
        ticket.setResponseNote(responseNote);
        ticket.setResidentRating(residentRating);
        ticket.setResidentReview(residentReview);
        ticket.setCreatedAt(createdAt);
        ticket.setResolvedAt(resolvedAt);
        complaintTicketRepository.save(ticket);
    }

    private void shift(
        Long staffId,
        String staffName,
        String role,
        LocalDate shiftDate,
        String shiftLabel,
        String zone,
        String startTime,
        String endTime,
        String status,
        String note
    ) {
        StaffShift shift = new StaffShift();
        shift.setStaffId(staffId);
        shift.setStaffName(staffName);
        shift.setRole(role);
        shift.setShiftDate(shiftDate);
        shift.setShiftLabel(shiftLabel);
        shift.setZone(zone);
        shift.setStartTime(startTime);
        shift.setEndTime(endTime);
        shift.setStatus(status);
        shift.setNote(note);
        staffShiftRepository.save(shift);
    }
}
