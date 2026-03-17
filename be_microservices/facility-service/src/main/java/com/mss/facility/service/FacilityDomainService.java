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

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;

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

    public FacilityDtos.FacilityItem createFacility(FacilityDtos.CreateFacilityRequest request) {
        Facility facility = new Facility();
        applyFacility(facility, request);
        return toFacility(facilityRepository.save(facility));
    }

    public FacilityDtos.FacilityItem updateFacility(Long facilityId, FacilityDtos.CreateFacilityRequest request) {
        Facility facility = facilityRepository.findById(facilityId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Facility not found"));
        applyFacility(facility, request);
        return toFacility(facilityRepository.save(facility));
    }

    public FacilityDtos.FacilityItem updateFacilityStatus(Long facilityId, FacilityDtos.UpdateFacilityStatusRequest request) {
        Facility facility = facilityRepository.findById(facilityId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Facility not found"));
        facility.setStatus(request.status().trim());
        facility.setLastCheckAt(LocalDateTime.now());
        return toFacility(facilityRepository.save(facility));
    }

    public FacilityDtos.FacilityItem deactivateFacility(Long facilityId) {
        Facility facility = facilityRepository.findById(facilityId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Facility not found"));
        facility.setStatus("Deactivated");
        facility.setLastCheckAt(LocalDateTime.now());
        return toFacility(facilityRepository.save(facility));
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
        Facility facility = facilityRepository.findById(request.facilityId()).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Facility not found"));
        Booking booking = new Booking();
        booking.setResidentId(residentId);
        booking.setFacilityId(request.facilityId());
        booking.setTitle(facility.getName());
        booking.setBookingDate(request.bookingDate());
        booking.setStatus("Confirmed");
        booking.setAmount(resolveAmount(facility, request));

        if (isParkingFacility(facility)) {
            String slotCode = normalizeSlotCode(request.slotCode());
            if (slotCode == null) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Parking slot is required");
            }
            if (!slotCodes(facility).contains(slotCode)) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Selected parking slot does not exist");
            }
            if (isSlotOccupied(facility.getId(), slotCode)) {
                throw new ResponseStatusException(HttpStatus.CONFLICT, "Selected parking slot is already reserved");
            }
            String planType = normalizePlanType(request.planType());
            if (planType == null) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Parking plan type is required");
            }
            booking.setSlotCode(slotCode);
            booking.setPlanType(planType);
            booking.setTimeSlot("yearly".equals(planType) ? "Yearly Subscription" : "Monthly Subscription");
            booking.setTitle("Parking Slot " + slotCode);
        } else {
            booking.setTimeSlot(request.timeSlot());
        }

        return toBooking(bookingRepository.save(booking));
    }

    public List<FacilityDtos.AnnouncementItem> announcements() {
        return announcementRepository.findTop5ByOrderByCreatedAtDesc().stream().map(this::toAnnouncement).toList();
    }

    private FacilityDtos.FacilityItem toFacility(Facility facility) {
        return new FacilityDtos.FacilityItem(
            facility.getId(),
            facility.getName(),
            facility.getArea(),
            facility.getStatus(),
            facility.getHealth(),
            facility.getLastCheckAt(),
            facility.getIcon(),
            facility.getDescription(),
            defaultString(facility.getServiceType(), "shared"),
            defaultString(facility.getBookingMode(), "timeslot"),
            facility.getOneTimePrice(),
            facility.getMonthlyPrice(),
            facility.getYearlyPrice(),
            slotCodes(facility),
            occupiedSlots(facility),
            maintenanceLogRepository.findByFacilityIdOrderByCreatedAtDesc(facility.getId()).stream().map(this::toLog).toList()
        );
    }

    private FacilityDtos.FacilityLogItem toLog(MaintenanceLog log) {
        return new FacilityDtos.FacilityLogItem(log.getId(), log.getNote(), log.getCreatedByName(), log.getCreatedAt(), log.isMarkOperational());
    }

    private FacilityDtos.BookingItem toBooking(Booking booking) {
        Facility facility = facilityRepository.findById(booking.getFacilityId()).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Facility not found"));
        return new FacilityDtos.BookingItem(
            booking.getId(),
            booking.getFacilityId(),
            facility.getName(),
            booking.getTitle(),
            booking.getBookingDate(),
            booking.getTimeSlot(),
            booking.getStatus(),
            booking.getSlotCode(),
            booking.getPlanType(),
            booking.getAmount()
        );
    }

    private FacilityDtos.AnnouncementItem toAnnouncement(Announcement announcement) {
        return new FacilityDtos.AnnouncementItem(announcement.getId(), announcement.getTitle(), announcement.getContent(), announcement.getCategory(), announcement.getCreatedAt());
    }

    private BigDecimal resolveAmount(Facility facility, FacilityDtos.CreateBookingRequest request) {
        if (isParkingFacility(facility)) {
            return "yearly".equals(normalizePlanType(request.planType())) ? defaultAmount(facility.getYearlyPrice()) : defaultAmount(facility.getMonthlyPrice());
        }
        return defaultAmount(facility.getOneTimePrice());
    }

    private BigDecimal defaultAmount(BigDecimal amount) {
        return amount == null ? BigDecimal.ZERO : amount;
    }

    private boolean isParkingFacility(Facility facility) {
        return "parking".equalsIgnoreCase(defaultString(facility.getServiceType(), ""));
    }

    private List<String> slotCodes(Facility facility) {
        if (facility.getSlotLayout() == null || facility.getSlotLayout().isBlank()) {
            return List.of();
        }
        return List.of(facility.getSlotLayout().split(",")).stream()
            .map(String::trim)
            .filter(code -> !code.isBlank())
            .toList();
    }

    private List<String> occupiedSlots(Facility facility) {
        if (!isParkingFacility(facility)) {
            return List.of();
        }
        return bookingRepository.findByFacilityIdOrderByBookingDateDesc(facility.getId()).stream()
            .filter(booking -> "Confirmed".equalsIgnoreCase(booking.getStatus()))
            .map(Booking::getSlotCode)
            .filter(slot -> slot != null && !slot.isBlank())
            .distinct()
            .sorted()
            .toList();
    }

    private boolean isSlotOccupied(Long facilityId, String slotCode) {
        return bookingRepository.findByFacilityIdOrderByBookingDateDesc(facilityId).stream()
            .filter(booking -> "Confirmed".equalsIgnoreCase(booking.getStatus()))
            .anyMatch(booking -> slotCode.equalsIgnoreCase(defaultString(booking.getSlotCode(), "")));
    }

    private String normalizeSlotCode(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim().toUpperCase(Locale.ROOT);
    }

    private String normalizePlanType(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        String normalized = value.trim().toLowerCase(Locale.ROOT);
        return switch (normalized) {
            case "monthly", "month" -> "monthly";
            case "yearly", "year" -> "yearly";
            default -> null;
        };
    }

    private String defaultString(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }

    private void applyFacility(Facility facility, FacilityDtos.CreateFacilityRequest request) {
        facility.setName(request.name().trim());
        facility.setArea(request.area().trim());
        facility.setStatus(defaultString(request.status(), "Operational"));
        facility.setHealth(Math.max(0, Math.min(100, request.health())));
        facility.setIcon(defaultString(request.icon(), "build"));
        facility.setDescription(request.description());
        facility.setServiceType(defaultString(request.serviceType(), "shared"));
        facility.setBookingMode(defaultString(request.bookingMode(), "timeslot"));
        facility.setOneTimePrice(defaultAmount(request.oneTimePrice()));
        facility.setMonthlyPrice(defaultAmount(request.monthlyPrice()));
        facility.setYearlyPrice(defaultAmount(request.yearlyPrice()));
        facility.setSlotLayout(request.slotLayout());
        facility.setLastCheckAt(LocalDateTime.now());
    }
}
