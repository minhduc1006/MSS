package com.mss.operations.repository;

import com.mss.operations.model.PackageRecord;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PackageRecordRepository extends JpaRepository<PackageRecord, Long> {
    List<PackageRecord> findAllByOrderByReceivedAtDesc();
    List<PackageRecord> findByResidentIdOrderByReceivedAtDesc(Long residentId);
}
