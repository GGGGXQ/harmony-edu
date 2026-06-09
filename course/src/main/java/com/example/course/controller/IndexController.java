package com.example.course.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class IndexController {

    @GetMapping("/")
    public Map<String, Object> index() {
        return Map.of(
                "name", "教育助手 API",
                "version", "1.0.0",
                "status", "running"
        );
    }

    @GetMapping("/api/health")
    public Map<String, Object> health() {
        return Map.of("status", "UP");
    }
}
