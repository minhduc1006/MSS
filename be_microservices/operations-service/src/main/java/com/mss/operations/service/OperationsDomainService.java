package com.mss.operations.service;

import com.mss.operations.dto.OperationsDtos;
import com.mss.operations.model.ActivityLog;
import com.mss.operations.model.CustomServiceRequest;
import com.mss.operations.model.StaffTask;
import com.mss.operations.repository.ActivityLogRepository;
import com.mss.operations.repository.CustomServiceRequestRepository;
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

    public OperationsDomainService(
        ActivityLogRepository activityRepository,
        StaffTaskRepository taskRepository,
        CustomServiceRequestRepository customServiceRequestRepository
    ) {
        this.activityRepository = activityRepository;
        this.taskRepository = taskRepository;
        this.customServiceRequestRepository = customServiceRequestRepository;
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
        if (request.title() == null || request.title().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Task title is required");
        }

        StaffTask task = new StaffTask();
        task.setAssignedStaffId(request.assignedStaffId());
        task.setAssignedStaffName(request.assignedStaffName());
        task.setTitle(request.title().trim());
        task.setZone(request.zone() == null || request.zone().isBlank() ? "Unspecified" : request.zone().trim());
        task.setPriority(request.priority() == null || request.priority().isBlank() ? "Medium" : request.priority().trim());
        task.setStatus("Pending");
        task.setCategory(request.category() == null || request.category().isBlank() ? "Operations" : request.category().trim());
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
        serviceRequest.setZone(request.zone() == null || request.zone().isBlank() ? request.unitNumber().trim() : request.zone().trim());
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

    private CustomServiceRequest getCustomServiceRequest(Long requestId) {
        return customServiceRequestRepository.findById(requestId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Custom service request not found"));
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

    private void logActivity(String type, String title, String description) {
        ActivityLog log = new ActivityLog();
        log.setType(type);
        log.setTitle(title);
        log.setDescription(description);
        log.setCreatedAt(LocalDateTime.now());
        activityRepository.save(log);
    }
}
