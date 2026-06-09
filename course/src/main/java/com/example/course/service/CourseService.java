package com.example.course.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.example.course.entity.Course;

import java.util.List;

public interface CourseService extends IService<Course> {
    List<Course> getAllCourses();
}
