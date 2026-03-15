package com.mss.billing.repository;

import com.mss.billing.model.Invoice;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface InvoiceRepository extends JpaRepository<Invoice, Long> {
    List<Invoice> findAllByOrderByDueDateDesc();
    List<Invoice> findByResidentIdOrderByDueDateDesc(Long residentId);
    Optional<Invoice> findByPayosOrderCode(Long payosOrderCode);
}
