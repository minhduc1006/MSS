package com.mss.operations.model;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
public class CustomServiceRequest {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private Long residentId;
    private String residentName;
    private String unitNumber;
    private String title;
    private String description;
    private String zone;
    private String preferredSchedule;
    private String status;
    private Long assignedStaffId;
    private String assignedStaffName;
    private BigDecimal quotedPrice;
    private String quoteNote;
    private String residentDecisionNote;
    private LocalDateTime createdAt;

    public Long getId() { return id; }
    public Long getResidentId() { return residentId; }
    public void setResidentId(Long residentId) { this.residentId = residentId; }
    public String getResidentName() { return residentName; }
    public void setResidentName(String residentName) { this.residentName = residentName; }
    public String getUnitNumber() { return unitNumber; }
    public void setUnitNumber(String unitNumber) { this.unitNumber = unitNumber; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getZone() { return zone; }
    public void setZone(String zone) { this.zone = zone; }
    public String getPreferredSchedule() { return preferredSchedule; }
    public void setPreferredSchedule(String preferredSchedule) { this.preferredSchedule = preferredSchedule; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public Long getAssignedStaffId() { return assignedStaffId; }
    public void setAssignedStaffId(Long assignedStaffId) { this.assignedStaffId = assignedStaffId; }
    public String getAssignedStaffName() { return assignedStaffName; }
    public void setAssignedStaffName(String assignedStaffName) { this.assignedStaffName = assignedStaffName; }
    public BigDecimal getQuotedPrice() { return quotedPrice; }
    public void setQuotedPrice(BigDecimal quotedPrice) { this.quotedPrice = quotedPrice; }
    public String getQuoteNote() { return quoteNote; }
    public void setQuoteNote(String quoteNote) { this.quoteNote = quoteNote; }
    public String getResidentDecisionNote() { return residentDecisionNote; }
    public void setResidentDecisionNote(String residentDecisionNote) { this.residentDecisionNote = residentDecisionNote; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
