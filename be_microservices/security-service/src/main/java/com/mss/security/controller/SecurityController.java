package com.mss.security.controller;

import com.mss.security.dto.SecurityDtos;
import com.mss.security.service.SecurityDomainService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/security")
public class SecurityController {
    private final SecurityDomainService service;

    public SecurityController(SecurityDomainService service) {
        this.service = service;
    }

    @GetMapping("/overview")
    public SecurityDtos.SecurityOverview overview() {
        return service.overview();
    }

    @PostMapping("/incidents")
    public SecurityDtos.IncidentItem createIncident(@Valid @RequestBody SecurityDtos.CreateIncidentRequest request) {
        return service.createIncident(request);
    }

    @PostMapping("/sos")
    public SecurityDtos.IncidentItem triggerSos(@Valid @RequestBody SecurityDtos.TriggerSosRequest request) {
        return service.triggerSos(request);
    }

    @GetMapping("/history")
    public SecurityDtos.SecurityHistoryResponse history(@RequestParam long userId, @RequestParam String audience) {
        return service.history(userId, audience);
    }

    @GetMapping("/history/{audience}/{userId}")
    public SecurityDtos.SecurityHistoryResponse historyPath(@PathVariable String audience, @PathVariable Long userId) {
        return service.history(userId, audience);
    }
}
