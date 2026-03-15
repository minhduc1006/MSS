package com.mss.auth.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

@Entity
@Table(name = "app_users")
public class AppUser {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String password;

    @Column(nullable = false)
    private String fullName;

    @Column(nullable = false)
    private String role;

    private String unitNumber;
    private String tower;
    private String shift;
    private String jobTitle;
    private String phone;
    private String avatarUrl;
    private String status;
    private String leaseStatus;
    private long billCount;
    private long guestCount;
    private long openIssueCount;
    private String passwordResetOtp;
    private LocalDateTime passwordResetOtpExpiresAt;
    private String passwordResetToken;
    private LocalDateTime passwordResetTokenExpiresAt;

    public Long getId() { return id; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }
    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }
    public String getUnitNumber() { return unitNumber; }
    public void setUnitNumber(String unitNumber) { this.unitNumber = unitNumber; }
    public String getTower() { return tower; }
    public void setTower(String tower) { this.tower = tower; }
    public String getShift() { return shift; }
    public void setShift(String shift) { this.shift = shift; }
    public String getJobTitle() { return jobTitle; }
    public void setJobTitle(String jobTitle) { this.jobTitle = jobTitle; }
    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }
    public String getAvatarUrl() { return avatarUrl; }
    public void setAvatarUrl(String avatarUrl) { this.avatarUrl = avatarUrl; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getLeaseStatus() { return leaseStatus; }
    public void setLeaseStatus(String leaseStatus) { this.leaseStatus = leaseStatus; }
    public long getBillCount() { return billCount; }
    public void setBillCount(long billCount) { this.billCount = billCount; }
    public long getGuestCount() { return guestCount; }
    public void setGuestCount(long guestCount) { this.guestCount = guestCount; }
    public long getOpenIssueCount() { return openIssueCount; }
    public void setOpenIssueCount(long openIssueCount) { this.openIssueCount = openIssueCount; }
    public String getPasswordResetOtp() { return passwordResetOtp; }
    public void setPasswordResetOtp(String passwordResetOtp) { this.passwordResetOtp = passwordResetOtp; }
    public LocalDateTime getPasswordResetOtpExpiresAt() { return passwordResetOtpExpiresAt; }
    public void setPasswordResetOtpExpiresAt(LocalDateTime passwordResetOtpExpiresAt) { this.passwordResetOtpExpiresAt = passwordResetOtpExpiresAt; }
    public String getPasswordResetToken() { return passwordResetToken; }
    public void setPasswordResetToken(String passwordResetToken) { this.passwordResetToken = passwordResetToken; }
    public LocalDateTime getPasswordResetTokenExpiresAt() { return passwordResetTokenExpiresAt; }
    public void setPasswordResetTokenExpiresAt(LocalDateTime passwordResetTokenExpiresAt) { this.passwordResetTokenExpiresAt = passwordResetTokenExpiresAt; }
}
