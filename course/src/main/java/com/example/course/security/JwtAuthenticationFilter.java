package com.example.course.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Collections;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtTokenProvider jwtTokenProvider;
    private final StringRedisTemplate redisTemplate;

    public JwtAuthenticationFilter(JwtTokenProvider jwtTokenProvider, StringRedisTemplate redisTemplate) {
        this.jwtTokenProvider = jwtTokenProvider;
        this.redisTemplate = redisTemplate;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String token = extractToken(request);

        if (token != null) {
            String userId = null;
            try {
                String cacheKey = "token:" + token;
                String cachedUserId = redisTemplate.opsForValue().get(cacheKey);
                if (cachedUserId != null) {
                    userId = cachedUserId;
                }
            } catch (Exception ignored) {
                // Redis down — fallback to JWT signature validation
            }

            if (userId == null && jwtTokenProvider.validateToken(token)) {
                userId = jwtTokenProvider.getUserIdFromToken(token);
                try {
                    String cacheKey = "token:" + token;
                    redisTemplate.opsForValue().set(
                            cacheKey, userId,
                            jwtTokenProvider.getExpiration(),
                            java.util.concurrent.TimeUnit.MILLISECONDS
                    );
                } catch (Exception ignored) {
                    // Redis down — skip cache write
                }
            }

            if (userId != null) {
                UsernamePasswordAuthenticationToken authentication =
                        new UsernamePasswordAuthenticationToken(userId, null, Collections.emptyList());
                SecurityContextHolder.getContext().setAuthentication(authentication);
            }
        }

        filterChain.doFilter(request, response);
    }

    private String extractToken(HttpServletRequest request) {
        String bearer = request.getHeader("Authorization");
        if (StringUtils.hasText(bearer) && bearer.startsWith("Bearer ")) {
            return bearer.substring(7);
        }
        return null;
    }
}
