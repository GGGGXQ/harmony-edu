package com.example.course.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.example.course.entity.ChatMessage;

import java.util.List;

public interface ChatMessageService extends IService<ChatMessage> {
    List<ChatMessage> getBySessionId(String sessionId);

    List<ChatMessage> getRecentBySessionId(String sessionId, int limit);
}
