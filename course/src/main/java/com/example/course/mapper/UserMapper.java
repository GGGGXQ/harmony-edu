package com.example.course.mapper;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.course.entity.User;

public interface UserMapper extends BaseMapper<User> {

    default User selectByUsername(String username) {
        return selectOne(new LambdaQueryWrapper<User>().eq(User::getUsername, username));
    }

    default User selectByEmail(String email) {
        return selectOne(new LambdaQueryWrapper<User>().eq(User::getEmail, email));
    }

    default boolean existsByUsername(String username) {
        return selectCount(new LambdaQueryWrapper<User>().eq(User::getUsername, username)) > 0;
    }

    default boolean existsByEmail(String email) {
        return selectCount(new LambdaQueryWrapper<User>().eq(User::getEmail, email)) > 0;
    }
}
