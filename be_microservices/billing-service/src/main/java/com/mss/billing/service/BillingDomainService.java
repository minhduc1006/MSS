package com.mss.billing.service;

import com.mss.billing.config.PayOsProperties;
import com.mss.billing.dto.BillingDtos;
import com.mss.billing.model.ApartmentUnit;
import com.mss.billing.model.Invoice;
import com.mss.billing.repository.ApartmentUnitRepository;
import com.mss.billing.repository.InvoiceRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;
import vn.payos.PayOS;
import vn.payos.model.v2.paymentRequests.CreatePaymentLinkRequest;
import vn.payos.model.v2.paymentRequests.CreatePaymentLinkResponse;
import vn.payos.model.webhooks.WebhookData;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;
import java.util.Map;

@Service
public class BillingDomainService {
    private final InvoiceRepository invoiceRepository;
    private final ApartmentUnitRepository unitRepository;
    private final PayOsProperties payOsProperties;
    private final AuthServiceClient authServiceClient;
    private final InvoiceEmailService invoiceEmailService;

    public BillingDomainService(
        InvoiceRepository invoiceRepository,
        ApartmentUnitRepository unitRepository,
        PayOsProperties payOsProperties,
        AuthServiceClient authServiceClient,
        InvoiceEmailService invoiceEmailService
    ) {
        this.invoiceRepository = invoiceRepository;
        this.unitRepository = unitRepository;
        this.payOsProperties = payOsProperties;
        this.authServiceClient = authServiceClient;
        this.invoiceEmailService = invoiceEmailService;
    }

    public BillingDtos.BillingOverview getOverview(String status) {
        List<Invoice> all = invoiceRepository.findAllByOrderByDueDateDesc();
        List<Invoice> filtered = all.stream()
            .filter(i -> status == null || status.isBlank() || "All".equalsIgnoreCase(status) || i.getStatus().equalsIgnoreCase(status))
            .toList();
        BigDecimal total = all.stream().map(Invoice::getAmount).reduce(BigDecimal.ZERO, BigDecimal::add);
        List<Invoice> outstanding = all.stream().filter(i -> !"Paid".equalsIgnoreCase(i.getStatus())).toList();
        BigDecimal outstandingAmount = outstanding.stream().map(Invoice::getAmount).reduce(BigDecimal.ZERO, BigDecimal::add);
        return new BillingDtos.BillingOverview(new BillingDtos.BillingSummary(total, outstandingAmount, outstanding.size()), filtered.stream().map(this::toBill).toList());
    }

    public List<BillingDtos.BillItem> getResidentBills(Long residentId) {
        return invoiceRepository.findByResidentIdOrderByDueDateDesc(residentId).stream().map(this::toBill).toList();
    }

    public BillingDtos.CreateInvoiceResponse createInvoice(BillingDtos.CreateInvoiceRequest request) {
        if (request.residentId() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Resident ID is required");
        }
        if (request.title() == null || request.title().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invoice title is required");
        }
        if (request.amount() == null || request.amount().compareTo(BigDecimal.ZERO) <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invoice amount must be greater than zero");
        }

        Invoice invoice = new Invoice();
        invoice.setResidentId(request.residentId());
        invoice.setResidentName(request.residentName());
        invoice.setResidentEmail(resolveResidentEmail(request));
        invoice.setUnitNumber(request.unitNumber());
        invoice.setTitle(request.title());
        invoice.setCategory(request.category() == null || request.category().isBlank() ? "service" : request.category());
        invoice.setAmount(request.amount());
        invoice.setDueDate(request.dueDate() == null ? LocalDate.now().plusDays(1) : request.dueDate());
        invoice.setStatus("Pending");
        invoice.setDescription(request.description());
        Invoice saved = invoiceRepository.save(invoice);
        BillingDtos.InvoiceEmailResponse emailResponse = invoiceEmailService.sendInvoiceEmail(saved);
        return new BillingDtos.CreateInvoiceResponse(toBill(saved), emailResponse);
    }

    public BillingDtos.PaymentSession createCheckout(Long invoiceId, BillingDtos.CreatePaymentSessionRequest request) {
        Invoice invoice = invoiceRepository.findById(invoiceId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Invoice not found"));
        if ("Paid".equalsIgnoreCase(invoice.getStatus())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invoice has already been paid");
        }

        PayOS client = requirePayOs();
        String returnUrl = resolveUrl(request == null ? null : request.returnUrl(), payOsProperties.getReturnUrl());
        String cancelUrl = resolveUrl(request == null ? null : request.cancelUrl(), payOsProperties.getCancelUrl());
        if (!hasText(returnUrl) || !hasText(cancelUrl)) {
            throw new ResponseStatusException(
                HttpStatus.SERVICE_UNAVAILABLE,
                "PayOS returnUrl/cancelUrl are required. Configure PAYOS_RETURN_URL and PAYOS_CANCEL_URL or send them from the client."
            );
        }

        Long orderCode = Instant.now().toEpochMilli();
        CreatePaymentLinkRequest payOsRequest = CreatePaymentLinkRequest.builder()
            .orderCode(orderCode)
            .amount(normalizeAmount(invoice.getAmount()))
            .description(buildDescription(invoice))
            .returnUrl(returnUrl)
            .cancelUrl(cancelUrl)
            .buyerName(invoice.getResidentName())
            .build();

        try {
            CreatePaymentLinkResponse response = client.paymentRequests().create(payOsRequest);
            invoice.setPayosOrderCode(response.getOrderCode());
            invoice.setPaymentLinkId(response.getPaymentLinkId());
            invoice.setCheckoutUrl(response.getCheckoutUrl());
            invoice.setStatus("Pending");
            invoiceRepository.save(invoice);
            return new BillingDtos.PaymentSession(
                invoice.getId(),
                response.getOrderCode(),
                response.getPaymentLinkId(),
                response.getCheckoutUrl(),
                response.getStatus().toString()
            );
        } catch (RuntimeException error) {
            throw new ResponseStatusException(
                HttpStatus.BAD_GATEWAY,
                "Unable to create PayOS checkout link: " + error.getMessage(),
                error
            );
        }
    }

    public BillingDtos.BillItem pay(Long invoiceId) {
        Invoice invoice = invoiceRepository.findById(invoiceId).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Invoice not found"));
        invoice.setStatus("Paid");
        invoice.setPaidAt(LocalDateTime.now());
        Invoice saved = invoiceRepository.save(invoice);
        return toBill(saved);
    }

    public BillingDtos.PayOsWebhookResult handlePayOsWebhook(Map<String, Object> payload) {
        PayOS client = requirePayOs();
        try {
            WebhookData verified = client.webhooks().verify(payload);
            invoiceRepository.findByPayosOrderCode(verified.getOrderCode()).ifPresent(invoice -> {
                invoice.setPaymentLinkId(verified.getPaymentLinkId());
                if ("00".equals(verified.getCode())) {
                    invoice.setStatus("Paid");
                    invoice.setPaidAt(LocalDateTime.now());
                    invoice.setCheckoutUrl(null);
                }
                invoiceRepository.save(invoice);
            });
            return new BillingDtos.PayOsWebhookResult(
                true,
                verified.getOrderCode(),
                verified.getCode(),
                verified.getDesc()
            );
        } catch (RuntimeException error) {
            throw new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "Invalid PayOS webhook: " + error.getMessage(),
                error
            );
        }
    }

    public String paymentResultPage(String title, String message) {
        return """
            <!DOCTYPE html>
            <html lang="en">
            <head>
              <meta charset="utf-8" />
              <meta name="viewport" content="width=device-width, initial-scale=1" />
              <title>PayOS Result</title>
              <style>
                body { font-family: Arial, sans-serif; background: #f6f7f8; color: #172033; margin: 0; }
                .card { max-width: 480px; margin: 48px auto; background: white; border: 1px solid #e3e8f0; border-radius: 20px; padding: 24px; }
                h1 { font-size: 24px; margin: 0 0 12px; }
                p { line-height: 1.5; margin: 0 0 12px; }
              </style>
            </head>
            <body>
              <div class="card">
                <h1>%s</h1>
                <p>%s</p>
                <p>You can return to the Skyline Heights app now.</p>
              </div>
            </body>
            </html>
            """.formatted(title, message);
    }

    public BillingDtos.ApartmentStats apartments() {
        List<ApartmentUnit> units = unitRepository.findAll().stream().sorted(Comparator.comparing(ApartmentUnit::getUnitNumber)).toList();
        return new BillingDtos.ApartmentStats(units.size(), units.stream().filter(u -> "Occupied".equalsIgnoreCase(u.getOccupancyStatus())).count(), units.stream().map(this::toUnit).toList());
    }

    public BillingDtos.InvoiceEmailResponse sendInvoiceEmail(Long invoiceId) {
        Invoice invoice = invoiceRepository.findById(invoiceId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Invoice not found"));
        if (!hasText(invoice.getResidentEmail())) {
            invoice.setResidentEmail(authServiceClient.getUserEmail(invoice.getResidentId()));
            invoiceRepository.save(invoice);
        }
        return invoiceEmailService.sendInvoiceEmail(invoice);
    }

    private BillingDtos.BillItem toBill(Invoice invoice) {
        return new BillingDtos.BillItem(
            invoice.getId(),
            invoice.getResidentId(),
            invoice.getResidentName(),
            invoice.getResidentEmail(),
            invoice.getUnitNumber(),
            invoice.getTitle(),
            invoice.getCategory(),
            invoice.getAmount(),
            invoice.getDueDate(),
            invoice.getStatus(),
            invoice.getDescription(),
            invoice.getPaymentLinkId(),
            invoice.getPayosOrderCode(),
            invoice.getCheckoutUrl()
        );
    }

    private BillingDtos.UnitItem toUnit(ApartmentUnit unit) {
        return new BillingDtos.UnitItem(unit.getId(), unit.getUnitNumber(), unit.getTower(), unit.getUnitType(), unit.getOccupancyStatus(), unit.getResidentName(), unit.getBalance());
    }

    private String resolveResidentEmail(BillingDtos.CreateInvoiceRequest request) {
        if (hasText(request.residentEmail())) {
            return request.residentEmail().trim();
        }

        String resolvedEmail = authServiceClient.getUserEmail(request.residentId());
        if (!hasText(resolvedEmail)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Resident email is required");
        }
        return resolvedEmail.trim();
    }

    private PayOS requirePayOs() {
        if (!payOsProperties.isConfigured()) {
            throw new ResponseStatusException(
                HttpStatus.SERVICE_UNAVAILABLE,
                "PayOS is not configured. Set PAYOS_CLIENT_ID, PAYOS_API_KEY, and PAYOS_CHECKSUM_KEY."
            );
        }
        return new PayOS(
            payOsProperties.getClientId().trim(),
            payOsProperties.getApiKey().trim(),
            payOsProperties.getChecksumKey().trim()
        );
    }

    private Long normalizeAmount(BigDecimal amount) {
        return amount.setScale(0, RoundingMode.HALF_UP).longValueExact();
    }

    private String buildDescription(Invoice invoice) {
        return "MSS invoice " + invoice.getId();
    }

    private String resolveUrl(String preferred, String fallback) {
        return hasText(preferred) ? preferred.trim() : hasText(fallback) ? fallback.trim() : null;
    }

    private boolean hasText(String value) {
        return value != null && !value.isBlank();
    }
}
