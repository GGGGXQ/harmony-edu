package com.example.course.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class QaDTO {

    private String sessionId;

    @NotBlank
    private String courseId;

    @NotBlank
    private String question;
}
