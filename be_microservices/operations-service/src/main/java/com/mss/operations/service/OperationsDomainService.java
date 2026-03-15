package com.mss.operations.service;

import com.mss.operations.dto.OperationsDtos;
import com.mss.operations.model.ActivityLog;
import com.mss.operations.model.StaffTask;
import com.mss.operations.repository.ActivityLogRepository;
import com.mss.operations.repository.StaffTaskRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class OperationsDomainService {
    private final ActivityLogRepository activityRepository;
    private final StaffTaskRepository taskRepository;

    public OperationsDomainService(ActivityLogRepository activityRepository, StaffTaskRepository taskRepository) {
        this.activityRepository = activityRepository;
        this.taskRepository = taskRepository;
    }

    public List<OperationsDtos.ActivityItem> activities() {
        return activityRepository.findTop5ByOrderByCreatedAtDesc().stream().map(this::toActivity).toList();
    }

    public OperationsDtos.TaskBundle tasks(Long staffId) {
        List<StaffTask> tasks = taskRepository.findByAssignedStaffIdOrderByIdAsc(staffId);
        return new OperationsDtos.TaskBundle(tasks.size(), tasks.stream().filter(task -> "Completed".equalsIgnoreCase(task.getStatus())).count(), tasks.stream().map(this::toTask).toList());
    }

    private OperationsDtos.ActivityItem toActivity(ActivityLog log) {
        return new OperationsDtos.ActivityItem(log.getId(), log.getType(), log.getTitle(), log.getDescription(), log.getCreatedAt());
    }

    private OperationsDtos.TaskItem toTask(StaffTask task) {
        return new OperationsDtos.TaskItem(task.getId(), task.getTitle(), task.getZone(), task.getPriority(), task.getStatus(), task.getCategory());
    }
}
