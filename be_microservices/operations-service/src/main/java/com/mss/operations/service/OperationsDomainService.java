package com.mss.operations.service;

import com.mss.operations.dto.OperationsDtos;
import com.mss.operations.model.ActivityLog;
import com.mss.operations.model.ComplaintTicket;
import com.mss.operations.model.CustomServiceRequest;
import com.mss.operations.model.PackageRecord;
import com.mss.operations.model.StaffShift;
import com.mss.operations.model.StaffTask;
import com.mss.operations.repository.ActivityLogRepository;
import com.mss.operations.repository.ComplaintTicketRepository;
import com.mss.operations.repository.CustomServiceRequestRepository;
import com.mss.operations.repository.PackageRecordRepository;
import com.mss.operations.repository.StaffShiftRepository;
import com.mss.operations.repository.StaffTaskRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Locale;

@Service
public class OperationsDomainService {
    private final ActivityLogRepository activityRepository;
    private final StaffTaskRepository taskRepository;
    private final CustomServiceRequestRepository customServiceRequestRepository;
    private final PackageRecordRepository packageRecordRepository;
    private final ComplaintTicketRepository complaintTicketRepository;
    private final StaffShiftRepository staffShiftRepository;

    public OperationsDomainService(
        ActivityLogRepository activityRepository,
        StaffTaskRepository taskRepository,
        CustomServiceRequestRepository customServiceRequestRepository,
        PackageRecordRepository packageRecordRepository,
        ComplaintTicketRepository complaintTicketRepository,
        StaffShiftRepository staffShiftRepository
    ) {
        this.activityRepository = activityRepository;
        this.taskRepository = taskRepository;
        this.customServiceRequestRepository = customServiceRequestRepository;
        this.packageRecordRepository = packageRecordRepository;
        this.complaintTicketRepository = complaintTicketRepository;
        this.staffShiftRepository = staffShiftRepository;
    }

    public List<OperationsDtos.ActivityItem> activities() {
        return activityRepository.findTop5ByOrderByCreatedAtDesc().stream().map(this::toActivity).toList();
    }

    public OperationsDtos.TaskBundle tasks(Long staffId) {
        List<StaffTask> tasks = taskRepository.findByAssignedStaffIdOrderByIdAsc(staffId);
        return new OperationsDtos.TaskBundle(
            tasks.size(),
            tasks.stream().filter(task -> "Completed".equalsIgnoreCase(task.getStatus())).count(),
            tasks.stream().map(this::toTask).toList()
        );
    }

    public OperationsDtos.TaskItem createTask(OperationsDtos.CreateTaskRequest request) {
        if (request == null || request.assignedStaffId() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Assigned staff is required");
        }
        if (!hasText(request.title())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Task title is required");
        }

        StaffTask task = new StaffTask();
        task.setAssignedStaffId(request.assignedStaffId());
        task.setAssignedStaffName(request.assignedStaffName());
        task.setTitle(request.title().trim());
        task.setZone(hasText(request.zone()) ? request.zone().trim() : "Unspecified");
        task.setPriority(hasText(request.priority()) ? request.priority().trim() : "Medium");
        task.setStatus("Pending");
        task.setCategory(hasText(request.category()) ? request.category().trim() : "Operations");
        task.setSourceType(request.sourceType());
        task.setSourceId(request.sourceId());
        return toTask(taskRepository.save(task));
    }

    public List<OperationsDtos.CustomServiceRequestItem> customServiceRequests() {
        return customServiceRequestRepository.findAllByOrderByCreatedAtDesc().stream().map(this::toCustomServiceRequest).toList();
    }

    public List<OperationsDtos.CustomServiceRequestItem> residentCustomServiceRequests(Long residentId) {
        return customServiceRequestRepository.findByResidentIdOrderByCreatedAtDesc(residentId).stream().map(this::toCustomServiceRequest).toList();
    }

    public List<OperationsDtos.CustomServiceRequestItem> staffCustomServiceRequests(Long staffId) {
        return customServiceRequestRepository.findByAssignedStaffIdOrderByCreatedAtDesc(staffId).stream().map(this::toCustomServiceRequest).toList();
    }

    @Transactional
    public OperationsDtos.CustomServiceRequestItem createCustomServiceRequest(OperationsDtos.CreateCustomServiceRequestRequest request) {
        CustomServiceRequest serviceRequest = new CustomServiceRequest();
        serviceRequest.setResidentId(request.residentId());
        serviceRequest.setResidentName(request.residentName().trim());
        serviceRequest.setUnitNumber(request.unitNumber().trim());
        serviceRequest.setTitle(request.title().trim());
        serviceRequest.setDescription(request.description().trim());
        serviceRequest.setZone(hasText(request.zone()) ? request.zone().trim() : request.unitNumber().trim());
        serviceRequest.setPreferredSchedule(request.preferredSchedule());
        serviceRequest.setStatus("Pending Assignment");
        serviceRequest.setCreatedAt(LocalDateTime.now());
        CustomServiceRequest saved = customServiceRequestRepository.save(serviceRequest);
        logActivity("service", "Custom service request created", saved.getResidentName() + " requested " + saved.getTitle());
        return toCustomServiceRequest(saved);
    }

    @Transactional
    public OperationsDtos.CustomServiceRequestItem assignCustomServiceRequest(Long requestId, OperationsDtos.AssignCustomServiceRequestRequest request) {
        CustomServiceRequest serviceRequest = getCustomServiceRequest(requestId);
        serviceRequest.setAssignedStaffId(request.staffId());
        serviceRequest.setAssignedStaffName(request.staffName().trim());
        serviceRequest.setQuotedPrice(null);
        serviceRequest.setQuoteNote(null);
        serviceRequest.setResidentDecisionNote(null);
        serviceRequest.setStatus("Awaiting Quote");
        CustomServiceRequest saved = customServiceRequestRepository.save(serviceRequest);
        logActivity("service", "Custom service assigned", saved.getTitle() + " assigned to " + saved.getAssignedStaffName());
        return toCustomServiceRequest(saved);
    }

    @Transactional
    public OperationsDtos.CustomServiceRequestItem quoteCustomServiceRequest(Long requestId, OperationsDtos.QuoteCustomServiceRequestRequest request) {
        CustomServiceRequest serviceRequest = getCustomServiceRequest(requestId);
        if (serviceRequest.getAssignedStaffId() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Request has not been assigned to staff");
        }
        serviceRequest.setQuotedPrice(request.quotedPrice());
        serviceRequest.setQuoteNote(request.quoteNote());
        serviceRequest.setStatus("Awaiting Resident Confirmation");
        CustomServiceRequest saved = customServiceRequestRepository.save(serviceRequest);
        logActivity("service", "Custom service quoted", saved.getTitle() + " quoted by " + saved.getAssignedStaffName());
        return toCustomServiceRequest(saved);
    }

    @Transactional
    public OperationsDtos.CustomServiceRequestItem residentDecision(Long requestId, OperationsDtos.ResidentDecisionRequest request) {
        CustomServiceRequest serviceRequest = getCustomServiceRequest(requestId);
        String decision = request.decision().trim().toLowerCase(Locale.ROOT);
        serviceRequest.setResidentDecisionNote(request.note());

        if ("confirm".equals(decision)) {
            if (serviceRequest.getAssignedStaffId() == null) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "No staff assigned to this request");
            }
            serviceRequest.setStatus("Confirmed");
            ensureTaskExists(serviceRequest);
            logActivity("service", "Custom service confirmed", serviceRequest.getResidentName() + " confirmed " + serviceRequest.getTitle());
        } else if ("reject".equals(decision)) {
            serviceRequest.setAssignedStaffId(null);
            serviceRequest.setAssignedStaffName(null);
            serviceRequest.setQuotedPrice(null);
            serviceRequest.setQuoteNote(null);
            serviceRequest.setStatus("Reassign Required");
            logActivity("service", "Custom service rejected", serviceRequest.getResidentName() + " rejected quote for " + serviceRequest.getTitle());
        } else {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Decision must be confirm or reject");
        }

        return toCustomServiceRequest(customServiceRequestRepository.save(serviceRequest));
    }

    public List<OperationsDtos.PackageItem> packages() {
        return packageRecordRepository.findAllByOrderByReceivedAtDesc().stream().map(this::toPackage).toList();
    }

    public List<OperationsDtos.PackageItem> residentPackages(Long residentId) {
        return packageRecordRepository.findByResidentIdOrderByReceivedAtDesc(residentId).stream().map(this::toPackage).toList();
    }

    @Transactional
    public OperationsDtos.PackageItem createPackage(OperationsDtos.CreatePackageRequest request) {
        PackageRecord record = new PackageRecord();
        record.setResidentId(request.residentId());
        record.setResidentName(hasText(request.residentName()) ? request.residentName().trim() : null);
        record.setUnitNumber(hasText(request.unitNumber()) ? request.unitNumber().trim() : null);
        record.setRecordType(request.recordType().trim());
        record.setCarrier(hasText(request.carrier()) ? request.carrier().trim() : null);
        record.setItemName(request.itemName().trim());
        record.setTrackingCode(hasText(request.trackingCode()) ? request.trackingCode().trim() : null);
        record.setLocation(hasText(request.location()) ? request.location().trim() : "Front Desk");
        record.setStatus(hasText(request.status()) ? request.status().trim() : defaultPackageStatus(record.getRecordType()));
        record.setReportedByName(hasText(request.reportedByName()) ? request.reportedByName().trim() : "Front Desk");
        record.setReceivedAt(LocalDateTime.now());
        record.setNote(request.note());
        PackageRecord saved = packageRecordRepository.save(record);
        logActivity("operations", saved.getRecordType() + " logged", saved.getItemName() + " recorded at " + saved.getLocation());
        return toPackage(saved);
    }

    @Transactional
    public OperationsDtos.PackageItem updatePackageStatus(Long packageId, OperationsDtos.UpdatePackageStatusRequest request) {
        PackageRecord record = packageRecordRepository.findById(packageId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Package record not found"));
        record.setStatus(request.status().trim());
        String normalized = request.status().trim().toLowerCase(Locale.ROOT);
        if (normalized.contains("pick") || normalized.contains("claim")) {
            record.setPickedUpAt(LocalDateTime.now());
        }
        PackageRecord saved = packageRecordRepository.save(record);
        logActivity("operations", saved.getRecordType() + " updated", saved.getItemName() + " is now " + saved.getStatus());
        return toPackage(saved);
    }

    public List<OperationsDtos.ComplaintItem> complaints() {
        return complaintTicketRepository.findAllByOrderByCreatedAtDesc().stream().map(this::toComplaint).toList();
    }

    public List<OperationsDtos.ComplaintItem> residentComplaints(Long residentId) {
        return complaintTicketRepository.findByResidentIdOrderByCreatedAtDesc(residentId).stream().map(this::toComplaint).toList();
    }

    public List<OperationsDtos.ComplaintItem> staffComplaints(Long staffId) {
        return complaintTicketRepository.findByAssignedStaffIdOrderByCreatedAtDesc(staffId).stream().map(this::toComplaint).toList();
    }

    @Transactional
    public OperationsDtos.ComplaintItem createComplaint(OperationsDtos.CreateComplaintRequest request) {
        ComplaintTicket ticket = new ComplaintTicket();
        ticket.setResidentId(request.residentId());
        ticket.setResidentName(request.residentName().trim());
        ticket.setUnitNumber(request.unitNumber().trim());
        ticket.setCategory(request.category().trim());
        ticket.setTitle(request.title().trim());
        ticket.setDescription(request.description().trim());
        ticket.setPriority(hasText(request.priority()) ? request.priority().trim() : "Medium");
        ticket.setStatus("Open");
        ticket.setCreatedAt(LocalDateTime.now());
        ComplaintTicket saved = complaintTicketRepository.save(ticket);
        logActivity("service", "Complaint received", saved.getResidentName() + " submitted " + saved.getTitle());
        return toComplaint(saved);
    }

    @Transactional
    public OperationsDtos.ComplaintItem assignComplaint(Long complaintId, OperationsDtos.AssignComplaintRequest request) {
        ComplaintTicket ticket = getComplaint(complaintId);
        ticket.setAssignedStaffId(request.staffId());
        ticket.setAssignedStaffName(request.staffName().trim());
        ticket.setStatus("Assigned");
        ComplaintTicket saved = complaintTicketRepository.save(ticket);
        ensureComplaintTaskExists(saved);
        logActivity("service", "Complaint assigned", saved.getTitle() + " assigned to " + saved.getAssignedStaffName());
        return toComplaint(saved);
    }

    @Transactional
    public OperationsDtos.ComplaintItem updateComplaintStatus(Long complaintId, OperationsDtos.UpdateComplaintStatusRequest request) {
        ComplaintTicket ticket = getComplaint(complaintId);
        ticket.setStatus(request.status().trim());
        ticket.setResponseNote(request.responseNote());
        String normalized = request.status().trim().toLowerCase(Locale.ROOT);
        if (normalized.contains("resolved") || normalized.contains("closed")) {
            ticket.setResolvedAt(LocalDateTime.now());
        }
        ComplaintTicket saved = complaintTicketRepository.save(ticket);
        logActivity("service", "Complaint updated", saved.getTitle() + " moved to " + saved.getStatus());
        return toComplaint(saved);
    }

    @Transactional
    public OperationsDtos.ComplaintItem rateComplaint(Long complaintId, OperationsDtos.RateComplaintRequest request) {
        ComplaintTicket ticket = getComplaint(complaintId);
        if (request.rating() == null || request.rating() < 1 || request.rating() > 5) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Rating must be between 1 and 5");
        }
        if (ticket.getResolvedAt() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Complaint must be resolved before rating");
        }
        ticket.setResidentRating(request.rating());
        ticket.setResidentReview(request.review());
        ComplaintTicket saved = complaintTicketRepository.save(ticket);
        logActivity("service", "Resident rated service", saved.getTitle() + " received " + request.rating() + "/5");
        return toComplaint(saved);
    }

    public List<OperationsDtos.StaffShiftItem> shifts() {
        return staffShiftRepository.findAllByOrderByShiftDateAscStartTimeAsc().stream().map(this::toShift).toList();
    }

    public List<OperationsDtos.StaffShiftItem> staffShifts(Long staffId) {
        return staffShiftRepository.findByStaffIdOrderByShiftDateAscStartTimeAsc(staffId).stream().map(this::toShift).toList();
    }

    @Transactional
    public OperationsDtos.StaffShiftItem createShift(OperationsDtos.CreateStaffShiftRequest request) {
        StaffShift shift = new StaffShift();
        applyShift(shift, request);
        StaffShift saved = staffShiftRepository.save(shift);
        logActivity("operations", "Shift scheduled", saved.getStaffName() + " scheduled for " + saved.getShiftLabel() + " shift");
        return toShift(saved);
    }

    @Transactional
    public OperationsDtos.StaffShiftItem updateShift(Long shiftId, OperationsDtos.CreateStaffShiftRequest request) {
        StaffShift shift = staffShiftRepository.findById(shiftId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Staff shift not found"));
        applyShift(shift, request);
        StaffShift saved = staffShiftRepository.save(shift);
        logActivity("operations", "Shift updated", saved.getStaffName() + " shift updated for " + saved.getShiftDate());
        return toShift(saved);
    }

    private OperationsDtos.ActivityItem toActivity(ActivityLog log) {
        return new OperationsDtos.ActivityItem(log.getId(), log.getType(), log.getTitle(), log.getDescription(), log.getCreatedAt());
    }

    private OperationsDtos.TaskItem toTask(StaffTask task) {
        return new OperationsDtos.TaskItem(task.getId(), task.getSourceId(), task.getSourceType(), task.getAssignedStaffName(), task.getTitle(), task.getZone(), task.getPriority(), task.getStatus(), task.getCategory());
    }

    private OperationsDtos.CustomServiceRequestItem toCustomServiceRequest(CustomServiceRequest request) {
        return new OperationsDtos.CustomServiceRequestItem(
            request.getId(),
            request.getResidentId(),
            request.getResidentName(),
            request.getUnitNumber(),
            request.getTitle(),
            request.getDescription(),
            request.getZone(),
            request.getPreferredSchedule(),
            request.getStatus(),
            request.getAssignedStaffId(),
            request.getAssignedStaffName(),
            request.getQuotedPrice(),
            request.getQuoteNote(),
            request.getResidentDecisionNote(),
            request.getCreatedAt()
        );
    }

    private OperationsDtos.PackageItem toPackage(PackageRecord record) {
        return new OperationsDtos.PackageItem(
            record.getId(),
            record.getResidentId(),
            record.getResidentName(),
            record.getUnitNumber(),
            record.getRecordType(),
            record.getCarrier(),
            record.getItemName(),
            record.getTrackingCode(),
            record.getLocation(),
            record.getStatus(),
            record.getReportedByName(),
            record.getReceivedAt(),
            record.getPickedUpAt(),
            record.getNote()
        );
    }

    private OperationsDtos.ComplaintItem toComplaint(ComplaintTicket ticket) {
        return new OperationsDtos.ComplaintItem(
            ticket.getId(),
            ticket.getResidentId(),
            ticket.getResidentName(),
            ticket.getUnitNumber(),
            ticket.getCategory(),
            ticket.getTitle(),
            ticket.getDescription(),
            ticket.getPriority(),
            ticket.getStatus(),
            ticket.getAssignedStaffId(),
            ticket.getAssignedStaffName(),
            ticket.getResponseNote(),
            ticket.getResidentRating(),
            ticket.getResidentReview(),
            ticket.getCreatedAt(),
            ticket.getResolvedAt()
        );
    }

    private OperationsDtos.StaffShiftItem toShift(StaffShift shift) {
        return new OperationsDtos.StaffShiftItem(
            shift.getId(),
            shift.getStaffId(),
            shift.getStaffName(),
            shift.getRole(),
            shift.getShiftDate(),
            shift.getShiftLabel(),
            shift.getZone(),
            shift.getStartTime(),
            shift.getEndTime(),
            shift.getStatus(),
            shift.getNote()
        );
    }

    private CustomServiceRequest getCustomServiceRequest(Long requestId) {
        return customServiceRequestRepository.findById(requestId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Custom service request not found"));
    }

    private ComplaintTicket getComplaint(Long complaintId) {
        return complaintTicketRepository.findById(complaintId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Complaint not found"));
    }

    private void ensureTaskExists(CustomServiceRequest serviceRequest) {
        if (serviceRequest.getId() == null) {
            return;
        }
        if (taskRepository.findFirstBySourceTypeAndSourceId("custom_service_request", serviceRequest.getId()).isPresent()) {
            return;
        }
        StaffTask task = new StaffTask();
        task.setAssignedStaffId(serviceRequest.getAssignedStaffId());
        task.setAssignedStaffName(serviceRequest.getAssignedStaffName());
        task.setTitle(serviceRequest.getTitle());
        task.setZone(serviceRequest.getZone());
        task.setPriority("Medium");
        task.setStatus("Pending");
        task.setCategory("Custom Service");
        task.setSourceType("custom_service_request");
        task.setSourceId(serviceRequest.getId());
        taskRepository.save(task);
    }

    private void ensureComplaintTaskExists(ComplaintTicket ticket) {
        if (ticket.getId() == null || ticket.getAssignedStaffId() == null) {
            return;
        }
        if (taskRepository.findFirstBySourceTypeAndSourceId("complaint", ticket.getId()).isPresent()) {
            return;
        }
        StaffTask task = new StaffTask();
        task.setAssignedStaffId(ticket.getAssignedStaffId());
        task.setAssignedStaffName(ticket.getAssignedStaffName());
        task.setTitle(ticket.getTitle());
        task.setZone(ticket.getUnitNumber());
        task.setPriority(ticket.getPriority());
        task.setStatus("Pending");
        task.setCategory("Complaint");
        task.setSourceType("complaint");
        task.setSourceId(ticket.getId());
        taskRepository.save(task);
    }

    private void applyShift(StaffShift shift, OperationsDtos.CreateStaffShiftRequest request) {
        shift.setStaffId(request.staffId());
        shift.setStaffName(request.staffName().trim());
        shift.setRole(request.role().trim());
        shift.setShiftDate(request.shiftDate());
        shift.setShiftLabel(request.shiftLabel().trim());
        shift.setZone(request.zone().trim());
        shift.setStartTime(request.startTime().trim());
        shift.setEndTime(request.endTime().trim());
        shift.setStatus(hasText(request.status()) ? request.status().trim() : "Scheduled");
        shift.setNote(request.note());
    }

    private void logActivity(String type, String title, String description) {
        ActivityLog log = new ActivityLog();
        log.setType(type);
        log.setTitle(title);
        log.setDescription(description);
        log.setCreatedAt(LocalDateTime.now());
        activityRepository.save(log);
    }

    private String defaultPackageStatus(String recordType) {
        return "lost & found".equalsIgnoreCase(recordType) ? "Claim Pending" : "Arrived";
    }

    private boolean hasText(String value) {
        return value != null && !value.isBlank();
    }
}
