package com.mss.operations.model;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;

import java.time.LocalDate;

@Entity
public class StaffShift {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private Long staffId;
    private String staffName;
    private String role;
    private LocalDate shiftDate;
    private String shiftLabel;
    private String zone;
    private String startTime;
    private String endTime;
    private String status;
    private String note;

    public Long getId() { return id; }
    public Long getStaffId() { return staffId; }
    public void setStaffId(Long staffId) { this.staffId = staffId; }
    public String getStaffName() { return staffName; }
    public void setStaffName(String staffName) { this.staffName = staffName; }
    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }
    public LocalDate getShiftDate() { return shiftDate; }
    public void setShiftDate(LocalDate shiftDate) { this.shiftDate = shiftDate; }
    public String getShiftLabel() { return shiftLabel; }
    public void setShiftLabel(String shiftLabel) { this.shiftLabel = shiftLabel; }
    public String getZone() { return zone; }
    public void setZone(String zone) { this.zone = zone; }
    public String getStartTime() { return startTime; }
    public void setStartTime(String startTime) { this.startTime = startTime; }
    public String getEndTime() { return endTime; }
    public void setEndTime(String endTime) { this.endTime = endTime; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }
}
