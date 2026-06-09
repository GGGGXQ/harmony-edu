package com.example.course.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import lombok.Data;

@Data
@Schema(description = "更新用户信息请求")
public class UpdateUserDTO {
    @Schema(description = "新用户名")
    private String username;

    @Email(message = "邮箱格式不正确")
    @Schema(description = "新邮箱")
    private String email;
}
