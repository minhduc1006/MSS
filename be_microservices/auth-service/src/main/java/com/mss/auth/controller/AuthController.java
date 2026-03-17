package com.mss.auth.controller;

import com.mss.auth.dto.AuthDtos;
import com.mss.auth.service.AuthDomainService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.List;

@RestController
@RequestMapping("/api")
public class AuthController {
    private final AuthDomainService service;

    public AuthController(AuthDomainService service) {
        this.service = service;
    }

    @PostMapping("/auth/login")
    public AuthDtos.UserResponse login(@Valid @RequestBody AuthDtos.LoginRequest request) {
        return service.login(request);
    }

    @PostMapping("/auth/reset-password/request-otp")
    public AuthDtos.PasswordResetOtpResponse requestPasswordResetOtp(@Valid @RequestBody AuthDtos.RequestPasswordResetOtpRequest request) {
        return service.requestPasswordResetOtp(request);
    }

    @PostMapping("/auth/reset-password/verify-otp")
    public AuthDtos.VerifyPasswordResetOtpResponse verifyPasswordResetOtp(@Valid @RequestBody AuthDtos.VerifyPasswordResetOtpRequest request) {
        return service.verifyPasswordResetOtp(request);
    }

    @PostMapping("/auth/reset-password/complete")
    public void completePasswordReset(@Valid @RequestBody AuthDtos.CompletePasswordResetRequest request) {
        service.completePasswordReset(request);
    }

    @GetMapping("/users/residents")
    public List<AuthDtos.ResidentItem> residents() {
        return service.getResidents();
    }

    @PostMapping("/users/residents")
    public AuthDtos.ResidentItem createResident(@Valid @RequestBody AuthDtos.CreateResidentRequest request) {
        return service.createResident(request);
    }

    @DeleteMapping("/users/residents/{id}")
    public void deleteResident(@PathVariable Long id) {
        service.deleteResident(id);
    }

    @PostMapping("/users/residents/{id}/activate")
    public void activateResident(@PathVariable Long id) {
        service.activateResident(id);
    }

    @GetMapping("/users/staff")
    public List<AuthDtos.StaffItem> staff() {
        return service.getStaff();
    }

    @GetMapping("/users/admins")
    public List<AuthDtos.AdminContactItem> admins() {
        return service.getAdminContacts();
    }

    @PostMapping("/users/staff")
    public AuthDtos.StaffItem createStaff(@Valid @RequestBody AuthDtos.CreateStaffRequest request) {
        return service.createStaff(request);
    }

    @PutMapping("/users/staff/{id}")
    public AuthDtos.StaffItem updateStaff(@PathVariable Long id, @Valid @RequestBody AuthDtos.UpdateStaffRequest request) {
        return service.updateStaff(id, request);
    }

    @DeleteMapping("/users/staff/{id}")
    public void deleteStaff(@PathVariable Long id) {
        service.deleteStaff(id);
    }

    @PostMapping("/users/staff/{id}/activate")
    public void activateStaff(@PathVariable Long id) {
        service.activateStaff(id);
    }

    @GetMapping("/users/{id}")
    public AuthDtos.UserResponse user(@PathVariable Long id) {
        return service.getUser(id);
    }

    @GetMapping("/users/by-email")
    public AuthDtos.UserResponse userByEmail(@RequestParam String email) {
        return service.getUserByEmail(email);
    }

    @GetMapping("/users/{id}/account")
    public AuthDtos.AccountResponse account(@PathVariable Long id) {
        return service.getAccount(id);
    }

    @GetMapping("/users/{id}/settings")
    public AuthDtos.AccountResponse settings(@PathVariable Long id) {
        return service.getAccount(id);
    }

    @PostMapping("/users/{id}/change-password")
    public void changePassword(@PathVariable Long id, @Valid @RequestBody AuthDtos.ChangePasswordRequest request) {
        service.changePassword(id, request);
    }
}
