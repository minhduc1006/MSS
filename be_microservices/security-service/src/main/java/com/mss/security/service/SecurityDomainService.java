package com.mss.security.service;

import com.mss.security.dto.SecurityDtos;
import com.mss.security.model.Incident;
import com.mss.security.model.SecurityLog;
import com.mss.security.repository.IncidentRepository;
import com.mss.security.repository.SecurityLogRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class SecurityDomainService {
    private final IncidentRepository incidentRepository;
    private final SecurityLogRepository logRepository;

    public SecurityDomainService(IncidentRepository incidentRepository, SecurityLogRepository logRepository) {
        this.incidentRepository = incidentRepository;
        this.logRepository = logRepository;
    }

    public SecurityDtos.SecurityOverview overview() {
        return new SecurityDtos.SecurityOverview(incidentRepository.findAllByOrderByCreatedAtDesc().stream().map(this::toIncident).toList(), logRepository.findAllByOrderByAccessTimeDesc().stream().limit(8).map(this::toLog).toList());
    }

    public SecurityDtos.IncidentItem createIncident(SecurityDtos.CreateIncidentRequest request) {
        Incident incident = new Incident();
        incident.setTitle(request.title().trim());
        incident.setDescription(request.description().trim());
        incident.setZone(request.zone().trim());
        incident.setSeverity(request.severity().trim());
        incident.setStatus("Open");
        incident.setAssignedStaffName("Unassigned");
        incident.setCreatedAt(LocalDateTime.now());
        Incident savedIncident = incidentRepository.save(incident);

        if (request.userId() != null && request.userId() > 0) {
            SecurityLog log = new SecurityLog();
            log.setUserId(request.userId());
            log.setAudience(hasText(request.audience()) ? request.audience().trim() : "resident");
            log.setEvent("Incident Report");
            log.setVisitor("User " + request.userId());
            log.setAccessTime(LocalDateTime.now());
            log.setStatus("Reported");
            logRepository.save(log);
        }

        return toIncident(savedIncident);
    }

    public SecurityDtos.IncidentItem updateIncident(Long incidentId, SecurityDtos.UpdateIncidentRequest request) {
        Incident incident = incidentRepository.findById(incidentId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Incident not found"));
        incident.setTitle(request.title().trim());
        incident.setDescription(request.description().trim());
        incident.setZone(request.zone().trim());
        incident.setStatus(request.status().trim());
        incident.setSeverity(request.severity().trim());
        incident.setAssignedStaffName(hasText(request.assignedStaffName()) ? request.assignedStaffName().trim() : "Unassigned");
        return toIncident(incidentRepository.save(incident));
    }

    public SecurityDtos.IncidentItem updateIncidentStatus(Long incidentId, SecurityDtos.UpdateIncidentStatusRequest request) {
        Incident incident = incidentRepository.findById(incidentId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Incident not found"));
        incident.setStatus(request.status().trim());
        return toIncident(incidentRepository.save(incident));
    }

    public SecurityDtos.IncidentItem deactivateIncident(Long incidentId) {
        Incident incident = incidentRepository.findById(incidentId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Incident not found"));
        incident.setStatus("Deactivated");
        return toIncident(incidentRepository.save(incident));
    }

    public SecurityDtos.IncidentItem triggerSos(SecurityDtos.TriggerSosRequest request) {
        Incident incident = new Incident();
        incident.setTitle("SOS Alert - User " + request.userId());
        incident.setDescription("Emergency alert triggered from mobile app.");
        incident.setZone(request.audience().equals("staff") ? "Operations Floor" : "Resident Tower");
        incident.setSeverity("Critical");
        incident.setStatus("Open");
        incident.setAssignedStaffName("Security Team");
        incident.setCreatedAt(LocalDateTime.now());
        Incident saved = incidentRepository.save(incident);
        SecurityLog log = new SecurityLog();
        log.setUserId(request.userId());
        log.setAudience(request.audience());
        log.setEvent("Emergency SOS");
        log.setVisitor("User " + request.userId());
        log.setAccessTime(LocalDateTime.now());
        log.setStatus("Alerted");
        logRepository.save(log);
        return toIncident(saved);
    }

    public SecurityDtos.SecurityHistoryResponse history(Long userId, String audience) {
        List<SecurityLog> logs = userId > 0 ? logRepository.findByUserIdOrderByAccessTimeDesc(userId) : logRepository.findByAudienceOrderByAccessTimeDesc(audience);
        return new SecurityDtos.SecurityHistoryResponse((audience.equals("staff") ? "OPS-STAFF" : "SH-" + userId), logs.stream().map(this::toLog).toList());
    }

    private SecurityDtos.IncidentItem toIncident(Incident incident) {
        return new SecurityDtos.IncidentItem(incident.getId(), incident.getTitle(), incident.getDescription(), incident.getZone(), incident.getStatus(), incident.getSeverity(), incident.getAssignedStaffName(), incident.getCreatedAt());
    }

    private SecurityDtos.SecurityLogItem toLog(SecurityLog log) {
        return new SecurityDtos.SecurityLogItem(log.getId(), log.getAudience(), log.getEvent(), log.getVisitor(), log.getAccessTime(), log.getStatus());
    }

    private boolean hasText(String value) {
        return value != null && !value.isBlank();
    }
}
