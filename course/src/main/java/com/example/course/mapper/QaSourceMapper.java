package com.example.course.mapper;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.course.entity.QaSource;

import java.util.List;

public interface QaSourceMapper extends BaseMapper<QaSource> {

    default List<QaSource> selectByMessageId(String messageId) {
        return selectList(new LambdaQueryWrapper<QaSource>()
                .eq(QaSource::getMessageId, messageId)
                .orderByAsc(QaSource::getCreatedAt));
    }
}
