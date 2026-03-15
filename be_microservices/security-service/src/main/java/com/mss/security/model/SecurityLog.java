package com.mss.security.model;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;

import java.time.LocalDateTime;

@Entity
public class SecurityLog {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private Long userId;
    private String audience;
    private String event;
    private String visitor;
    private LocalDateTime accessTime;
    private String status;

    public Long getId() { return id; }
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public String getAudience() { return audience; }
    public void setAudience(String audience) { this.audience = audience; }
    public String getEvent() { return event; }
    public void setEvent(String event) { this.event = event; }
    public String getVisitor() { return visitor; }
    public void setVisitor(String visitor) { this.visitor = visitor; }
    public LocalDateTime getAccessTime() { return accessTime; }
    public void setAccessTime(LocalDateTime accessTime) { this.accessTime = accessTime; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}
