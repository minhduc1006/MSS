package com.mss.operations.repository;

import com.mss.operations.model.StaffTask;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface StaffTaskRepository extends JpaRepository<StaffTask, Long> {
    List<StaffTask> findByAssignedStaffIdOrderByIdAsc(Long assignedStaffId);
}
