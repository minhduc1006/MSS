package com.mss.billing.repository;

import com.mss.billing.model.ApartmentUnit;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface ApartmentUnitRepository extends JpaRepository<ApartmentUnit, Long> {
    Optional<ApartmentUnit> findByUnitNumberIgnoreCase(String unitNumber);
}
