package com.example.course.vo;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class CourseVO {
    private String id;
    private String name;
    private String description;
    private LocalDateTime createdAt;
}
