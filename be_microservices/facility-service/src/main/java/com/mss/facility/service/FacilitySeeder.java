package com.mss.facility.service;

import com.mss.facility.model.Announcement;
import com.mss.facility.model.Booking;
import com.mss.facility.model.Facility;
import com.mss.facility.model.MaintenanceLog;
import com.mss.facility.repository.AnnouncementRepository;
import com.mss.facility.repository.BookingRepository;
import com.mss.facility.repository.FacilityRepository;
import com.mss.facility.repository.MaintenanceLogRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Locale;

@Component
public class FacilitySeeder implements CommandLineRunner {
    private final FacilityRepository facilityRepository;
    private final MaintenanceLogRepository logRepository;
    private final BookingRepository bookingRepository;
    private final AnnouncementRepository announcementRepository;

    public FacilitySeeder(FacilityRepository facilityRepository, MaintenanceLogRepository logRepository, BookingRepository bookingRepository, AnnouncementRepository announcementRepository) {
        this.facilityRepository = facilityRepository;
        this.logRepository = logRepository;
        this.bookingRepository = bookingRepository;
        this.announcementRepository = announcementRepository;
    }

    @Override
    @Transactional
    public void run(String... args) {
        pruneFacility("Community Lounge");
        pruneFacility("Elevator B2");

        Facility pool = upsertFacility("Swimming Pool", "Amenity Deck", "Operational", 98, LocalDateTime.now().minusHours(2), "pool", "shared", "timeslot", "Outdoor pool access for residents and guests.", BigDecimal.ZERO, null, null, null);
        Facility gym = upsertFacility("Gymnasium", "Wellness Floor", "Operational", 92, LocalDateTime.now().minusHours(6), "gym", "shared", "timeslot", "Fitness center with cardio and weights.", BigDecimal.ZERO, null, null, null);
        Facility lights = upsertFacility("Lobby Lighting", "Main Entrance", "Issue Reported", 40, LocalDateTime.now().minusMinutes(10), "lightbulb", "operations", "none", "Main lobby lighting and ambiance system.", BigDecimal.ZERO, null, null, null);
        Facility housekeeping = upsertFacility("Housekeeping Service", "Resident Home", "Operational", 94, LocalDateTime.now().minusHours(1), "cleaning", "in_unit", "service_request", "Book a housekeeping team for apartment cleaning.", new BigDecimal("250000"), null, null, null);
        Facility repair = upsertFacility("Home Repair Service", "Resident Home", "Operational", 91, LocalDateTime.now().minusHours(1), "build", "in_unit", "service_request", "Request an on-site technician for apartment repairs.", new BigDecimal("350000"), null, null, null);
        Facility acCleaning = upsertFacility("AC Cleaning Service", "Resident Home", "Operational", 90, LocalDateTime.now().minusHours(2), "air", "in_unit", "service_request", "Indoor AC cleaning and filter maintenance service.", new BigDecimal("180000"), null, null, null);
        Facility parking = upsertFacility("Car Parking Subscription", "Basement Parking", "Operational", 96, LocalDateTime.now().minusHours(2), "parking", "parking", "subscription", "Reserve a dedicated monthly or yearly parking slot for your car.", BigDecimal.ZERO, new BigDecimal("800000"), new BigDecimal("8400000"), buildParkingLayout());

        if (logRepository.count() == 0) {
            log(pool, "PH levels checked", "David Miller", LocalDateTime.now().minusHours(2), true);
            log(pool, "Chlorine added", "David Miller", LocalDateTime.now().minusHours(3), true);
            log(gym, "Treadmill #3 motor issue resolved", "Sarah Connor", LocalDateTime.now().minusDays(1), true);
            log(gym, "Cable machine lubricated", "Sarah Connor", LocalDateTime.now().minusDays(2), false);
            log(lights, "3 bulbs flickering", "Sarah Connor", LocalDateTime.now().minusMinutes(20), false);
            log(housekeeping, "Daily cleaning roster synced", "Operations Desk", LocalDateTime.now().minusHours(2), true);
            log(repair, "Technician inventory checked", "Operations Desk", LocalDateTime.now().minusHours(2), true);
            log(acCleaning, "Filter stock replenished", "Operations Desk", LocalDateTime.now().minusHours(3), true);
            log(parking, "Slot occupancy audit completed", "Parking Team", LocalDateTime.now().minusHours(1), true);
        }

        if (bookingRepository.count() == 0) {
            booking(2L, pool, "Swimming Pool", LocalDate.now().plusDays(1), "08:00 AM - 10:00 AM", "Confirmed");
            booking(2L, housekeeping, "Housekeeping Service", LocalDate.now().plusDays(2), "09:00 AM - 11:00 AM", "Confirmed");
        }

        ensureParkingBooking(2L, parking, "A1", "yearly", new BigDecimal("8400000"));
        ensureParkingBooking(3L, parking, "B2", "monthly", new BigDecimal("800000"));
        ensureParkingBooking(4L, parking, "C4", "monthly", new BigDecimal("800000"));
        ensureParkingBooking(5L, parking, "D5", "yearly", new BigDecimal("8400000"));

        if (announcementRepository.count() == 0) {
            announcement("Elevator maintenance on Monday", "Elevator B will be out of service from 9 AM to 3 PM for scheduled maintenance.", "maintenance", LocalDateTime.now().minusHours(2));
            announcement("Pool deck cleaning", "The pool deck will close at 8 PM tonight for scheduled cleaning.", "facility", LocalDateTime.now().minusHours(6));
            announcement("Community fire drill", "A building-wide fire drill is scheduled for Friday at 10 AM.", "safety", LocalDateTime.now().minusDays(1));
        }
    }

    private void pruneFacility(String name) {
        facilityRepository.findAll().stream()
            .filter(existing -> name.equalsIgnoreCase(existing.getName()))
            .findFirst()
            .ifPresent(facility -> {
                bookingRepository.deleteByFacilityId(facility.getId());
                logRepository.deleteByFacilityId(facility.getId());
                facilityRepository.delete(facility);
            });
    }

    private Facility upsertFacility(
        String name,
        String area,
        String status,
        int health,
        LocalDateTime checkedAt,
        String icon,
        String serviceType,
        String bookingMode,
        String description,
        BigDecimal oneTimePrice,
        BigDecimal monthlyPrice,
        BigDecimal yearlyPrice,
        String slotLayout
    ) {
        Facility facility = facilityRepository.findAll().stream()
            .filter(existing -> name.equalsIgnoreCase(existing.getName()))
            .findFirst()
            .orElseGet(Facility::new);
        facility.setName(name);
        facility.setArea(area);
        facility.setStatus(status);
        facility.setHealth(health);
        facility.setLastCheckAt(checkedAt);
        facility.setIcon(icon);
        facility.setServiceType(serviceType);
        facility.setBookingMode(bookingMode);
        facility.setDescription(description);
        facility.setOneTimePrice(oneTimePrice);
        facility.setMonthlyPrice(monthlyPrice);
        facility.setYearlyPrice(yearlyPrice);
        facility.setSlotLayout(slotLayout);
        return facilityRepository.save(facility);
    }

    private String buildParkingLayout() {
        StringBuilder builder = new StringBuilder();
        for (char row = 'A'; row <= 'E'; row++) {
            for (int column = 1; column <= 6; column++) {
                if (builder.length() > 0) {
                    builder.append(",");
                }
                builder.append(row).append(column);
            }
        }
        return builder.toString();
    }

    private void log(Facility facility, String note, String by, LocalDateTime createdAt, boolean operational) {
        MaintenanceLog log = new MaintenanceLog();
        log.setFacilityId(facility.getId());
        log.setNote(note);
        log.setCreatedByName(by);
        log.setCreatedAt(createdAt);
        log.setMarkOperational(operational);
        logRepository.save(log);
    }

    private void booking(Long residentId, Facility facility, String title, LocalDate date, String slot, String status) {
        booking(residentId, facility, title, date, slot, status, null, null, BigDecimal.ZERO);
    }

    private void booking(Long residentId, Facility facility, String title, LocalDate date, String slot, String status, String slotCode, String planType, BigDecimal amount) {
        Booking booking = new Booking();
        booking.setResidentId(residentId);
        booking.setFacilityId(facility.getId());
        booking.setTitle(title);
        booking.setBookingDate(date);
        booking.setTimeSlot(slot);
        booking.setStatus(status);
        booking.setSlotCode(slotCode);
        booking.setPlanType(planType);
        booking.setAmount(amount);
        bookingRepository.save(booking);
    }

    private void ensureParkingBooking(Long residentId, Facility facility, String slotCode, String planType, BigDecimal amount) {
        final String normalizedSlot = slotCode.trim().toUpperCase(Locale.ROOT);
        final boolean exists = bookingRepository.findByFacilityIdOrderByBookingDateDesc(facility.getId()).stream()
            .anyMatch(existing -> normalizedSlot.equalsIgnoreCase(existing.getSlotCode()));
        if (exists) {
            return;
        }
        booking(
            residentId,
            facility,
            "Parking Slot " + normalizedSlot,
            LocalDate.now(),
            "yearly".equalsIgnoreCase(planType) ? "Yearly Subscription" : "Monthly Subscription",
            "Confirmed",
            normalizedSlot,
            planType,
            amount
        );
    }

    private void announcement(String title, String content, String category, LocalDateTime at) {
        Announcement announcement = new Announcement();
        announcement.setTitle(title);
        announcement.setContent(content);
        announcement.setCategory(category);
        announcement.setCreatedAt(at);
        announcementRepository.save(announcement);
    }
}
