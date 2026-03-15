package com.mss.facility.service;

import com.mss.facility.dto.FacilityDtos;
import com.mss.facility.model.Announcement;
import com.mss.facility.model.Booking;
import com.mss.facility.model.Facility;
import com.mss.facility.model.MaintenanceLog;
import com.mss.facility.repository.AnnouncementRepository;
import com.mss.facility.repository.BookingRepository;
import com.mss.facility.repository.FacilityRepository;
import com.mss.facility.repository.MaintenanceLogRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;

@Service
public class FacilityDomainService {
    private final FacilityRepository facilityRepository;
    private final MaintenanceLogRepository maintenanceLogRepository;
    private final BookingRepository bookingRepository;
    private final AnnouncementRepository announcementRepository;

    public FacilityDomainService(FacilityRepository facilityRepository, MaintenanceLogRepository maintenanceLogRepository, BookingRepository bookingRepository, AnnouncementRepository announcementRepository) {
        this.facilityRepository = facilityRepository;
        this.maintenanceLogRepository = maintenanceLogRepository;
        this.bookingRepository = bookingRepository;
        this.announcementRepository = announcementRepository;
    }

    public FacilityDtos.FacilitiesResponse facilities() {
        return new FacilityDtos.FacilitiesResponse(facilityRepository.findAll().stream().sorted(Comparator.comparing(Facility::getName)).map(this::toFacility).toList());
    }

    public FacilityDtos.FacilityLogItem addLog(Long facilityId, FacilityDtos.CreateMaintenanceLogRequest request) {
        Facility facility = facilityRepository.findById(facilityId).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Facility not found"));
        MaintenanceLog log = new MaintenanceLog();
        log.setFacilityId(facilityId);
        log.setNote(request.note());
        log.setCreatedByName(request.createdByName());
        log.setCreatedAt(LocalDateTime.now());
        log.setMarkOperational(request.markOperational());
        MaintenanceLog saved = maintenanceLogRepository.save(log);
        facility.setLastCheckAt(LocalDateTime.now());
        facility.setStatus(request.markOperational() ? "Operational" : facility.getStatus());
        facility.setHealth(Math.min(100, facility.getHealth() + (request.markOperational() ? 15 : 5)));
        facilityRepository.save(facility);
        return toLog(saved);
    }

    public List<FacilityDtos.BookingItem> bookings(Long residentId) {
        return bookingRepository.findByResidentIdOrderByBookingDateDesc(residentId).stream().map(this::toBooking).toList();
    }

    public FacilityDtos.BookingItem createBooking(Long residentId, FacilityDtos.CreateBookingRequest request) {
        Booking booking = new Booking();
        booking.setResidentId(residentId);
        booking.setFacilityId(request.facilityId());
        Facility facility = facilityRepository.findById(request.facilityId()).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Facility not found"));
        booking.setTitle(facility.getName());
        booking.setBookingDate(request.bookingDate());
        booking.setTimeSlot(request.timeSlot());
        booking.setStatus("Confirmed");
        return toBooking(bookingRepository.save(booking));
    }

    public List<FacilityDtos.AnnouncementItem> announcements() {
        return announcementRepository.findTop5ByOrderByCreatedAtDesc().stream().map(this::toAnnouncement).toList();
    }

    private FacilityDtos.FacilityItem toFacility(Facility facility) {
        return new FacilityDtos.FacilityItem(facility.getId(), facility.getName(), facility.getArea(), facility.getStatus(), facility.getHealth(), facility.getLastCheckAt(), facility.getIcon(), maintenanceLogRepository.findByFacilityIdOrderByCreatedAtDesc(facility.getId()).stream().map(this::toLog).toList());
    }

    private FacilityDtos.FacilityLogItem toLog(MaintenanceLog log) {
        return new FacilityDtos.FacilityLogItem(log.getId(), log.getNote(), log.getCreatedByName(), log.getCreatedAt(), log.isMarkOperational());
    }

    private FacilityDtos.BookingItem toBooking(Booking booking) {
        Facility facility = facilityRepository.findById(booking.getFacilityId()).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Facility not found"));
        return new FacilityDtos.BookingItem(booking.getId(), booking.getFacilityId(), facility.getName(), booking.getTitle(), booking.getBookingDate(), booking.getTimeSlot(), booking.getStatus());
    }

    private FacilityDtos.AnnouncementItem toAnnouncement(Announcement announcement) {
        return new FacilityDtos.AnnouncementItem(announcement.getId(), announcement.getTitle(), announcement.getContent(), announcement.getCategory(), announcement.getCreatedAt());
    }
}
