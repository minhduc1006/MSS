package com.mss.security.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDateTime;
import java.util.List;

public final class SecurityDtos {
    private SecurityDtos() {}
    public record IncidentItem(Long id, String title, String description, String zone, String status, String severity, String assignedStaffName, LocalDateTime createdAt) {}
    public record SecurityLogItem(Long id, String audience, String event, String visitor, LocalDateTime accessTime, String status) {}
    public record SecurityOverview(List<IncidentItem> incidents, List<SecurityLogItem> recentLogs) {}
    public record CreateIncidentRequest(
        @NotBlank String title,
        @NotBlank String description,
        @NotBlank String zone,
        @NotBlank String severity,
        Long userId,
        String audience
    ) {}
    public record UpdateIncidentRequest(
        @NotBlank String title,
        @NotBlank String description,
        @NotBlank String zone,
        @NotBlank String status,
        @NotBlank String severity,
        String assignedStaffName
    ) {}
    public record UpdateIncidentStatusRequest(@NotBlank String status) {}
    public record TriggerSosRequest(@NotNull Long userId, @NotBlank String audience) {}
    public record SecurityHistoryResponse(String visitorCode, List<SecurityLogItem> logs) {}
}
