package com.mss.billing.service;

import com.mss.billing.dto.BillingDtos;
import com.mss.billing.model.Invoice;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.core.env.Environment;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

import java.text.NumberFormat;
import java.util.Locale;

@Service
public class InvoiceEmailService {
    private static final Logger log = LoggerFactory.getLogger(InvoiceEmailService.class);

    private final JavaMailSender mailSender;
    private final Environment environment;
    private final String fromAddress;
    private final String portalUrl;

    public InvoiceEmailService(
        ObjectProvider<JavaMailSender> mailSenderProvider,
        Environment environment,
        @Value("${invoice.mail.from:}") String fromAddress,
        @Value("${app.portal-url:http://localhost:3000}") String portalUrl
    ) {
        this.mailSender = mailSenderProvider.getIfAvailable();
        this.environment = environment;
        this.fromAddress = fromAddress;
        this.portalUrl = portalUrl;
    }

    public BillingDtos.InvoiceEmailResponse sendInvoiceEmail(Invoice invoice) {
        String recipient = hasText(invoice.getResidentEmail()) ? invoice.getResidentEmail().trim() : null;
        if (!hasText(recipient)) {
            return new BillingDtos.InvoiceEmailResponse(invoice.getId(), null, false, "Resident email is missing");
        }
        if (mailSender == null || !hasText(environment.getProperty("spring.mail.host"))) {
            log.warn("Skipping invoice email for invoice {} because spring.mail.host is not configured", invoice.getId());
            return new BillingDtos.InvoiceEmailResponse(
                invoice.getId(),
                recipient,
                false,
                "Email service is not configured. Set spring.mail.* before sending."
            );
        }

        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, "UTF-8");
            if (hasText(fromAddress)) {
                helper.setFrom(fromAddress.trim());
            }
            helper.setTo(recipient);
            helper.setSubject("Skyline Heights invoice #" + invoice.getId());
            helper.setText(buildBody(invoice), true);
            mailSender.send(message);
            return new BillingDtos.InvoiceEmailResponse(invoice.getId(), recipient, true, "Invoice email sent successfully");
        } catch (MessagingException | RuntimeException error) {
            log.error("Unable to send invoice {} to {}", invoice.getId(), recipient, error);
            return new BillingDtos.InvoiceEmailResponse(invoice.getId(), recipient, false, "Unable to send invoice email: " + error.getMessage());
        }
    }

    private String buildBody(Invoice invoice) {
        NumberFormat currency = NumberFormat.getCurrencyInstance(new Locale("vi", "VN"));
        String dueDate = invoice.getDueDate() == null ? "N/A" : invoice.getDueDate().toString();
        String description = escapeHtml(hasText(invoice.getDescription()) ? invoice.getDescription().trim() : "Monthly billing cycle");
        String payUrl = hasText(invoice.getCheckoutUrl()) ? invoice.getCheckoutUrl().trim() : portalUrl + "/resident/bills";
        return """
            <!DOCTYPE html>
            <html lang="en">
            <head>
              <meta charset="UTF-8" />
              <meta name="viewport" content="width=device-width, initial-scale=1.0" />
              <title>Monthly Invoice</title>
            </head>
            <body style="margin:0;padding:24px;background:#eef4fb;font-family:Arial,sans-serif;color:#172033;">
              <table role="presentation" width="100%%" cellspacing="0" cellpadding="0" style="max-width:720px;margin:0 auto;background:#ffffff;border-radius:24px;overflow:hidden;border:1px solid #d8e7fb;box-shadow:0 16px 40px rgba(19,127,236,0.12);">
                <tr>
                  <td style="background:#137fec;padding:28px 34px;">
                    <table role="presentation" width="100%%" cellspacing="0" cellpadding="0">
                      <tr>
                        <td style="width:76px;">
                          <div style="width:56px;height:56px;border-radius:16px;background:#ffffff;display:flex;align-items:center;justify-content:center;color:#137fec;font-size:28px;font-weight:800;text-align:center;line-height:56px;">S</div>
                        </td>
                        <td>
                          <div style="font-size:18px;font-weight:800;color:#ffffff;">Skyline Residences</div>
                          <div style="font-size:15px;letter-spacing:3px;color:#d9ebff;text-transform:uppercase;margin-top:6px;">Premium Living</div>
                        </td>
                        <td style="text-align:right;">
                          <span style="display:inline-block;padding:14px 20px;border-radius:999px;background:rgba(255,255,255,0.14);color:#ffffff;font-size:13px;font-weight:800;letter-spacing:1px;text-transform:uppercase;">Monthly Invoice</span>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
                <tr>
                  <td style="padding:34px 40px 26px;">
                    <table role="presentation" width="100%%" cellspacing="0" cellpadding="0">
                      <tr>
                        <td style="width:50%%;vertical-align:top;padding-right:16px;">
                          <div style="font-size:14px;font-weight:800;letter-spacing:1.8px;color:#94a4bd;text-transform:uppercase;margin-bottom:12px;">Bill To</div>
                          <div style="font-size:18px;font-weight:800;line-height:1.5;color:#172033;">%s</div>
                          <div style="font-size:15px;line-height:1.8;color:#60718a;">Unit %s</div>
                          <div style="font-size:15px;line-height:1.8;color:#60718a;">%s</div>
                        </td>
                        <td style="width:50%%;vertical-align:top;text-align:right;">
                          <div style="font-size:14px;font-weight:800;letter-spacing:1.8px;color:#94a4bd;text-transform:uppercase;margin-bottom:12px;">Invoice Details</div>
                          <div style="font-size:15px;line-height:1.8;color:#172033;">Date: %s</div>
                          <div style="font-size:15px;line-height:1.8;color:#172033;">Invoice #: INV-%s</div>
                          <div style="font-size:15px;line-height:1.8;color:#172033;">Due Date: %s</div>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
                <tr>
                  <td style="padding:10px 40px 0;">
                    <div style="height:1px;background:#e7eef8;"></div>
                  </td>
                </tr>
                <tr>
                  <td style="padding:26px 40px 12px;">
                    <table role="presentation" width="100%%" cellspacing="0" cellpadding="0">
                      <tr>
                        <td style="font-size:14px;font-weight:800;letter-spacing:1.8px;color:#94a4bd;text-transform:uppercase;padding-bottom:12px;">Description</td>
                        <td style="font-size:14px;font-weight:800;letter-spacing:1.8px;color:#94a4bd;text-transform:uppercase;padding-bottom:12px;text-align:right;">Amount</td>
                      </tr>
                      <tr>
                        <td style="padding:20px 0;border-top:1px solid #edf3fb;">
                          <div style="font-size:18px;font-weight:800;color:#172033;">%s</div>
                          <div style="font-size:14px;line-height:1.7;color:#94a4bd;margin-top:4px;">%s</div>
                        </td>
                        <td style="padding:20px 0;border-top:1px solid #edf3fb;text-align:right;font-size:18px;font-weight:700;color:#172033;">%s</td>
                      </tr>
                    </table>
                  </td>
                </tr>
                <tr>
                  <td style="padding:22px 40px 10px;">
                    <div style="border-radius:22px;background:#f7faff;padding:28px 28px;">
                      <table role="presentation" width="100%%" cellspacing="0" cellpadding="0">
                        <tr>
                          <td style="vertical-align:top;">
                            <div style="font-size:16px;font-weight:800;line-height:1.5;color:#17306f;text-transform:uppercase;">Total Amount Due</div>
                            <div style="font-size:14px;line-height:1.7;color:#5f6f86;margin-top:10px;">Please pay by %s to avoid late fees.</div>
                          </td>
                          <td style="vertical-align:middle;text-align:right;font-size:28px;font-weight:800;color:#173ea5;">%s</td>
                        </tr>
                      </table>
                    </div>
                  </td>
                </tr>
                <tr>
                  <td style="padding:24px 40px 18px;text-align:center;">
                    <a href="%s" style="display:block;background:#137fec;color:#ffffff;text-decoration:none;padding:18px 20px;border-radius:14px;font-size:16px;font-weight:800;box-shadow:0 10px 20px rgba(19,127,236,0.18);">Pay My Invoice Now</a>
                    <div style="font-size:13px;line-height:1.7;color:#94a4bd;margin-top:16px;">Secure payment is available in Skyline Heights. Major cards and bank transfers are supported.</div>
                  </td>
                </tr>
                <tr>
                  <td style="background:#f6f9fd;padding:34px 40px;text-align:center;border-top:1px solid #e7eef8;">
                    <div style="font-size:16px;font-weight:800;color:#172033;">Management Office</div>
                    <div style="font-size:14px;line-height:1.8;color:#7d8ea7;margin-top:12px;">
                      Skyline Heights Management<br/>
                      Monday - Friday, 9:00 AM - 6:00 PM<br/>
                      Email: support@skylineheights.com
                    </div>
                  </td>
                </tr>
              </table>
            </body>
            </html>
            """.formatted(
            escapeHtml(valueOrDefault(invoice.getResidentName(), "Resident")),
            escapeHtml(valueOrDefault(invoice.getUnitNumber(), "N/A")),
            escapeHtml(valueOrDefault(invoice.getResidentEmail(), "Resident account")),
            java.time.LocalDate.now(),
            invoice.getId(),
            dueDate,
            escapeHtml(valueOrDefault(invoice.getTitle(), "Monthly Invoice")),
            description,
            invoice.getAmount() == null ? "N/A" : currency.format(invoice.getAmount()),
            dueDate,
            invoice.getAmount() == null ? "N/A" : currency.format(invoice.getAmount()),
            payUrl
        );
    }

    public BillingDtos.InvoiceEmailResponse sendPaymentReceiptEmail(Invoice invoice) {
        String recipient = hasText(invoice.getResidentEmail()) ? invoice.getResidentEmail().trim() : null;
        if (!hasText(recipient)) {
            return new BillingDtos.InvoiceEmailResponse(invoice.getId(), null, false, "Resident email is missing");
        }
        if (mailSender == null || !hasText(environment.getProperty("spring.mail.host"))) {
            log.warn("Skipping receipt email for invoice {} because spring.mail.host is not configured", invoice.getId());
            return new BillingDtos.InvoiceEmailResponse(
                invoice.getId(),
                recipient,
                false,
                "Email service is not configured. Set spring.mail.* before sending."
            );
        }

        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, "UTF-8");
            if (hasText(fromAddress)) {
                helper.setFrom(fromAddress.trim());
            }
            helper.setTo(recipient);
            helper.setSubject("Payment Receipt for Skyline Heights invoice #" + invoice.getId());
            helper.setText(buildReceiptBody(invoice), true);
            mailSender.send(message);
            return new BillingDtos.InvoiceEmailResponse(invoice.getId(), recipient, true, "Payment receipt email sent successfully");
        } catch (MessagingException | RuntimeException error) {
            log.error("Unable to send receipt {} to {}", invoice.getId(), recipient, error);
            return new BillingDtos.InvoiceEmailResponse(invoice.getId(), recipient, false, "Unable to send receipt email: " + error.getMessage());
        }
    }

    private String buildReceiptBody(Invoice invoice) {
        NumberFormat currency = NumberFormat.getCurrencyInstance(new Locale("vi", "VN"));
        String paymentDate = invoice.getPaidAt() == null ? "N/A" : invoice.getPaidAt().toLocalDate().toString();
        String description = escapeHtml(hasText(invoice.getDescription()) ? invoice.getDescription().trim() : "Monthly billing cycle");
        return """
            <!DOCTYPE html>
            <html lang="en">
            <head>
              <meta charset="UTF-8" />
              <meta name="viewport" content="width=device-width, initial-scale=1.0" />
              <title>Payment Receipt</title>
            </head>
            <body style="margin:0;padding:24px;background:#eef4fb;font-family:Arial,sans-serif;color:#172033;">
              <table role="presentation" width="100%%" cellspacing="0" cellpadding="0" style="max-width:720px;margin:0 auto;background:#ffffff;border-radius:24px;overflow:hidden;border:1px solid #d8e7fb;box-shadow:0 16px 40px rgba(19,127,236,0.12);">
                <tr>
                  <td style="background:#10b981;padding:28px 34px;">
                    <table role="presentation" width="100%%" cellspacing="0" cellpadding="0">
                      <tr>
                        <td style="width:76px;">
                          <div style="width:56px;height:56px;border-radius:16px;background:#ffffff;display:flex;align-items:center;justify-content:center;color:#10b981;font-size:28px;font-weight:800;text-align:center;line-height:56px;">✓</div>
                        </td>
                        <td>
                          <div style="font-size:18px;font-weight:800;color:#ffffff;">Skyline Residences</div>
                          <div style="font-size:15px;letter-spacing:3px;color:#d1fae5;text-transform:uppercase;margin-top:6px;">Payment Successful</div>
                        </td>
                        <td style="text-align:right;">
                          <span style="display:inline-block;padding:14px 20px;border-radius:999px;background:rgba(255,255,255,0.14);color:#ffffff;font-size:13px;font-weight:800;letter-spacing:1px;text-transform:uppercase;">Receipt</span>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
                <tr>
                  <td style="padding:34px 40px 26px;">
                    <table role="presentation" width="100%%" cellspacing="0" cellpadding="0">
                      <tr>
                        <td style="width:50%%;vertical-align:top;padding-right:16px;">
                          <div style="font-size:14px;font-weight:800;letter-spacing:1.8px;color:#94a4bd;text-transform:uppercase;margin-bottom:12px;">Billed To</div>
                          <div style="font-size:18px;font-weight:800;line-height:1.5;color:#172033;">%s</div>
                          <div style="font-size:15px;line-height:1.8;color:#60718a;">Unit %s</div>
                          <div style="font-size:15px;line-height:1.8;color:#60718a;">%s</div>
                        </td>
                        <td style="width:50%%;vertical-align:top;text-align:right;">
                          <div style="font-size:14px;font-weight:800;letter-spacing:1.8px;color:#94a4bd;text-transform:uppercase;margin-bottom:12px;">Payment Details</div>
                          <div style="font-size:15px;line-height:1.8;color:#172033;">Date: %s</div>
                          <div style="font-size:15px;line-height:1.8;color:#172033;">Invoice #: INV-%s</div>
                          <div style="font-size:15px;line-height:1.8;color:#10b981;font-weight:bold;">Status: PAID</div>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
                <tr>
                  <td style="padding:10px 40px 0;">
                    <div style="height:1px;background:#e7eef8;"></div>
                  </td>
                </tr>
                <tr>
                  <td style="padding:26px 40px 12px;">
                    <table role="presentation" width="100%%" cellspacing="0" cellpadding="0">
                      <tr>
                        <td style="font-size:14px;font-weight:800;letter-spacing:1.8px;color:#94a4bd;text-transform:uppercase;padding-bottom:12px;">Description</td>
                        <td style="font-size:14px;font-weight:800;letter-spacing:1.8px;color:#94a4bd;text-transform:uppercase;padding-bottom:12px;text-align:right;">Amount Paid</td>
                      </tr>
                      <tr>
                        <td style="padding:20px 0;border-top:1px solid #edf3fb;">
                          <div style="font-size:18px;font-weight:800;color:#172033;">%s</div>
                          <div style="font-size:14px;line-height:1.7;color:#94a4bd;margin-top:4px;">%s</div>
                        </td>
                        <td style="padding:20px 0;border-top:1px solid #edf3fb;text-align:right;font-size:18px;font-weight:700;color:#172033;">%s</td>
                      </tr>
                    </table>
                  </td>
                </tr>
                <tr>
                  <td style="background:#f6f9fd;padding:34px 40px;text-align:center;border-top:1px solid #e7eef8;">
                    <div style="font-size:16px;font-weight:800;color:#172033;">Management Office</div>
                    <div style="font-size:14px;line-height:1.8;color:#7d8ea7;margin-top:12px;">
                      Thank you for your payment.<br/>
                      Skyline Heights Management<br/>
                      Monday - Friday, 9:00 AM - 6:00 PM<br/>
                      Email: support@skylineheights.com
                    </div>
                  </td>
                </tr>
              </table>
            </body>
            </html>
            """.formatted(
            escapeHtml(valueOrDefault(invoice.getResidentName(), "Resident")),
            escapeHtml(valueOrDefault(invoice.getUnitNumber(), "N/A")),
            escapeHtml(valueOrDefault(invoice.getResidentEmail(), "Resident account")),
            paymentDate,
            invoice.getId(),
            escapeHtml(valueOrDefault(invoice.getTitle(), "Monthly Invoice")),
            description,
            invoice.getAmount() == null ? "N/A" : currency.format(invoice.getAmount())
        );
    }

    private String escapeHtml(String value) {
        return value
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("\"", "&quot;")
            .replace("'", "&#39;");
    }

    private String valueOrDefault(String value, String fallback) {
        return hasText(value) ? value.trim() : fallback;
    }

    private boolean hasText(String value) {
        return value != null && !value.isBlank();
    }
}
