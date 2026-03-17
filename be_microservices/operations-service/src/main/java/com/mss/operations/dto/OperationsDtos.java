package com.mss.operations.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
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
}
