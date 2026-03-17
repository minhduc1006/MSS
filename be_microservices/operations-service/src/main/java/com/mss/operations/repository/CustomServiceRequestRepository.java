package com.mss.operations.repository;

import com.mss.operations.model.CustomServiceRequest;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CustomServiceRequestRepository extends JpaRepository<CustomServiceRequest, Long> {
    List<CustomServiceRequest> findAllByOrderByCreatedAtDesc();
    List<CustomServiceRequest> findByResidentIdOrderByCreatedAtDesc(Long residentId);
    List<CustomServiceRequest> findByAssignedStaffIdOrderByCreatedAtDesc(Long assignedStaffId);
}
