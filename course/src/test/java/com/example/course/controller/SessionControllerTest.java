package com.example.course.controller;

import com.example.course.entity.Course;
import com.example.course.entity.Session;
import com.example.course.security.JwtTokenProvider;
import com.example.course.service.CourseService;
import com.example.course.service.QaService;
import com.example.course.service.SessionService;
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
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(SessionController.class)
@Import(SessionControllerTest.TestSecurityConfig.class)
class SessionControllerTest {

    @Autowired
    MockMvc mockMvc;

    @Autowired
    ObjectMapper objectMapper;

    @MockBean
    SessionService sessionService;

    @MockBean
    QaService qaService;

    @MockBean
    CourseService courseService;

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
    void list_returnsSessions() throws Exception {
        Session s = new Session();
        s.setId("session-1");
        s.setCourseId("course-1");
        s.setTitle("测试会话");
        s.setCreatedAt(LocalDateTime.now());
        s.setUpdatedAt(LocalDateTime.now());

        Course c = new Course();
        c.setId("course-1");
        c.setName("计算机网络");

        when(sessionService.getByUserIdAndCourseId(anyString(), isNull())).thenReturn(List.of(s));
        when(courseService.listByIds(anySet())).thenReturn(List.of(c));

        mockMvc.perform(get("/api/sessions"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data[0].id").value("session-1"))
                .andExpect(jsonPath("$.data[0].courseName").value("计算机网络"))
                .andExpect(jsonPath("$.data[0].title").value("测试会话"));
    }

    @Test
    void delete_validRequest_returns200() throws Exception {
        Session session = new Session();
        session.setId("session-1");
        session.setUserId("user-1");

        when(sessionService.getById("session-1")).thenReturn(session);

        mockMvc.perform(delete("/api/sessions/session-1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200));
    }

    @Test
    void delete_notOwner_returns403() throws Exception {
        Session session = new Session();
        session.setId("session-1");
        session.setUserId("other-user");

        when(sessionService.getById("session-1")).thenReturn(session);

        mockMvc.perform(delete("/api/sessions/session-1"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(403));
    }

    @Test
    void delete_notFound_returns404() throws Exception {
        when(sessionService.getById("nonexistent")).thenReturn(null);

        mockMvc.perform(delete("/api/sessions/nonexistent"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(404));
    }

    @Test
    void listByCourse_returnsSessions() throws Exception {
        Session s = new Session();
        s.setId("session-1");
        s.setCourseId("course-1");
        s.setTitle("会话");
        s.setCreatedAt(LocalDateTime.now());
        s.setUpdatedAt(LocalDateTime.now());

        Course c = new Course();
        c.setId("course-1");
        c.setName("计算机网络");

        when(sessionService.getByUserIdAndCourseId(anyString(), eq("course-1"))).thenReturn(List.of(s));
        when(courseService.getById("course-1")).thenReturn(c);

        mockMvc.perform(get("/api/sessions/course-1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data[0].courseName").value("计算机网络"));
    }

    @Test
    void history_returnsMessages() throws Exception {
        ChatMessageVO msg = new ChatMessageVO();
        msg.setRole("user");
        msg.setContent("问题");

        when(qaService.getSessionHistory("session-1", "user-1")).thenReturn(List.of(msg));

        mockMvc.perform(get("/api/sessions/session-1/history"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data[0].role").value("user"))
                .andExpect(jsonPath("$.data[0].content").value("问题"));
    }

    @Test
    void history_serviceError_returns500() throws Exception {
        when(qaService.getSessionHistory("session-1", "user-1"))
                .thenThrow(new RuntimeException("会话不存在"));

        mockMvc.perform(get("/api/sessions/session-1/history"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(500));
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
