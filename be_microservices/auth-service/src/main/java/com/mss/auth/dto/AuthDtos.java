package com.mss.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public final class AuthDtos {
    private AuthDtos() {}

    public record LoginRequest(@NotBlank @Email String email, @NotBlank String password, @NotBlank String role) {}
    public record UserResponse(Long id, String fullName, String email, String role, String unitNumber, String tower, String avatarUrl) {}
    public record ResidentItem(Long id, String fullName, String unitNumber, String tower, String leaseStatus, String email, String status, String avatarUrl) {}
    public record StaffItem(Long id, String fullName, String role, String shift, String email, String phone, String status, String avatarUrl) {}
    public record AccountStats(long billCount, long guestCount, long openIssueCount) {}
    public record AccountResponse(UserResponse user, AccountStats stats) {}
    public record CreateResidentRequest(@NotBlank String fullName, @NotBlank String unitNumber, @NotBlank String tower, @NotBlank @Email String email) {}
    public record CreateStaffRequest(
        @NotBlank String fullName,
        @NotBlank String jobTitle,
        @NotBlank String shift,
        @NotBlank @Email String email,
        @NotBlank String phone
    ) {}
    public record UpdateStaffRequest(
        @NotBlank String fullName,
        @NotBlank String jobTitle,
        @NotBlank String shift,
        @NotBlank @Email String email,
        @NotBlank String phone,
        @NotBlank String status
    ) {}
    public record ChangePasswordRequest(@NotBlank String currentPassword, @NotBlank String newPassword) {}
    public record RequestPasswordResetOtpRequest(@NotBlank @Email String email) {}
    public record VerifyPasswordResetOtpRequest(@NotBlank @Email String email, @NotBlank String otp) {}
    public record CompletePasswordResetRequest(@NotBlank @Email String email, @NotBlank String resetToken, @NotBlank String newPassword) {}
    public record PasswordResetOtpResponse(String message) {}
    public record VerifyPasswordResetOtpResponse(String resetToken, String message) {}
}
