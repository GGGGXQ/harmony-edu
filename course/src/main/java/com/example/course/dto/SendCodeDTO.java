package com.example.course.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class SendCodeDTO {

    @NotBlank
    @Email
    private String email;
}
