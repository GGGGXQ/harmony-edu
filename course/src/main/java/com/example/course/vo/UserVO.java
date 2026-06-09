package com.example.course.vo;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class UserVO {
    private String id;
    private String username;
    private String email;
    private Boolean todaySigned;
    private Integer signinDays;
    private LocalDateTime createdAt;
}
