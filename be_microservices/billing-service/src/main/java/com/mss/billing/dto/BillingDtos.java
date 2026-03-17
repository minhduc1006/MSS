package com.mss.billing.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public final class BillingDtos {
    private BillingDtos() {}
    public record CreateInvoiceRequest(
        Long residentId,
        String residentName,
        String residentEmail,
        String unitNumber,
        String title,
        String category,
        BigDecimal amount,
        LocalDate dueDate,
        String description
    ) {}
    public record InvoiceEmailResponse(Long invoiceId, String recipient, boolean sent, String message) {}
    public record CreateInvoiceResponse(BillItem invoice, InvoiceEmailResponse email) {}
    public record UpdateInvoiceStatusRequest(String status) {}
    public record CreatePaymentSessionRequest(String returnUrl, String cancelUrl) {}
    public record PaymentSession(Long invoiceId, Long orderCode, String paymentLinkId, String checkoutUrl, String status) {}
    public record PayOsWebhookResult(boolean success, Long orderCode, String code, String description) {}
    public record BillItem(Long id, Long residentId, String residentName, String residentEmail, String unitNumber, String title, String category, BigDecimal amount, LocalDate dueDate, String status, String description, String paymentLinkId, Long payosOrderCode, String checkoutUrl) {}
    public record BillingSummary(BigDecimal totalInvoiced, BigDecimal totalOutstanding, long activeInvoices) {}
    public record BillingOverview(BillingSummary summary, List<BillItem> invoices) {}
    public record CreateApartmentUnitRequest(
        String unitNumber,
        String tower,
        String unitType,
        String occupancyStatus,
        String residentName,
        BigDecimal balance
    ) {}
    public record UpdateApartmentUnitStatusRequest(String status) {}
    public record UnitItem(Long id, String unitNumber, String tower, String unitType, String occupancyStatus, String residentName, BigDecimal balance) {}
    public record ApartmentStats(long totalUnits, long occupiedUnits, List<UnitItem> units) {}
}
