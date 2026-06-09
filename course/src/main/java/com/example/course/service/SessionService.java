package com.example.course.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.example.course.entity.Session;

import java.util.List;

public interface SessionService extends IService<Session> {
    List<Session> getByUserIdAndCourseId(String userId, String courseId);
    List<Session> getPageByUserIdAndCourseId(int offset, int size, String userId, String courseId);
    long countByUserIdAndCourseId(String userId, String courseId);
}
