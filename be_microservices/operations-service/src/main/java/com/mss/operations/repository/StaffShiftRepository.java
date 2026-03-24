package com.mss.operations.repository;

import com.mss.operations.model.StaffShift;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface StaffShiftRepository extends JpaRepository<StaffShift, Long> {
    List<StaffShift> findAllByOrderByShiftDateAscStartTimeAsc();
    List<StaffShift> findByStaffIdOrderByShiftDateAscStartTimeAsc(Long staffId);
}
