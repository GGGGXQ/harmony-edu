package com.example.course.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.course.entity.Session;
import com.example.course.mapper.SessionMapper;
import com.example.course.service.SessionService;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class SessionServiceImpl extends ServiceImpl<SessionMapper, Session> implements SessionService {

    @Override
    public List<Session> getByUserIdAndCourseId(String userId, String courseId) {
        return baseMapper.selectByUserIdAndCourseIdOrderByUpdatedAtDesc(userId, courseId);
    }

    @Override
    public List<Session> getPageByUserIdAndCourseId(int offset, int size, String userId, String courseId) {
        return baseMapper.selectPageByUserIdAndCourseId(offset, size, userId, courseId);
    }

    @Override
    public long countByUserIdAndCourseId(String userId, String courseId) {
        return baseMapper.countByUserIdAndCourseId(userId, courseId);
    }
}
