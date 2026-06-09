package com.example.course.controller;

import com.example.course.dto.QaDTO;
import com.example.course.security.JwtTokenProvider;
import com.example.course.service.QaService;
import com.example.course.vo.ChatMessageVO;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import reactor.core.publisher.Flux;

import java.util.Collections;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.asyncDispatch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(QaController.class)
@Import(QaControllerTest.TestSecurityConfig.class)
class QaControllerTest {

    @Autowired
    MockMvc mockMvc;

    @Autowired
    ObjectMapper objectMapper;

    @MockBean
    QaService qaService;

    @MockBean
    JwtTokenProvider jwtTokenProvider;

    @MockBean
    StringRedisTemplate stringRedisTemplate;

    @BeforeEach
    void setUp() {
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken("user-1", null, Collections.emptyList()));
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void ask_validRequest_returns200() throws Exception {
        ChatMessageVO vo = new ChatMessageVO();
        vo.setRole("assistant");
        vo.setContent("这是答案");
        vo.setSources(List.of());

        when(qaService.ask(any(), anyString(), anyString(), anyString())).thenReturn(vo);

        QaDTO req = new QaDTO();
        req.setCourseId("course-1");
        req.setQuestion("什么是TCP");

        mockMvc.perform(post("/api/qa/ask")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.role").value("assistant"))
                .andExpect(jsonPath("$.data.content").value("这是答案"));
    }

    @Test
    void ask_invalidRequest_returns400() throws Exception {
        QaDTO req = new QaDTO();
        req.setCourseId("course-1");

        mockMvc.perform(post("/api/qa/ask")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void ask_serviceError_returns500() throws Exception {
        when(qaService.ask(any(), anyString(), anyString(), anyString()))
                .thenThrow(new RuntimeException("内部错误"));

        QaDTO req = new QaDTO();
        req.setCourseId("course-1");
        req.setQuestion("问题");

        mockMvc.perform(post("/api/qa/ask")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(500))
                .andExpect(jsonPath("$.message").value("内部错误"));
    }

    @Test
    void askStream_returnsSseEvents() throws Exception {
        when(qaService.askStream(any(), anyString(), anyString(), anyString()))
                .thenReturn(Flux.just(
                        "{\"type\":\"start\",\"role\":\"assistant\"}",
                        "{\"type\":\"token\",\"content\":\"你好\"}",
                        "{\"type\":\"done\",\"data\":{\"role\":\"assistant\",\"content\":\"你好\"}}"
                ));

        QaDTO req = new QaDTO();
        req.setCourseId("course-1");
        req.setQuestion("你好");

        MvcResult result = mockMvc.perform(post("/api/qa/ask/stream")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(request().asyncStarted())
                .andReturn();

        mockMvc.perform(asyncDispatch(result))
                .andExpect(status().isOk());
    }

    @EnableWebSecurity
    @TestConfiguration
    static class TestSecurityConfig {
        @Bean
        public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
            http.csrf(csrf -> csrf.disable())
                .authorizeHttpRequests(auth -> auth.anyRequest().permitAll());
            return http.build();
        }
    }
}
