package com.example.course.mapper;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.course.entity.Course;

import java.util.List;

public interface CourseMapper extends BaseMapper<Course> {

    default List<Course> selectAllOrderByCreatedAtDesc() {
        return selectList(new LambdaQueryWrapper<Course>().orderByDesc(Course::getCreatedAt));
    }
}
