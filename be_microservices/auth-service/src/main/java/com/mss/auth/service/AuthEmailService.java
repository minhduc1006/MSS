package com.mss.auth.service;

import com.mss.auth.model.AppUser;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.env.Environment;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;

@Service
public class AuthEmailService {
    private final JavaMailSender mailSender;
    private final Environment environment;
    private final String fromAddress;
    private final String portalUrl;

    public AuthEmailService(
        JavaMailSender mailSender,
        Environment environment,
        @Value("${security.mail.from:}") String fromAddress,
        @Value("${app.portal-url:http://localhost:3000}") String portalUrl
    ) {
        this.mailSender = mailSender;
        this.environment = environment;
        this.fromAddress = fromAddress;
        this.portalUrl = portalUrl;
    }

    public void sendPasswordResetOtp(AppUser user, String otp) {
        if (!hasText(environment.getProperty("spring.mail.host"))) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Email service is not configured. Set spring.mail.* first.");
        }

        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, "UTF-8");
            if (hasText(fromAddress)) {
                helper.setFrom(fromAddress.trim());
            }
            helper.setTo(user.getEmail());
            helper.setSubject("Skyline Heights password reset verification");
            helper.setText(buildOtpTemplate(user, otp), true);
            mailSender.send(message);
        } catch (MessagingException | RuntimeException error) {
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Unable to send OTP email: " + error.getMessage(), error);
        }
    }

    private String buildOtpTemplate(AppUser user, String otp) {
        return """
            <!DOCTYPE html>
            <html lang="en">
            <head>
              <meta charset="UTF-8" />
              <meta name="viewport" content="width=device-width, initial-scale=1.0" />
              <title>Password Reset Verification</title>
            </head>
            <body style="margin:0;padding:24px;background:#eef4fb;font-family:Arial,sans-serif;color:#172033;">
              <table role="presentation" width="100%%" cellspacing="0" cellpadding="0" style="max-width:680px;margin:0 auto;background:#ffffff;border-radius:24px;overflow:hidden;border:1px solid #d8e7fb;box-shadow:0 16px 40px rgba(19,127,236,0.12);">
                <tr>
                  <td style="background:#137fec;padding:28px 34px;">
                    <table role="presentation" width="100%%" cellspacing="0" cellpadding="0">
                      <tr>
                        <td style="width:72px;">
                          <div style="width:56px;height:56px;border-radius:16px;background:#ffffff;display:flex;align-items:center;justify-content:center;color:#137fec;font-size:28px;font-weight:700;text-align:center;line-height:56px;">S</div>
                        </td>
                        <td>
                          <div style="font-size:18px;font-weight:800;color:#ffffff;">Skyline Heights</div>
                          <div style="font-size:30px;font-weight:800;color:#ffffff;line-height:1.2;margin-top:4px;">Security Notification</div>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
                <tr>
                  <td style="padding:42px 54px 36px;">
                    <div style="font-size:22px;font-weight:800;color:#172033;margin-bottom:18px;">Password Reset Request</div>
                    <p style="margin:0 0 24px;font-size:16px;line-height:1.8;color:#4b5f7b;">
                      We received a request to reset the password for %s. Use the verification code below to continue.
                    </p>
                    <div style="border:2px dashed #d7e5f7;border-radius:22px;background:#f8fbff;padding:28px 20px;text-align:center;">
                      <div style="font-size:14px;font-weight:800;letter-spacing:4px;color:#7386a3;text-transform:uppercase;margin-bottom:18px;">Verification Code</div>
                      <div style="font-size:56px;font-weight:800;letter-spacing:18px;color:#ff7a1a;">%s</div>
                    </div>
                    <div style="margin-top:18px;font-size:14px;color:#7386a3;">Expires in 15 minutes</div>
                    <div style="height:1px;background:#e7eef8;margin:28px 0;"></div>
                    <p style="margin:0 0 18px;font-size:15px;line-height:1.8;color:#5f6f86;">
                      If you did not request this password reset, please ignore this email and contact support immediately.
                    </p>
                    <a href="%s/reset-password" style="display:inline-block;color:#137fec;font-size:15px;font-weight:800;text-decoration:none;">Open Reset Screen</a>
                  </td>
                </tr>
                <tr>
                  <td style="background:#f6f9fd;padding:28px 40px;text-align:center;border-top:1px solid #e7eef8;">
                    <div style="font-size:14px;font-weight:800;color:#172033;letter-spacing:1px;text-transform:uppercase;">Skyline Heights Management</div>
                    <div style="font-size:14px;color:#8ea0b8;line-height:1.8;margin-top:10px;">
                      123 Corporate Way, Suite 500<br/>
                      New York, NY 10001
                    </div>
                  </td>
                </tr>
              </table>
            </body>
            </html>
            """.formatted(user.getEmail(), otp, portalUrl);
    }

    private boolean hasText(String value) {
        return value != null && !value.isBlank();
    }
}
