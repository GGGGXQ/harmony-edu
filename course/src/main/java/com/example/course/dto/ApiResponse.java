package com.example.course.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
@Schema(description = "统一响应格式")
public class ApiResponse {

    private int code;
    private String message;
    @Schema(hidden = true)
    @JsonInclude(JsonInclude.Include.NON_NULL)
    private Object data;

    public static ApiResponse success(Object data) {
        return new ApiResponse(200, "success", data);
    }

    public static ApiResponse error(int code, String message) {
        return new ApiResponse(code, message, null);
    }

    public static ApiResponse error(int code, String message, Object data) {
        return new ApiResponse(code, message, data);
    }
}
