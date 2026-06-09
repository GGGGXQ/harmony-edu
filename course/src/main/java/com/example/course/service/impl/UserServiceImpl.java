package com.example.course.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.course.entity.User;
import com.example.course.mapper.UserMapper;
import com.example.course.service.UserService;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.concurrent.TimeUnit;

@Service
public class UserServiceImpl extends ServiceImpl<UserMapper, User> implements UserService {

    private static final String KEY_TODAY = "signin:today:";
    private static final String KEY_DAYS = "signin:days:";

    private final StringRedisTemplate redisTemplate;

    public UserServiceImpl(StringRedisTemplate redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    @Override
    public User getByUsername(String username) {
        return baseMapper.selectByUsername(username);
    }

    @Override
    public User getByEmail(String email) {
        return baseMapper.selectByEmail(email);
    }

    @Override
    public boolean existsByUsername(String username) {
        return baseMapper.existsByUsername(username);
    }

    @Override
    public boolean existsByEmail(String email) {
        return baseMapper.existsByEmail(email);
    }

    @Override
    @Transactional
    public void signin(String userId) {
        String todayKey = KEY_TODAY + userId;
        String cache = redisTemplate.opsForValue().get(todayKey);
        if (cache != null) {
            throw new IllegalStateException("今日已签到");
        }
        User user = getById(userId);
        if (user == null) {
            throw new IllegalArgumentException("用户不存在");
        }
        if (Boolean.TRUE.equals(user.getTodaySigned())) {
            redisTemplate.opsForValue().set(todayKey, "1", 1, TimeUnit.DAYS);
            throw new IllegalStateException("今日已签到");
        }
        user.setTodaySigned(true);
        user.setSigninDays(user.getSigninDays() == null ? 1 : user.getSigninDays() + 1);
        updateById(user);
        redisTemplate.opsForValue().set(todayKey, "1", 1, TimeUnit.DAYS);
        redisTemplate.delete(KEY_DAYS + userId);
    }

    @Override
    public Integer getSigninDays(String userId) {
        String daysKey = KEY_DAYS + userId;
        String cache = redisTemplate.opsForValue().get(daysKey);
        if (cache != null) {
            return Integer.valueOf(cache);
        }
        User user = getById(userId);
        if (user == null) {
            throw new IllegalArgumentException("用户不存在");
        }
        Integer days = user.getSigninDays() == null ? 0 : user.getSigninDays();
        redisTemplate.opsForValue().set(daysKey, String.valueOf(days), 1, TimeUnit.DAYS);
        return days;
    }
}
