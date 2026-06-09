package com.example.course.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.example.course.entity.User;

public interface UserService extends IService<User> {
    User getByUsername(String username);
    User getByEmail(String email);
    boolean existsByUsername(String username);
    boolean existsByEmail(String email);
    void signin(String userId);
    Integer getSigninDays(String userId);
}
