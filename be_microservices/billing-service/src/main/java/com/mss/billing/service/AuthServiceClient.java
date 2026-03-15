package com.mss.billing.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

@Service
public class AuthServiceClient {
    private final RestClient restClient;

    public AuthServiceClient(@Value("${auth.service.base-url:http://localhost:8081/api}") String baseUrl) {
        this.restClient = RestClient.builder().baseUrl(baseUrl).build();
    }

    public String getUserEmail(Long userId) {
        if (userId == null) {
            return null;
        }

        AuthUserResponse response = restClient.get()
            .uri("/users/{id}", userId)
            .retrieve()
            .body(AuthUserResponse.class);
        return response == null ? null : response.email();
    }

    private record AuthUserResponse(Long id, String fullName, String email, String role, String unitNumber, String tower, String avatarUrl) {}
}
