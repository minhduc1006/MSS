package com.mss.operations.dto;

import java.time.LocalDateTime;
import java.util.List;

public final class OperationsDtos {
    private OperationsDtos() {}
    public record ActivityItem(Long id, String type, String title, String description, LocalDateTime createdAt) {}
    public record TaskItem(Long id, String title, String zone, String priority, String status, String category) {}
    public record TaskBundle(long totalTasks, long completedTasks, List<TaskItem> tasks) {}
}
