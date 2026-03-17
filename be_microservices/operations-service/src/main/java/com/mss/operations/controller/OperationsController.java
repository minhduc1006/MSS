package com.mss.operations.controller;

import com.mss.operations.dto.OperationsDtos;
import com.mss.operations.service.OperationsDomainService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/operations")
public class OperationsController {
    private final OperationsDomainService service;

    public OperationsController(OperationsDomainService service) {
        this.service = service;
    }

    @GetMapping("/activity")
    public List<OperationsDtos.ActivityItem> activity() {
        return service.activities();
    }

    @GetMapping("/staff/{staffId}/tasks")
    public OperationsDtos.TaskBundle tasks(@PathVariable Long staffId) {
        return service.tasks(staffId);
    }

    @PostMapping("/tasks")
    public OperationsDtos.TaskItem createTask(@RequestBody OperationsDtos.CreateTaskRequest request) {
        return service.createTask(request);
    }

    @GetMapping("/custom-service-requests")
    public List<OperationsDtos.CustomServiceRequestItem> customServiceRequests() {
        return service.customServiceRequests();
    }

    @GetMapping("/custom-service-requests/resident/{residentId}")
    public List<OperationsDtos.CustomServiceRequestItem> residentCustomServiceRequests(@PathVariable Long residentId) {
        return service.residentCustomServiceRequests(residentId);
    }

    @GetMapping("/custom-service-requests/staff/{staffId}")
    public List<OperationsDtos.CustomServiceRequestItem> staffCustomServiceRequests(@PathVariable Long staffId) {
        return service.staffCustomServiceRequests(staffId);
    }

    @PostMapping("/custom-service-requests")
    public OperationsDtos.CustomServiceRequestItem createCustomServiceRequest(
        @Valid @RequestBody OperationsDtos.CreateCustomServiceRequestRequest request
    ) {
        return service.createCustomServiceRequest(request);
    }

    @PostMapping("/custom-service-requests/{requestId}/assign")
    public OperationsDtos.CustomServiceRequestItem assignCustomServiceRequest(
        @PathVariable Long requestId,
        @Valid @RequestBody OperationsDtos.AssignCustomServiceRequestRequest request
    ) {
        return service.assignCustomServiceRequest(requestId, request);
    }

    @PostMapping("/custom-service-requests/{requestId}/quote")
    public OperationsDtos.CustomServiceRequestItem quoteCustomServiceRequest(
        @PathVariable Long requestId,
        @Valid @RequestBody OperationsDtos.QuoteCustomServiceRequestRequest request
    ) {
        return service.quoteCustomServiceRequest(requestId, request);
    }

    @PostMapping("/custom-service-requests/{requestId}/resident-decision")
    public OperationsDtos.CustomServiceRequestItem residentDecision(
        @PathVariable Long requestId,
        @Valid @RequestBody OperationsDtos.ResidentDecisionRequest request
    ) {
        return service.residentDecision(requestId, request);
    }
}
