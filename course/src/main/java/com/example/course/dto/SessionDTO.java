package com.example.course.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class SessionDTO {

    @NotBlank
    private String courseId;
}
