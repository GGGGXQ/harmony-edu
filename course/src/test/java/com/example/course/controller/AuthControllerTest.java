package com.example.course.controller;

import com.example.course.dto.LoginDTO;
import com.example.course.dto.RegisterDTO;
import com.example.course.security.JwtTokenProvider;
import com.example.course.service.AuthService;
import com.example.course.vo.TokenVO;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(AuthController.class)
@Import(AuthControllerTest.TestSecurityConfig.class)
class AuthControllerTest {

    @Autowired
    MockMvc mockMvc;

    @Autowired
    ObjectMapper objectMapper;

    @MockBean
    AuthService authService;

    @MockBean
    JwtTokenProvider jwtTokenProvider;

    @MockBean
    StringRedisTemplate stringRedisTemplate;

    @Test
    void register_validRequest_returns200() throws Exception {
        TokenVO vo = new TokenVO();
        vo.setToken("xxx");
        vo.setUserId("1");
        vo.setUsername("test");
        when(authService.register(any())).thenReturn(vo);

        RegisterDTO req = new RegisterDTO();
        req.setUsername("testuser");
        req.setPassword("123456");
        req.setEmail("test@test.com");

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.token").value("xxx"));
    }

    @Test
    void register_invalidRequest_returns400() throws Exception {
        RegisterDTO req = new RegisterDTO();
        req.setUsername("ab");

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void loginByPassword_validRequest_returns200() throws Exception {
        TokenVO vo = new TokenVO();
        vo.setToken("xxx");
        vo.setUserId("1");
        vo.setUsername("test");
        when(authService.loginByPassword(any())).thenReturn(vo);

        LoginDTO req = new LoginDTO();
        req.setEmail("test@test.com");
        req.setPassword("123456");

        mockMvc.perform(post("/api/auth/login/password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200));
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
