package com.mss.operations.repository;

import com.mss.operations.model.ComplaintTicket;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ComplaintTicketRepository extends JpaRepository<ComplaintTicket, Long> {
    List<ComplaintTicket> findAllByOrderByCreatedAtDesc();
    List<ComplaintTicket> findByResidentIdOrderByCreatedAtDesc(Long residentId);
    List<ComplaintTicket> findByAssignedStaffIdOrderByCreatedAtDesc(Long assignedStaffId);
}
