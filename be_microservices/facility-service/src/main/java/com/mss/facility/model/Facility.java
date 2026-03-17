package com.mss.facility.model;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
public class Facility {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String name;
    private String area;
    private String status;
    private int health;
    private LocalDateTime lastCheckAt;
    private String icon;
    private String description;
    private String serviceType;
    private String bookingMode;
    private BigDecimal oneTimePrice;
    private BigDecimal monthlyPrice;
    private BigDecimal yearlyPrice;
    private String slotLayout;

    public Long getId() { return id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getArea() { return area; }
    public void setArea(String area) { this.area = area; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public int getHealth() { return health; }
    public void setHealth(int health) { this.health = health; }
    public LocalDateTime getLastCheckAt() { return lastCheckAt; }
    public void setLastCheckAt(LocalDateTime lastCheckAt) { this.lastCheckAt = lastCheckAt; }
    public String getIcon() { return icon; }
    public void setIcon(String icon) { this.icon = icon; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getServiceType() { return serviceType; }
    public void setServiceType(String serviceType) { this.serviceType = serviceType; }
    public String getBookingMode() { return bookingMode; }
    public void setBookingMode(String bookingMode) { this.bookingMode = bookingMode; }
    public BigDecimal getOneTimePrice() { return oneTimePrice; }
    public void setOneTimePrice(BigDecimal oneTimePrice) { this.oneTimePrice = oneTimePrice; }
    public BigDecimal getMonthlyPrice() { return monthlyPrice; }
    public void setMonthlyPrice(BigDecimal monthlyPrice) { this.monthlyPrice = monthlyPrice; }
    public BigDecimal getYearlyPrice() { return yearlyPrice; }
    public void setYearlyPrice(BigDecimal yearlyPrice) { this.yearlyPrice = yearlyPrice; }
    public String getSlotLayout() { return slotLayout; }
    public void setSlotLayout(String slotLayout) { this.slotLayout = slotLayout; }
}
