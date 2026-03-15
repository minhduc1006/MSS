package com.mss.security.service;

import com.mss.security.model.Incident;
import com.mss.security.model.SecurityLog;
import com.mss.security.repository.IncidentRepository;
import com.mss.security.repository.SecurityLogRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

@Component
public class SecuritySeeder implements CommandLineRunner {
    private final IncidentRepository incidentRepository;
    private final SecurityLogRepository logRepository;

    public SecuritySeeder(IncidentRepository incidentRepository, SecurityLogRepository logRepository) {
        this.incidentRepository = incidentRepository;
        this.logRepository = logRepository;
    }

    @Override
    public void run(String... args) {
        if (incidentRepository.count() > 0) return;
        incident("Unauthorized Access", "A person was seen entering the restricted service elevator area without a keycard.", "Zone B - West Lobby", "Open", "High", "David Miller", LocalDateTime.now().minusMinutes(2));
        incident("Broken Lock", "Assigned to maintenance for parking gate repair.", "P2 Parking - Gate 4", "In-Progress", "Medium", "Sarah Connor", LocalDateTime.now().minusMinutes(15));
        incident("Suspicious Package", "Package identified as resident delivery. Case closed by admin.", "Mailroom - Main Tower", "Resolved", "Low", "Robert Wilson", LocalDateTime.now().minusHours(1));
        log(2L, "resident", "Guest Entry", "John Doe", LocalDateTime.now().withHour(10).withMinute(30), "Authorized");
        log(2L, "resident", "Gate Access", "Resident (Self)", LocalDateTime.now().withHour(8).withMinute(15), "Success");
        log(2L, "resident", "Delivery", "Amazon Courier", LocalDateTime.now().minusDays(1), "Authorized");
        log(8L, "staff", "Guest Entry", "John Doe", LocalDateTime.now().withHour(10).withMinute(30), "Authorized");
        log(8L, "staff", "Gate Access", "Resident (Self)", LocalDateTime.now().withHour(8).withMinute(15), "Success");
        log(8L, "staff", "Delivery", "Amazon Courier", LocalDateTime.now().minusDays(1), "Authorized");
    }

    private void incident(String title, String description, String zone, String status, String severity, String assignedStaffName, LocalDateTime createdAt) {
        Incident incident = new Incident();
        incident.setTitle(title);
        incident.setDescription(description);
        incident.setZone(zone);
        incident.setStatus(status);
        incident.setSeverity(severity);
        incident.setAssignedStaffName(assignedStaffName);
        incident.setCreatedAt(createdAt);
        incidentRepository.save(incident);
    }

    private void log(Long userId, String audience, String event, String visitor, LocalDateTime accessTime, String status) {
        SecurityLog log = new SecurityLog();
        log.setUserId(userId);
        log.setAudience(audience);
        log.setEvent(event);
        log.setVisitor(visitor);
        log.setAccessTime(accessTime);
        log.setStatus(status);
        logRepository.save(log);
    }
}
