package com.mss.auth.service;

import com.mss.auth.model.AppUser;
import com.mss.auth.repository.AppUserRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Component
public class AuthSeeder implements CommandLineRunner {
    private final AppUserRepository repository;

    public AuthSeeder(AppUserRepository repository) {
        this.repository = repository;
    }

    @Override
    public void run(String... args) {
        ensure("admin@skyline.com", "System Admin", "admin", null, null, null, null, "100", "Active", null, 0, 0, 8);
        ensure("admin@fpt.edu.vn", "FPT Admin", "admin", null, null, null, null, "100", "Active", null, 0, 0, 8);
        ensure("duclmhe182023@fpt.edu.vn", "Duc LM HE182023", "admin", null, null, null, null, "100", "Active", null, 0, 0, 8);
        ensure("john.doe@skyline.com", "John Doe", "resident", "402", "Skyview Tower", null, null, null, "Active", "Active", 4, 3, 0);
        ensure("alex.t@example.com", "Alex Thompson", "resident", "402B", "Skyview Tower", null, null, null, "Active", "Active", 1, 1, 0);
        ensure("s.jenkins@corp.com", "Sarah Jenkins", "resident", "115A", "Ocean Tower", null, null, null, "Active", "Ending Soon", 1, 0, 0);
        ensure("m.rivera@web.com", "Michael Rivera", "resident", "303C", "Garden Tower", null, null, null, "Inactive", "Move-out", 1, 0, 0);
        ensure("elena.rossi@skyline.com", "Elena Rossi", "resident", "208", "Skyview Tower", null, null, null, "Active", "Active", 1, 0, 0);
        ensure("jordan.lee@skyline.com", "Jordan Lee", "resident", "312", "Garden Tower", null, null, null, "Active", "Active", 1, 0, 0);
        ensure("ducdayne04@gmail.com", "Đức Dayne", "resident", "508", "Skyline Heights", null, null, null, "Active", "Active", 3, 2, 1);
        ensure("david.miller@skyline.com", "David Miller", "staff", null, null, "Day", "Security Officer", "+1 (555) 123-4567", "On Duty", null, 0, 0, 0);
        ensure("s.connor@skyline.com", "Sarah Connor", "staff", null, null, "Night", "Maintenance Lead", "+1 (555) 987-6543", "Off Duty", null, 0, 0, 0);
        ensure("r.wilson@skyline.com", "Robert Wilson", "staff", null, null, "Day", "Concierge", "+1 (555) 456-7890", "On Duty", null, 0, 0, 0);
        ensure("minhduc10604@gmail.com", "Minh Đức", "staff", null, null, "Day", "Operations Coordinator", "+84 909 106 604", "On Duty", null, 0, 0, 0);
    }

    private void ensure(String email, String name, String role, String unitNumber, String tower, String shift, String jobTitle, String phone, String status, String leaseStatus, long billCount, long guestCount, long openIssueCount) {
        AppUser user = repository.findByEmailIgnoreCase(email).orElseGet(AppUser::new);
        user.setEmail(email);
        user.setPassword("password123");
        user.setFullName(name);
        user.setRole(role);
        user.setUnitNumber(unitNumber);
        user.setTower(tower);
        user.setShift(shift);
        user.setJobTitle(jobTitle);
        user.setPhone(phone);
        user.setStatus(status);
        user.setLeaseStatus(leaseStatus);
        user.setBillCount(billCount);
        user.setGuestCount(guestCount);
        user.setOpenIssueCount(openIssueCount);
        user.setAvatarUrl("https://api.dicebear.com/9.x/initials/svg?seed=" + name.replace(" ", "%20"));
        repository.save(user);
    }
}
