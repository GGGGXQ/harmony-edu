package com.example.course.controller;

import com.example.course.dto.ApiResponse;
import com.example.course.entity.Course;
import com.example.course.service.CourseService;
import com.example.course.vo.CourseVO;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/courses")
public class CourseController {

    private final CourseService courseService;

    public CourseController(CourseService courseService) {
        this.courseService = courseService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse> list() {
        List<Course> courses = courseService.getAllCourses();
        List<CourseVO> vos = courses.stream().map(this::toCourseVO).toList();
        return ResponseEntity.ok(ApiResponse.success(vos));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse> get(@PathVariable String id) {
        Course course = courseService.getById(id);
        if (course == null) {
            return ResponseEntity.badRequest().body(ApiResponse.error(404, "课程不存在"));
        }
        return ResponseEntity.ok(ApiResponse.success(toCourseVO(course)));
    }

    private CourseVO toCourseVO(Course course) {
        CourseVO vo = new CourseVO();
        vo.setId(course.getId());
        vo.setName(course.getName());
        vo.setDescription(course.getDescription());
        vo.setCreatedAt(course.getCreatedAt());
        return vo;
    }
}
