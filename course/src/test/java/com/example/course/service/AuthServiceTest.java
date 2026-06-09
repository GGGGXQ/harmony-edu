package com.example.course.service;

import com.example.course.dto.LoginDTO;
import com.example.course.dto.RegisterDTO;
import com.example.course.entity.User;
import com.example.course.security.JwtTokenProvider;
import com.example.course.vo.TokenVO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    UserService userService;

    @Mock
    JwtTokenProvider jwtTokenProvider;

    @Mock
    StringRedisTemplate redisTemplate;

    @Mock
    ValueOperations<String, String> valueOps;

    @Mock
    EmailService emailService;

    PasswordEncoder passwordEncoder;
    AuthService authService;

    @BeforeEach
    void setUp() {
        passwordEncoder = new BCryptPasswordEncoder();
        authService = new AuthService(userService, passwordEncoder, jwtTokenProvider, redisTemplate, emailService);
    }

    @Test
    void register_usernameExists_throwsException() {
        when(userService.existsByUsername("existing")).thenReturn(true);

        RegisterDTO req = new RegisterDTO();
        req.setUsername("existing");
        req.setPassword("123456");
        req.setEmail("test@test.com");

        RuntimeException ex = assertThrows(RuntimeException.class, () -> authService.register(req));
        assertEquals("用户名已存在", ex.getMessage());
    }

    @Test
    void register_success_returnsToken() {
        when(userService.existsByUsername("newuser")).thenReturn(false);
        when(userService.existsByEmail("new@test.com")).thenReturn(false);
        doAnswer(invocation -> {
            User u = invocation.getArgument(0);
            u.setId("mock-uuid");
            return true;
        }).when(userService).save(any(User.class));
        when(jwtTokenProvider.generateToken(anyString(), anyString())).thenReturn("mock-token");

        RegisterDTO req = new RegisterDTO();
        req.setUsername("newuser");
        req.setPassword("123456");
        req.setEmail("new@test.com");

        TokenVO result = authService.register(req);
        assertEquals("mock-token", result.getToken());
        assertEquals("newuser", result.getUsername());
        verify(userService).save(any(User.class));
    }

    @Test
    void loginByPassword_wrongPassword_throwsException() {
        User user = new User();
        user.setUsername("user");
        user.setEmail("user@test.com");
        user.setPassword(passwordEncoder.encode("correctpwd"));

        when(userService.getByEmail("user@test.com")).thenReturn(user);

        LoginDTO req = new LoginDTO();
        req.setEmail("user@test.com");
        req.setPassword("wrongpwd");

        RuntimeException ex = assertThrows(RuntimeException.class, () -> authService.loginByPassword(req));
        assertEquals("邮箱或密码错误", ex.getMessage());
    }

    @Test
    void loginByPassword_success_returnsToken() {
        User user = new User();
        user.setId("uid-1");
        user.setUsername("user");
        user.setEmail("user@test.com");
        user.setPassword(passwordEncoder.encode("pwd"));

        when(userService.getByEmail("user@test.com")).thenReturn(user);
        when(jwtTokenProvider.generateToken("uid-1", "user")).thenReturn("mock-token");

        LoginDTO req = new LoginDTO();
        req.setEmail("user@test.com");
        req.setPassword("pwd");

        TokenVO result = authService.loginByPassword(req);
        assertEquals("mock-token", result.getToken());
    }

    @Test
    void sendCode_rateLimit_throwsException() {
        when(redisTemplate.hasKey("rate_limit:send_code:test@test.com")).thenReturn(true);

        RuntimeException ex = assertThrows(RuntimeException.class, () -> authService.sendCode("test@test.com"));
        assertEquals("请 60 秒后再试", ex.getMessage());
    }

    @Test
    void sendCode_success_storesCode() {
        when(redisTemplate.hasKey(anyString())).thenReturn(false);
        when(redisTemplate.opsForValue()).thenReturn(valueOps);

        authService.sendCode("test@test.com");

        verify(valueOps).set(startsWith("verify_code:"), anyString(), eq(5L), any());
        verify(emailService).sendVerificationCode(eq("test@test.com"), anyString());
    }
}
