package com.example.course.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.example.course.entity.QaSource;

import java.util.List;

public interface QaSourceService extends IService<QaSource> {
    List<QaSource> getByMessageId(String messageId);
}
