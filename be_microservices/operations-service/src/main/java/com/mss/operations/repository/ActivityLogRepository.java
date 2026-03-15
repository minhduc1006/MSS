package com.mss.operations.repository;

import com.mss.operations.model.ActivityLog;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ActivityLogRepository extends JpaRepository<ActivityLog, Long> {
    List<ActivityLog> findTop5ByOrderByCreatedAtDesc();
}
