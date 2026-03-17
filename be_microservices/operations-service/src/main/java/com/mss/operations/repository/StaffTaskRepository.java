package com.mss.operations.repository;

import com.mss.operations.model.StaffTask;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface StaffTaskRepository extends JpaRepository<StaffTask, Long> {
    List<StaffTask> findByAssignedStaffIdOrderByIdAsc(Long assignedStaffId);
    Optional<StaffTask> findFirstBySourceTypeAndSourceId(String sourceType, Long sourceId);
}
