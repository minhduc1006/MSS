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

    @GetMapping("/packages")
    public List<OperationsDtos.PackageItem> packages() {
        return service.packages();
    }

    @GetMapping("/packages/resident/{residentId}")
    public List<OperationsDtos.PackageItem> residentPackages(@PathVariable Long residentId) {
        return service.residentPackages(residentId);
    }

    @PostMapping("/packages")
    public OperationsDtos.PackageItem createPackage(@Valid @RequestBody OperationsDtos.CreatePackageRequest request) {
        return service.createPackage(request);
    }

    @PostMapping("/packages/{packageId}/status")
    public OperationsDtos.PackageItem updatePackageStatus(
        @PathVariable Long packageId,
        @Valid @RequestBody OperationsDtos.UpdatePackageStatusRequest request
    ) {
        return service.updatePackageStatus(packageId, request);
    }

    @GetMapping("/complaints")
    public List<OperationsDtos.ComplaintItem> complaints() {
        return service.complaints();
    }

    @GetMapping("/complaints/resident/{residentId}")
    public List<OperationsDtos.ComplaintItem> residentComplaints(@PathVariable Long residentId) {
        return service.residentComplaints(residentId);
    }

    @GetMapping("/complaints/staff/{staffId}")
    public List<OperationsDtos.ComplaintItem> staffComplaints(@PathVariable Long staffId) {
        return service.staffComplaints(staffId);
    }

    @PostMapping("/complaints")
    public OperationsDtos.ComplaintItem createComplaint(@Valid @RequestBody OperationsDtos.CreateComplaintRequest request) {
        return service.createComplaint(request);
    }

    @PostMapping("/complaints/{complaintId}/assign")
    public OperationsDtos.ComplaintItem assignComplaint(
        @PathVariable Long complaintId,
        @Valid @RequestBody OperationsDtos.AssignComplaintRequest request
    ) {
        return service.assignComplaint(complaintId, request);
    }

    @PostMapping("/complaints/{complaintId}/status")
    public OperationsDtos.ComplaintItem updateComplaintStatus(
        @PathVariable Long complaintId,
        @Valid @RequestBody OperationsDtos.UpdateComplaintStatusRequest request
    ) {
        return service.updateComplaintStatus(complaintId, request);
    }

    @PostMapping("/complaints/{complaintId}/rating")
    public OperationsDtos.ComplaintItem rateComplaint(
        @PathVariable Long complaintId,
        @Valid @RequestBody OperationsDtos.RateComplaintRequest request
    ) {
        return service.rateComplaint(complaintId, request);
    }

    @GetMapping("/shifts")
    public List<OperationsDtos.StaffShiftItem> shifts() {
        return service.shifts();
    }

    @GetMapping("/shifts/staff/{staffId}")
    public List<OperationsDtos.StaffShiftItem> staffShifts(@PathVariable Long staffId) {
        return service.staffShifts(staffId);
    }

    @PostMapping("/shifts")
    public OperationsDtos.StaffShiftItem createShift(@Valid @RequestBody OperationsDtos.CreateStaffShiftRequest request) {
        return service.createShift(request);
    }

    @PostMapping("/shifts/{shiftId}")
    public OperationsDtos.StaffShiftItem updateShift(
        @PathVariable Long shiftId,
        @Valid @RequestBody OperationsDtos.CreateStaffShiftRequest request
    ) {
        return service.updateShift(shiftId, request);
    }
}
