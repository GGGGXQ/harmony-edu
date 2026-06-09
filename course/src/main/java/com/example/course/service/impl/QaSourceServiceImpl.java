package com.example.course.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.course.entity.QaSource;
import com.example.course.mapper.QaSourceMapper;
import com.example.course.service.QaSourceService;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class QaSourceServiceImpl extends ServiceImpl<QaSourceMapper, QaSource> implements QaSourceService {

    @Override
    public List<QaSource> getByMessageId(String messageId) {
        return baseMapper.selectByMessageId(messageId);
    }
}
