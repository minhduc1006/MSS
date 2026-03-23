package com.mss.billing.repository;

import com.mss.billing.model.UtilityMeterReading;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface UtilityMeterReadingRepository extends JpaRepository<UtilityMeterReading, Long> {
    List<UtilityMeterReading> findAllByOrderByBillingMonthDescIdDesc();
}
