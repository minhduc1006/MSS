package com.mss.facility.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

public final class FacilityDtos {
    private FacilityDtos() {}

    public record FacilityLogItem(Long id, String note, String createdByName, LocalDateTime createdAt, boolean markOperational) {}
    public record FacilityItem(
        Long id,
        String name,
        String area,
        String status,
        int health,
        LocalDateTime lastCheckAt,
        String icon,
        String description,
        String serviceType,
        String bookingMode,
        BigDecimal oneTimePrice,
        BigDecimal monthlyPrice,
        BigDecimal yearlyPrice,
        List<String> slotCodes,
        List<String> occupiedSlotCodes,
        List<FacilityLogItem> logs
    ) {}
    public record FacilitiesResponse(List<FacilityItem> facilities) {}
    public record CreateFacilityRequest(
        @NotBlank String name,
        @NotBlank String area,
        @NotBlank String status,
        int health,
        String icon,
        String description,
        String serviceType,
        String bookingMode,
        BigDecimal oneTimePrice,
        BigDecimal monthlyPrice,
        BigDecimal yearlyPrice,
        String slotLayout
    ) {}
    public record UpdateFacilityStatusRequest(@NotBlank String status) {}
    public record CreateMaintenanceLogRequest(@NotBlank String note, @NotBlank String createdByName, boolean markOperational) {}
    public record BookingItem(
        Long id,
        Long facilityId,
        String facilityName,
        String title,
        LocalDate bookingDate,
        String timeSlot,
        String status,
        String slotCode,
        String planType,
        BigDecimal amount
    ) {}
    public record CreateBookingRequest(
        @NotNull Long facilityId,
        @NotNull LocalDate bookingDate,
        @NotBlank String timeSlot,
        String slotCode,
        String planType
    ) {}
    public record AnnouncementItem(Long id, String title, String content, String category, LocalDateTime createdAt) {}
}
