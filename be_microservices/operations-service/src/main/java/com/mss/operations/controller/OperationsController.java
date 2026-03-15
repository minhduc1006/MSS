package com.mss.operations.controller;

import com.mss.operations.dto.OperationsDtos;
import com.mss.operations.service.OperationsDomainService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/operations")
public class OperationsController {
    private final OperationsDomainService service;

    public OperationsController(OperationsDomainService service) {
        this.service = service;
    }

    @GetMapping("/activity")
    public List<OperationsDtos.ActivityItem> activity() {
        return service.activities();
    }

    @GetMapping("/staff/{staffId}/tasks")
    public OperationsDtos.TaskBundle tasks(@PathVariable Long staffId) {
        return service.tasks(staffId);
    }
}
