package com.mss.operations.service;

import com.mss.operations.model.ActivityLog;
import com.mss.operations.model.StaffTask;
import com.mss.operations.repository.ActivityLogRepository;
import com.mss.operations.repository.StaffTaskRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

@Component
public class OperationsSeeder implements CommandLineRunner {
    private final ActivityLogRepository activityRepository;
    private final StaffTaskRepository taskRepository;

    public OperationsSeeder(ActivityLogRepository activityRepository, StaffTaskRepository taskRepository) {
        this.activityRepository = activityRepository;
        this.taskRepository = taskRepository;
    }

    @Override
    public void run(String... args) {
        if (activityRepository.count() > 0) return;
        activity("billing", "Billing generated for Unit 402", "Monthly maintenance fee processed.", LocalDateTime.now().minusMinutes(2));
        activity("maintenance", "Maintenance Request: Leak", "Unit 105 reported a kitchen sink leak.", LocalDateTime.now().minusMinutes(45));
        activity("onboarding", "New Resident Onboarded", "John Doe moved into Unit 402.", LocalDateTime.now().minusHours(3));
        task(8L, "Check Fire Extinguishers", "Tower A, Floor 1-10", "High", "Pending", "Safety");
        task(8L, "Lobby Cleaning Supervision", "Main Entrance", "Medium", "In Progress", "Operations");
        task(8L, "Pool Water Quality Test", "Amenity Deck", "Low", "Completed", "Facility");
        task(9L, "Repair Gate Lock", "P2 Parking - Gate 4", "High", "In Progress", "Maintenance");
        task(10L, "Concierge Desk Support", "Main Lobby", "Medium", "Completed", "Guest Service");
    }

    private void activity(String type, String title, String description, LocalDateTime at) {
        ActivityLog log = new ActivityLog();
        log.setType(type);
        log.setTitle(title);
        log.setDescription(description);
        log.setCreatedAt(at);
        activityRepository.save(log);
    }

    private void task(Long staffId, String title, String zone, String priority, String status, String category) {
        StaffTask task = new StaffTask();
        task.setAssignedStaffId(staffId);
        task.setTitle(title);
        task.setZone(zone);
        task.setPriority(priority);
        task.setStatus(status);
        task.setCategory(category);
        taskRepository.save(task);
    }
}
