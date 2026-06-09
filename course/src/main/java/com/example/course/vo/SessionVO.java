package com.example.course.vo;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class SessionVO {
    private String id;
    private String courseId;
    private String courseName;
    private String title;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
