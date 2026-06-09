package com.example.course.service;

import com.example.course.dto.LoginDTO;
import com.example.course.dto.RegisterDTO;
import com.example.course.entity.User;
import com.example.course.security.JwtTokenProvider;
import com.example.course.vo.TokenVO;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Random;
import java.util.concurrent.TimeUnit;

@Service
public class AuthService {

    private final UserService userService;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    private final StringRedisTemplate redisTemplate;
    private final EmailService emailService;

    private static final String TOKEN_PREFIX = "token:";
    private static final String CODE_PREFIX = "verify_code:";
    private static final String RATE_PREFIX = "rate_limit:";
    private static final long CODE_TTL = 5;
    private static final long RATE_TTL = 60;

    public AuthService(UserService userService, PasswordEncoder passwordEncoder,
                       JwtTokenProvider jwtTokenProvider, StringRedisTemplate redisTemplate,
                       EmailService emailService) {
        this.userService = userService;
        this.passwordEncoder = passwordEncoder;
        this.jwtTokenProvider = jwtTokenProvider;
        this.redisTemplate = redisTemplate;
        this.emailService = emailService;
    }

    public TokenVO register(RegisterDTO req) {
        if (userService.existsByUsername(req.getUsername())) {
            throw new RuntimeException("用户名已存在");
        }
        if (userService.existsByEmail(req.getEmail())) {
            throw new RuntimeException("邮箱已被注册");
        }

        User user = new User();
        user.setUsername(req.getUsername());
        user.setPassword(passwordEncoder.encode(req.getPassword()));
        user.setEmail(req.getEmail());
        userService.save(user);

        String token = jwtTokenProvider.generateToken(user.getId(), user.getUsername());
        cacheToken(token, user.getId());
        TokenVO vo = new TokenVO();
        vo.setToken(token);
        vo.setUserId(user.getId());
        vo.setUsername(user.getUsername());
        return vo;
    }

    public TokenVO loginByPassword(LoginDTO req) {
        User user = userService.getByEmail(req.getEmail());
        if (user == null) {
            throw new RuntimeException("邮箱或密码错误");
        }

        if (!passwordEncoder.matches(req.getPassword(), user.getPassword())) {
            throw new RuntimeException("邮箱或密码错误");
        }

        String token = jwtTokenProvider.generateToken(user.getId(), user.getUsername());
        cacheToken(token, user.getId());
        TokenVO vo = new TokenVO();
        vo.setToken(token);
        vo.setUserId(user.getId());
        vo.setUsername(user.getUsername());
        return vo;
    }

    public TokenVO loginByCode(String email, String code) {
        String key = CODE_PREFIX + email;
        String savedCode = redisTemplate.opsForValue().get(key);
        if (savedCode == null || !savedCode.equals(code)) {
            throw new RuntimeException("验证码错误或已过期");
        }
        redisTemplate.delete(key);

        User user = userService.getByEmail(email);
        if (user == null) {
            throw new RuntimeException("该邮箱未注册");
        }

        String token = jwtTokenProvider.generateToken(user.getId(), user.getUsername());
        cacheToken(token, user.getId());
        TokenVO vo = new TokenVO();
        vo.setToken(token);
        vo.setUserId(user.getId());
        vo.setUsername(user.getUsername());
        return vo;
    }

    public void sendCode(String email) {
        String rateKey = RATE_PREFIX + "send_code:" + email;
        if (Boolean.TRUE.equals(redisTemplate.hasKey(rateKey))) {
            throw new RuntimeException("请 60 秒后再试");
        }

        String code = String.format("%06d", new Random().nextInt(999999));
        redisTemplate.opsForValue().set(CODE_PREFIX + email, code, CODE_TTL, TimeUnit.MINUTES);
        redisTemplate.opsForValue().set(rateKey, "1", RATE_TTL, TimeUnit.SECONDS);

        emailService.sendVerificationCode(email, code);
    }

    public void logout(String token) {
        redisTemplate.delete(TOKEN_PREFIX + token);
    }

    private void cacheToken(String token, String userId) {
        redisTemplate.opsForValue().set(
                TOKEN_PREFIX + token,
                userId,
                jwtTokenProvider.getExpiration(),
                TimeUnit.MILLISECONDS
        );
    }
}
