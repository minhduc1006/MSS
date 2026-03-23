package com.mss.billing.repository;

import com.mss.billing.model.TenancyLease;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TenancyLeaseRepository extends JpaRepository<TenancyLease, Long> {
    List<TenancyLease> findAllByOrderByStartDateDesc();
}
