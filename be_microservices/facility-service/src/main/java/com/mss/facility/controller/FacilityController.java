package com.mss.facility.controller;

import com.mss.facility.dto.FacilityDtos;
import com.mss.facility.service.FacilityDomainService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api")
public class FacilityController {
    private final FacilityDomainService service;

    public FacilityController(FacilityDomainService service) {
        this.service = service;
    }

    @GetMapping("/facilities")
    public FacilityDtos.FacilitiesResponse facilities() {
        return service.facilities();
    }

    @PostMapping("/facilities/{facilityId}/logs")
    public FacilityDtos.FacilityLogItem addLog(@PathVariable Long facilityId, @Valid @RequestBody FacilityDtos.CreateMaintenanceLogRequest request) {
        return service.addLog(facilityId, request);
    }

    @GetMapping("/bookings/resident/{residentId}")
    public List<FacilityDtos.BookingItem> bookings(@PathVariable Long residentId) {
        return service.bookings(residentId);
    }

    @PostMapping("/bookings/resident/{residentId}")
    public FacilityDtos.BookingItem createBooking(@PathVariable Long residentId, @Valid @RequestBody FacilityDtos.CreateBookingRequest request) {
        return service.createBooking(residentId, request);
    }

    @GetMapping("/announcements")
    public List<FacilityDtos.AnnouncementItem> announcements() {
        return service.announcements();
    }
}
