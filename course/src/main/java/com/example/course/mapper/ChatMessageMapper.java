package com.example.course.mapper;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.course.entity.ChatMessage;

import java.util.List;

public interface ChatMessageMapper extends BaseMapper<ChatMessage> {

    default List<ChatMessage> selectBySessionId(String sessionId) {
        return selectList(new LambdaQueryWrapper<ChatMessage>()
                .eq(ChatMessage::getSessionId, sessionId)
                .orderByAsc(ChatMessage::getCreatedAt));
    }

    default List<ChatMessage> selectRecentBySessionId(String sessionId, int limit) {
        List<ChatMessage> list = selectList(new LambdaQueryWrapper<ChatMessage>()
                .eq(ChatMessage::getSessionId, sessionId)
                .orderByDesc(ChatMessage::getCreatedAt)
                .last("LIMIT " + limit));
        java.util.Collections.reverse(list);
        return list;
    }
}
