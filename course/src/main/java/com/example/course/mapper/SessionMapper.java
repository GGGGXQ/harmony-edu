package com.example.course.mapper;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.course.entity.Session;

import java.util.List;

public interface SessionMapper extends BaseMapper<Session> {

    default List<Session> selectByUserIdAndCourseIdOrderByUpdatedAtDesc(String userId, String courseId) {
        return selectList(buildQuery(userId, courseId));
    }

    default List<Session> selectPageByUserIdAndCourseId(int offset, int size, String userId, String courseId) {
        return selectList(buildQuery(userId, courseId)
                .last("LIMIT " + size + " OFFSET " + offset));
    }

    default long countByUserIdAndCourseId(String userId, String courseId) {
        return selectCount(buildQuery(userId, courseId));
    }

    private LambdaQueryWrapper<Session> buildQuery(String userId, String courseId) {
        var wrapper = new LambdaQueryWrapper<Session>()
                .eq(Session::getUserId, userId)
                .eq(Session::getDeleted, false)
                .orderByDesc(Session::getUpdatedAt);
        if (courseId != null) {
            wrapper.eq(Session::getCourseId, courseId);
        }
        return wrapper;
    }
}
