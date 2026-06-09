package com.example.course.config;

import com.example.course.controller.QaWebSocketHandler;
import com.example.course.security.JwtTokenProvider;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

@Configuration
@EnableWebSocket
public class WebSocketConfig implements WebSocketConfigurer {

    private final QaWebSocketHandler qaWebSocketHandler;
    private final JwtTokenProvider jwtTokenProvider;

    public WebSocketConfig(QaWebSocketHandler qaWebSocketHandler, JwtTokenProvider jwtTokenProvider) {
        this.qaWebSocketHandler = qaWebSocketHandler;
        this.jwtTokenProvider = jwtTokenProvider;
    }

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(qaWebSocketHandler, "/ws/qa/ask")
                .addInterceptors(new JwtHandshakeInterceptor(jwtTokenProvider))
                .setAllowedOrigins("*");
    }
}
