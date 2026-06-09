package com.example.course.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("qa_source")
public class QaSource {

    @TableId(type = IdType.ASSIGN_UUID)
    private String id;

    private String messageId;

    private String content;

    private LocalDateTime createdAt;
}
