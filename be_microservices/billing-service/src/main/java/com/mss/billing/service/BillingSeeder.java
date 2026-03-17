package com.mss.billing.service;

import com.mss.billing.model.ApartmentUnit;
import com.mss.billing.model.Invoice;
import com.mss.billing.repository.ApartmentUnitRepository;
import com.mss.billing.repository.InvoiceRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;

@Component
public class BillingSeeder implements CommandLineRunner {
    private static final BigDecimal LEGACY_USD_CEILING = new BigDecimal("10000");
    private static final BigDecimal VND_MULTIPLIER = new BigDecimal("10000");

    private final InvoiceRepository invoiceRepository;
    private final ApartmentUnitRepository unitRepository;

    public BillingSeeder(InvoiceRepository invoiceRepository, ApartmentUnitRepository unitRepository) {
        this.invoiceRepository = invoiceRepository;
        this.unitRepository = unitRepository;
    }

    @Override
    public void run(String... args) {
        ensureSeedUnits();
        if (invoiceRepository.count() > 0) {
            normalizeLegacySeedData();
            return;
        }
        bill(2L, "John Doe", "402", "Monthly Maintenance", "maintenance", new BigDecimal("1500000"), LocalDate.of(2026, 3, 1), "Paid", "Monthly building maintenance fee");
        bill(2L, "John Doe", "402", "Electricity Bill", "utility", new BigDecimal("854000"), LocalDate.of(2026, 2, 28), "Pending", "February electricity consumption");
        bill(2L, "John Doe", "402", "Water Usage", "utility", new BigDecimal("321000"), LocalDate.of(2026, 2, 25), "Paid", "February water usage");
        bill(2L, "John Doe", "402", "Parking Fee", "parking", new BigDecimal("500000"), LocalDate.of(2026, 2, 20), "Overdue", "Reserved parking slot fee");
        bill(4L, "Sarah Jenkins", "115A", "Monthly Maintenance", "maintenance", new BigDecimal("12500000"), LocalDate.of(2026, 3, 4), "Pending", "Outstanding building service charge");
        bill(7L, "Jordan Lee", "312", "Monthly Maintenance", "maintenance", new BigDecimal("18500000"), LocalDate.of(2026, 3, 2), "Overdue", "Building maintenance fee overdue");
        bill(6L, "Elena Rossi", "208", "Gym Membership", "facility", new BigDecimal("9500000"), LocalDate.of(2026, 2, 27), "Paid", "Annual amenity package");
        bill(3L, "Alex Thompson", "402B", "Water Usage", "utility", new BigDecimal("1125000"), LocalDate.of(2026, 3, 5), "Pending", "March water usage");
        bill(5L, "Michael Rivera", "303C", "Move-out Cleaning", "service", new BigDecimal("3000000"), LocalDate.of(2026, 3, 7), "Pending", "Final cleaning service");
    }

    private void ensureSeedUnits() {
        ensureUnit("402", "Skyview Tower", "Suite", "Occupied", "John Doe", new BigDecimal("1354000"));
        ensureUnit("402B", "Skyview Tower", "Penthouse", "Occupied", "Alex Thompson", BigDecimal.ZERO);
        ensureUnit("115A", "Ocean Tower", "Standard", "Occupied", "Sarah Jenkins", new BigDecimal("12500000"));
        ensureUnit("303C", "Garden Tower", "Standard", "Occupied", "Michael Rivera", new BigDecimal("3000000"));
        ensureUnit("208", "Skyview Tower", "Studio", "Occupied", "Elena Rossi", new BigDecimal("9500000"));
        ensureUnit("312", "Garden Tower", "Standard", "Occupied", "Jordan Lee", new BigDecimal("18500000"));
        ensureUnit("508", "Skyline Heights", "Standard", "Occupied", "Đức Dayne", new BigDecimal("5200000"));
        ensureUnit("105", "Skyview Tower", "Standard", "Vacant", null, BigDecimal.ZERO);
    }

    private void normalizeLegacySeedData() {
        var invoices = invoiceRepository.findAll();
        boolean updatedInvoices = false;
        for (Invoice invoice : invoices) {
            if (invoice.getAmount() != null && invoice.getAmount().abs().compareTo(LEGACY_USD_CEILING) < 0) {
                invoice.setAmount(toVnd(invoice.getAmount()));
                updatedInvoices = true;
            }
        }
        if (updatedInvoices) {
            invoiceRepository.saveAll(invoices);
        }

        var units = unitRepository.findAll();
        boolean updatedUnits = false;
        for (ApartmentUnit unit : units) {
            if (unit.getBalance() != null && unit.getBalance().abs().compareTo(BigDecimal.ZERO) > 0 && unit.getBalance().abs().compareTo(LEGACY_USD_CEILING) < 0) {
                unit.setBalance(toVnd(unit.getBalance()));
                updatedUnits = true;
            }
        }
        if (updatedUnits) {
            unitRepository.saveAll(units);
        }
    }

    private BigDecimal toVnd(BigDecimal legacyAmount) {
        return legacyAmount.multiply(VND_MULTIPLIER).setScale(0, RoundingMode.HALF_UP);
    }

    private void ensureUnit(String unitNumber, String tower, String unitType, String occupancyStatus, String residentName, BigDecimal balance) {
        if (unitRepository.findByUnitNumberIgnoreCase(unitNumber).isPresent()) {
            return;
        }
        ApartmentUnit unit = new ApartmentUnit();
        unit.setUnitNumber(unitNumber);
        unit.setTower(tower);
        unit.setUnitType(unitType);
        unit.setOccupancyStatus(occupancyStatus);
        unit.setResidentName(residentName);
        unit.setBalance(balance);
        unitRepository.save(unit);
    }

    private void bill(Long residentId, String residentName, String unitNumber, String title, String category, BigDecimal amount, LocalDate dueDate, String status, String description) {
        Invoice invoice = new Invoice();
        invoice.setResidentId(residentId);
        invoice.setResidentName(residentName);
        invoice.setUnitNumber(unitNumber);
        invoice.setTitle(title);
        invoice.setCategory(category);
        invoice.setAmount(amount);
        invoice.setDueDate(dueDate);
        invoice.setStatus(status);
        invoice.setDescription(description);
        invoiceRepository.save(invoice);
    }
}
