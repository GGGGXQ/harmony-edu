package com.example.course.vo;

import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data
public class ChatMessageVO {
    private String role;
    private String content;
    private List<QaSourceVO> sources;
    private LocalDateTime createdAt;
    private String sessionId;
}
