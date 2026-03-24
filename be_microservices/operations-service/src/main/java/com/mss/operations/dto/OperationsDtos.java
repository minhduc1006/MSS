package com.mss.operations.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

public final class OperationsDtos {
    private OperationsDtos() {}
    public record ActivityItem(Long id, String type, String title, String description, LocalDateTime createdAt) {}
    public record TaskItem(Long id, Long sourceId, String sourceType, String assignedStaffName, String title, String zone, String priority, String status, String category) {}
    public record TaskBundle(long totalTasks, long completedTasks, List<TaskItem> tasks) {}
    public record CreateTaskRequest(Long assignedStaffId, String assignedStaffName, String title, String zone, String priority, String category, String sourceType, Long sourceId) {}
    public record CustomServiceRequestItem(
        Long id,
        Long residentId,
        String residentName,
        String unitNumber,
        String title,
        String description,
        String zone,
        String preferredSchedule,
        String status,
        Long assignedStaffId,
        String assignedStaffName,
        BigDecimal quotedPrice,
        String quoteNote,
        String residentDecisionNote,
        LocalDateTime createdAt
    ) {}
    public record CreateCustomServiceRequestRequest(
        @NotNull Long residentId,
        @NotBlank String residentName,
        @NotBlank String unitNumber,
        @NotBlank String title,
        @NotBlank String description,
        String zone,
        String preferredSchedule
    ) {}
    public record AssignCustomServiceRequestRequest(@NotNull Long staffId, @NotBlank String staffName) {}
    public record QuoteCustomServiceRequestRequest(@NotNull BigDecimal quotedPrice, String quoteNote) {}
    public record ResidentDecisionRequest(@NotBlank String decision, String note) {}
    public record PackageItem(
        Long id,
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
    ) {}
    public record CreatePackageRequest(
        Long residentId,
        String residentName,
        String unitNumber,
        @NotBlank String recordType,
        String carrier,
        @NotBlank String itemName,
        String trackingCode,
        String location,
        String status,
        String reportedByName,
        String note
    ) {}
    public record UpdatePackageStatusRequest(@NotBlank String status) {}
    public record ComplaintItem(
        Long id,
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
    ) {}
    public record CreateComplaintRequest(
        @NotNull Long residentId,
        @NotBlank String residentName,
        @NotBlank String unitNumber,
        @NotBlank String category,
        @NotBlank String title,
        @NotBlank String description,
        String priority
    ) {}
    public record AssignComplaintRequest(@NotNull Long staffId, @NotBlank String staffName) {}
    public record UpdateComplaintStatusRequest(@NotBlank String status, String responseNote) {}
    public record RateComplaintRequest(@NotNull Integer rating, String review) {}
    public record StaffShiftItem(
        Long id,
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
    ) {}
    public record CreateStaffShiftRequest(
        @NotNull Long staffId,
        @NotBlank String staffName,
        @NotBlank String role,
        @NotNull LocalDate shiftDate,
        @NotBlank String shiftLabel,
        @NotBlank String zone,
        @NotBlank String startTime,
        @NotBlank String endTime,
        String status,
        String note
    ) {}
}
