package com.mss.facility.repository;

import com.mss.facility.model.MaintenanceLog;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MaintenanceLogRepository extends JpaRepository<MaintenanceLog, Long> {
    List<MaintenanceLog> findByFacilityIdOrderByCreatedAtDesc(Long facilityId);
    void deleteByFacilityId(Long facilityId);
}
