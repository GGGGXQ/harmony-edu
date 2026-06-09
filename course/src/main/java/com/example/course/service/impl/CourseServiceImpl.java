package com.example.course.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.course.entity.Course;
import com.example.course.mapper.CourseMapper;
import com.example.course.service.CourseService;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class CourseServiceImpl extends ServiceImpl<CourseMapper, Course> implements CourseService {

    @Override
    public List<Course> getAllCourses() {
        return baseMapper.selectAllOrderByCreatedAtDesc();
    }
}
