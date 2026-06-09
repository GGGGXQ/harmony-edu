package com.example.course.vo;

import com.fasterxml.jackson.annotation.JsonInclude;
import io.swagger.v3.oas.annotations.media.Schema;

import java.util.List;

@JsonInclude(JsonInclude.Include.NON_NULL)
@Schema(description = "分页响应")
public record PageVO<T>(
        @Schema(description = "数据列表") List<T> records,
        @Schema(description = "总数") long total,
        @Schema(description = "当前页码") int page,
        @Schema(description = "每页大小") int size,
        @Schema(description = "总页数") int pages
) {}
