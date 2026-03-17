package com.mss.auth.service;

import com.mss.auth.dto.AuthDtos;
import com.mss.auth.model.AppUser;
import com.mss.auth.repository.AppUserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;

@Service
public class AuthDomainService {
    private final AppUserRepository repository;
    private final AuthEmailService authEmailService;

    public AuthDomainService(AppUserRepository repository, AuthEmailService authEmailService) {
        this.repository = repository;
        this.authEmailService = authEmailService;
    }

    public AuthDtos.UserResponse login(AuthDtos.LoginRequest request) {
        AppUser user = resolveUserByEmail(request.email(), request.role())
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid credentials"));
        if (!user.getPassword().equals(request.password())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid credentials");
        }
        if (!user.getRole().equalsIgnoreCase(request.role()) || isDeactivated(user.getStatus())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Access denied");
        }
        return toUser(user);
    }

    public AuthDtos.PasswordResetOtpResponse requestPasswordResetOtp(AuthDtos.RequestPasswordResetOtpRequest request) {
        AppUser user = repository.findByEmailIgnoreCase(request.email())
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));
        user.setPasswordResetOtp(generateOtp());
        user.setPasswordResetOtpExpiresAt(LocalDateTime.now().plusMinutes(15));
        user.setPasswordResetToken(null);
        user.setPasswordResetTokenExpiresAt(null);
        repository.save(user);
        authEmailService.sendPasswordResetOtp(user, user.getPasswordResetOtp());
        return new AuthDtos.PasswordResetOtpResponse("OTP has been sent to the user's email.");
    }

    public AuthDtos.VerifyPasswordResetOtpResponse verifyPasswordResetOtp(AuthDtos.VerifyPasswordResetOtpRequest request) {
        AppUser user = repository.findByEmailIgnoreCase(request.email())
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));
        if (!hasText(user.getPasswordResetOtp()) || user.getPasswordResetOtpExpiresAt() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "No OTP request found for this email");
        }
        if (user.getPasswordResetOtpExpiresAt().isBefore(LocalDateTime.now())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "OTP has expired");
        }
        if (!user.getPasswordResetOtp().equals(request.otp().trim())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "OTP is incorrect");
        }

        String resetToken = UUID.randomUUID().toString();
        user.setPasswordResetOtp(null);
        user.setPasswordResetOtpExpiresAt(null);
        user.setPasswordResetToken(resetToken);
        user.setPasswordResetTokenExpiresAt(LocalDateTime.now().plusMinutes(15));
        repository.save(user);
        return new AuthDtos.VerifyPasswordResetOtpResponse(resetToken, "OTP verified successfully.");
    }

    public void completePasswordReset(AuthDtos.CompletePasswordResetRequest request) {
        AppUser user = repository.findByEmailIgnoreCase(request.email())
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));
        if (!hasText(user.getPasswordResetToken()) || user.getPasswordResetTokenExpiresAt() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Reset session is invalid or missing");
        }
        if (user.getPasswordResetTokenExpiresAt().isBefore(LocalDateTime.now())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Reset session has expired");
        }
        if (!user.getPasswordResetToken().equals(request.resetToken().trim())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Reset session is invalid");
        }

        user.setPassword(request.newPassword());
        user.setPasswordResetToken(null);
        user.setPasswordResetTokenExpiresAt(null);
        user.setPasswordResetOtp(null);
        user.setPasswordResetOtpExpiresAt(null);
        repository.save(user);
    }

    public List<AuthDtos.ResidentItem> getResidents() {
        return repository.findByRoleOrderByFullNameAsc("resident").stream()
            .sorted(userComparator())
            .map(this::toResident)
            .toList();
    }

    public List<AuthDtos.AdminContactItem> getAdminContacts() {
        return repository.findByRoleOrderByFullNameAsc("admin").stream()
            .sorted(userComparator())
            .map(this::toAdminContact)
            .toList();
    }

    public AuthDtos.ResidentItem createResident(AuthDtos.CreateResidentRequest request) {
        ensureEmailAvailable(request.email(), null);
        AppUser user = new AppUser();
        user.setEmail(request.email());
        user.setPassword("password123");
        user.setFullName(request.fullName());
        user.setRole("resident");
        user.setUnitNumber(request.unitNumber());
        user.setTower(request.tower());
        user.setStatus("Active");
        user.setLeaseStatus("Active");
        user.setAvatarUrl("https://api.dicebear.com/9.x/initials/svg?seed=" + request.fullName().replace(" ", "%20"));
        return toResident(repository.save(user));
    }

    public List<AuthDtos.StaffItem> getStaff() {
        return repository.findByRoleOrderByFullNameAsc("staff").stream()
            .sorted(userComparator())
            .map(this::toStaff)
            .toList();
    }

    public void deleteResident(Long id) {
        AppUser user = findUser(id);
        if (!"resident".equalsIgnoreCase(user.getRole())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "User is not a resident");
        }
        user.setStatus("Deactivated");
        user.setLeaseStatus("Inactive");
        repository.save(user);
    }

    public void activateResident(Long id) {
        AppUser user = findUser(id);
        if (!"resident".equalsIgnoreCase(user.getRole())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "User is not a resident");
        }
        user.setStatus("Active");
        user.setLeaseStatus("Active");
        repository.save(user);
    }

    public AuthDtos.StaffItem createStaff(AuthDtos.CreateStaffRequest request) {
        ensureEmailAvailable(request.email(), null);
        AppUser user = new AppUser();
        user.setEmail(request.email());
        user.setPassword("password123");
        user.setFullName(request.fullName());
        user.setRole("staff");
        user.setJobTitle(request.jobTitle());
        user.setShift(request.shift());
        user.setPhone(request.phone());
        user.setStatus("On Duty");
        user.setAvatarUrl("https://api.dicebear.com/9.x/initials/svg?seed=" + request.fullName().replace(" ", "%20"));
        return toStaff(repository.save(user));
    }

    public AuthDtos.StaffItem updateStaff(Long id, AuthDtos.UpdateStaffRequest request) {
        AppUser user = findUser(id);
        if (!"staff".equalsIgnoreCase(user.getRole())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "User is not a staff member");
        }

        ensureEmailAvailable(request.email(), id);
        user.setEmail(request.email());
        user.setFullName(request.fullName());
        user.setJobTitle(request.jobTitle());
        user.setShift(request.shift());
        user.setPhone(request.phone());
        user.setStatus(request.status());
        user.setAvatarUrl("https://api.dicebear.com/9.x/initials/svg?seed=" + request.fullName().replace(" ", "%20"));
        return toStaff(repository.save(user));
    }

    public void deleteStaff(Long id) {
        AppUser user = findUser(id);
        if (!"staff".equalsIgnoreCase(user.getRole())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "User is not a staff member");
        }
        user.setStatus("Deactivated");
        repository.save(user);
    }

    public void activateStaff(Long id) {
        AppUser user = findUser(id);
        if (!"staff".equalsIgnoreCase(user.getRole())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "User is not a staff member");
        }
        user.setStatus("Off Duty");
        repository.save(user);
    }

    public AuthDtos.UserResponse getUser(Long id) {
        return toUser(findUser(id));
    }

    public AuthDtos.UserResponse getUserByEmail(String email) {
        AppUser user = resolveUserByEmail(email, "admin")
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));
        return toUser(user);
    }

    public AuthDtos.AccountResponse getAccount(Long id) {
        AppUser user = findUser(id);
        return new AuthDtos.AccountResponse(toUser(user), new AuthDtos.AccountStats(user.getBillCount(), user.getGuestCount(), user.getOpenIssueCount()));
    }

    public void changePassword(Long id, AuthDtos.ChangePasswordRequest request) {
        AppUser user = findUser(id);
        if (!user.getPassword().equals(request.currentPassword())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Current password is incorrect");
        }
        user.setPassword(request.newPassword());
        repository.save(user);
    }

    private AppUser findUser(Long id) {
        return repository.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));
    }

    private void ensureEmailAvailable(String email, Long excludedId) {
        repository.findByEmailIgnoreCase(email).ifPresent(existing -> {
            if (excludedId == null || !existing.getId().equals(excludedId)) {
                throw new ResponseStatusException(HttpStatus.CONFLICT, "Email already exists");
            }
        });
    }

    private java.util.Optional<AppUser> resolveUserByEmail(String email, String requestedRole) {
        return repository.findByEmailIgnoreCase(email)
            .or(() -> provisionFptAdmin(email, requestedRole));
    }

    private java.util.Optional<AppUser> provisionFptAdmin(String email, String requestedRole) {
        if (!email.toLowerCase().endsWith("@fpt.edu.vn") || !"admin".equalsIgnoreCase(requestedRole)) {
            return java.util.Optional.empty();
        }

        AppUser user = new AppUser();
        user.setEmail(email);
        user.setPassword("password123");
        user.setFullName(toDisplayName(email));
        user.setRole("admin");
        user.setStatus("Active");
        user.setBillCount(0);
        user.setGuestCount(0);
        user.setOpenIssueCount(0);
        user.setAvatarUrl("https://api.dicebear.com/9.x/initials/svg?seed=" + user.getFullName().replace(" ", "%20"));
        return java.util.Optional.of(repository.save(user));
    }

    private String toDisplayName(String email) {
        String localPart = email.split("@")[0].replace('.', ' ').replace('_', ' ').trim();
        if (localPart.isEmpty()) {
            return "FPT Admin";
        }

        String[] parts = localPart.split("\\s+");
        StringBuilder builder = new StringBuilder();
        for (String part : parts) {
            if (part.isBlank()) {
                continue;
            }
            if (!builder.isEmpty()) {
                builder.append(' ');
            }
            builder.append(Character.toUpperCase(part.charAt(0)));
            if (part.length() > 1) {
                builder.append(part.substring(1));
            }
        }
        return builder.isEmpty() ? "FPT Admin" : builder + " (FPT)";
    }

    private Comparator<AppUser> userComparator() {
        return Comparator
            .comparing((AppUser user) -> isDeactivated(user.getStatus()))
            .thenComparing(user -> user.getFullName() == null ? "" : user.getFullName(), String.CASE_INSENSITIVE_ORDER);
    }

    private boolean isDeactivated(String status) {
        return "Deactivated".equalsIgnoreCase(status);
    }

    private String generateOtp() {
        return "%06d".formatted(ThreadLocalRandom.current().nextInt(0, 1_000_000));
    }

    private boolean hasText(String value) {
        return value != null && !value.isBlank();
    }

    private AuthDtos.UserResponse toUser(AppUser user) {
        return new AuthDtos.UserResponse(user.getId(), user.getFullName(), user.getEmail(), user.getRole(), user.getUnitNumber(), user.getTower(), user.getAvatarUrl());
    }

    private AuthDtos.ResidentItem toResident(AppUser user) {
        return new AuthDtos.ResidentItem(user.getId(), user.getFullName(), user.getUnitNumber(), user.getTower(), user.getLeaseStatus(), user.getEmail(), user.getStatus(), user.getAvatarUrl());
    }

    private AuthDtos.StaffItem toStaff(AppUser user) {
        return new AuthDtos.StaffItem(user.getId(), user.getFullName(), user.getJobTitle(), user.getShift(), user.getEmail(), user.getPhone(), user.getStatus(), user.getAvatarUrl());
    }

    private AuthDtos.AdminContactItem toAdminContact(AppUser user) {
        return new AuthDtos.AdminContactItem(
            user.getId(),
            user.getFullName(),
            user.getEmail(),
            user.getPhone(),
            user.getStatus(),
            user.getAvatarUrl()
        );
    }
}
