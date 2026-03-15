package com.mss.billing.controller;

import com.mss.billing.dto.BillingDtos;
import com.mss.billing.service.BillingDomainService;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class BillingController {
    private final BillingDomainService service;

    public BillingController(BillingDomainService service) {
        this.service = service;
    }

    @GetMapping("/billing/overview")
    public BillingDtos.BillingOverview overview(@RequestParam(required = false) String status) {
        return service.getOverview(status);
    }

    @GetMapping("/billing/resident/{residentId}")
    public List<BillingDtos.BillItem> residentBills(@PathVariable Long residentId) {
        return service.getResidentBills(residentId);
    }

    @PostMapping("/billing/invoices")
    public BillingDtos.CreateInvoiceResponse createInvoice(@RequestBody BillingDtos.CreateInvoiceRequest request) {
        return service.createInvoice(request);
    }

    @PostMapping("/billing/{invoiceId}/send-email")
    public BillingDtos.InvoiceEmailResponse sendInvoiceEmail(@PathVariable Long invoiceId) {
        return service.sendInvoiceEmail(invoiceId);
    }

    @PostMapping("/billing/{invoiceId}/pay")
    public BillingDtos.BillItem pay(@PathVariable Long invoiceId) {
        return service.pay(invoiceId);
    }

    @PostMapping("/billing/{invoiceId}/checkout")
    public BillingDtos.PaymentSession createCheckout(
        @PathVariable Long invoiceId,
        @RequestBody(required = false) BillingDtos.CreatePaymentSessionRequest request
    ) {
        return service.createCheckout(invoiceId, request);
    }

    @PostMapping("/billing/payos/webhook")
    public BillingDtos.PayOsWebhookResult handleWebhook(@RequestBody Map<String, Object> payload) {
        return service.handlePayOsWebhook(payload);
    }

    @GetMapping(value = "/billing/payos/return", produces = MediaType.TEXT_HTML_VALUE)
    public String payOsReturn() {
        return service.paymentResultPage(
            "Thanh toan PayOS da hoan tat",
            "Neu giao dich thanh cong, hoa don se tu dong cap nhat trong ung dung sau khi webhook duoc xu ly."
        );
    }

    @GetMapping(value = "/billing/payos/cancel", produces = MediaType.TEXT_HTML_VALUE)
    public String payOsCancel() {
        return service.paymentResultPage(
            "Ban da huy thanh toan",
            "Ban co the quay lai ung dung de chon lai hoa don va thu thanh toan sau."
        );
    }

    @GetMapping("/apartments")
    public BillingDtos.ApartmentStats apartments() {
        return service.apartments();
    }
}
