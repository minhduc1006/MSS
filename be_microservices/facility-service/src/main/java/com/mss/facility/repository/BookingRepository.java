package com.mss.facility.repository;

import com.mss.facility.model.Booking;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface BookingRepository extends JpaRepository<Booking, Long> {
    List<Booking> findByResidentIdOrderByBookingDateDesc(Long residentId);
}
