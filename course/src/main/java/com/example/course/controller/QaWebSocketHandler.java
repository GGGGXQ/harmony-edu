package com.example.course.controller;

import com.example.course.dto.QaDTO;
import com.example.course.service.QaService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;
import reactor.core.Disposable;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class QaWebSocketHandler extends TextWebSocketHandler {

    private static final Logger log = LoggerFactory.getLogger(QaWebSocketHandler.class);

    private final QaService qaService;
    private final ObjectMapper objectMapper;

    private final Map<String, Disposable> subscriptions = new ConcurrentHashMap<>();

    public QaWebSocketHandler(QaService qaService, ObjectMapper objectMapper) {
        this.qaService = qaService;
        this.objectMapper = objectMapper;
    }

    @Override
    public void handleTextMessage(WebSocketSession session, TextMessage message) {
        String userId = (String) session.getAttributes().get("userId");
        if (userId == null) {
            try { session.close(CloseStatus.POLICY_VIOLATION); } catch (IOException ignored) {}
            return;
        }

        cancelPreviousSubscription(session.getId());

        try {
            QaDTO req = objectMapper.readValue(message.getPayload(), QaDTO.class);

            Disposable sub = qaService.askStream(req.getSessionId(), req.getCourseId(), req.getQuestion(), userId)
                    .doOnNext(data -> log.info("[WS] onNext: {}", data.substring(0, Math.min(50, data.length()))))
                    .doOnError(e -> log.error("[WS] onError", e))
                    .doOnComplete(() -> log.info("[WS] onComplete"))
                    .subscribe(
                            data -> {
                                try {
                                    if (session.isOpen()) {
                                        session.sendMessage(new TextMessage(data));
                                    }
                                } catch (IOException e) {
                                    log.warn("[WS] send error: {}", e.getMessage());
                                }
                            },
                            error -> {
                                subscriptions.remove(session.getId());
                                try {
                                    if (session.isOpen()) {
                                        String errMsg = error.getMessage() != null
                                                ? error.getMessage().replace("\"", "'").replace("\n", " ")
                                                : "未知错误";
                                        session.sendMessage(new TextMessage(
                                                "{\"type\":\"error\",\"content\":\"" + errMsg + "\"}"));
                                    }
                                } catch (IOException e) {
                                    log.warn("[WS] error handler failed: {}", e.getMessage());
                                }
                            },
                            () -> {
                                subscriptions.remove(session.getId());
                            }
                    );

            subscriptions.put(session.getId(), sub);
        } catch (Exception e) {
            log.error("[WS] handleTextMessage error", e);
            try {
                String errMsg = e.getMessage() != null
                        ? e.getMessage().replace("\"", "'").replace("\n", " ")
                        : "请求解析失败";
                session.sendMessage(new TextMessage("{\"type\":\"error\",\"content\":\"" + errMsg + "\"}"));
            } catch (IOException ignored) {}
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        cancelPreviousSubscription(session.getId());
    }

    private void cancelPreviousSubscription(String sessionId) {
        Disposable prev = subscriptions.remove(sessionId);
        if (prev != null && !prev.isDisposed()) {
            prev.dispose();
        }
    }
}
