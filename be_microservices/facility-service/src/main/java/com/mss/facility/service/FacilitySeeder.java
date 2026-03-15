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

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

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
    public void run(String... args) {
        if (facilityRepository.count() > 0) return;
        Facility pool = facility("Swimming Pool", "Amenity Deck", "Operational", 98, LocalDateTime.now().minusHours(2), "pool");
        Facility gym = facility("Gymnasium", "Wellness Floor", "Maintenance", 65, LocalDateTime.now().minusDays(1), "gym");
        Facility elevator = facility("Elevator B2", "Tower B Core", "Operational", 92, LocalDateTime.now().minusHours(5), "elevator");
        Facility lights = facility("Lobby Lighting", "Main Entrance", "Issue Reported", 40, LocalDateTime.now().minusMinutes(10), "lightbulb");
        Facility lounge = facility("Community Lounge", "Floor 3", "Operational", 88, LocalDateTime.now().minusHours(4), "lounge");
        log(pool, "PH levels checked", "David Miller", LocalDateTime.now().minusHours(2), true);
        log(pool, "Chlorine added", "David Miller", LocalDateTime.now().minusHours(3), true);
        log(gym, "Treadmill #3 motor issue", "Sarah Connor", LocalDateTime.now().minusDays(1), false);
        log(gym, "Cable machine lubricated", "Sarah Connor", LocalDateTime.now().minusDays(2), false);
        log(elevator, "Door sensor cleaned", "Robert Wilson", LocalDateTime.now().minusHours(5), true);
        log(lights, "3 bulbs flickering", "Sarah Connor", LocalDateTime.now().minusMinutes(20), false);
        booking(2L, lounge, "Community Lounge", LocalDate.now(), "06:00 PM - 08:00 PM", "Confirmed");
        booking(2L, pool, "Swimming Pool", LocalDate.now().plusDays(1), "08:00 AM - 10:00 AM", "Confirmed");
        announcement("Elevator maintenance on Monday", "Elevator B will be out of service from 9 AM to 3 PM for scheduled maintenance.", "maintenance", LocalDateTime.now().minusHours(2));
        announcement("Pool deck cleaning", "The pool deck will close at 8 PM tonight for scheduled cleaning.", "facility", LocalDateTime.now().minusHours(6));
        announcement("Community fire drill", "A building-wide fire drill is scheduled for Friday at 10 AM.", "safety", LocalDateTime.now().minusDays(1));
    }

    private Facility facility(String name, String area, String status, int health, LocalDateTime checkedAt, String icon) {
        Facility facility = new Facility();
        facility.setName(name);
        facility.setArea(area);
        facility.setStatus(status);
        facility.setHealth(health);
        facility.setLastCheckAt(checkedAt);
        facility.setIcon(icon);
        return facilityRepository.save(facility);
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
        Booking booking = new Booking();
        booking.setResidentId(residentId);
        booking.setFacilityId(facility.getId());
        booking.setTitle(title);
        booking.setBookingDate(date);
        booking.setTimeSlot(slot);
        booking.setStatus(status);
        bookingRepository.save(booking);
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
