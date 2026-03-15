package com.mss.security.repository;

import com.mss.security.model.SecurityLog;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SecurityLogRepository extends JpaRepository<SecurityLog, Long> {
    List<SecurityLog> findByUserIdOrderByAccessTimeDesc(Long userId);
    List<SecurityLog> findByAudienceOrderByAccessTimeDesc(String audience);
    List<SecurityLog> findAllByOrderByAccessTimeDesc();
}
