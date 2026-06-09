package com.example.course.controller;

import com.example.course.dto.ApiResponse;
import com.example.course.entity.Course;
import com.example.course.entity.Session;
import com.example.course.service.CourseService;
import com.example.course.service.QaService;
import com.example.course.service.SessionService;
import com.example.course.vo.ChatMessageVO;
import com.example.course.vo.PageVO;
import com.example.course.vo.SessionVO;
import jakarta.validation.constraints.Min;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/sessions")
@Validated
public class SessionController {

    private final SessionService sessionService;
    private final QaService qaService;
    private final CourseService courseService;

    public SessionController(SessionService sessionService, QaService qaService, CourseService courseService) {
        this.sessionService = sessionService;
        this.qaService = qaService;
        this.courseService = courseService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse> list(
            @RequestParam(defaultValue = "1") @Min(1) int page,
            @RequestParam(defaultValue = "20") @Min(1) int size,
            Authentication auth) {
        String userId = (String) auth.getPrincipal();
        long total = sessionService.countByUserIdAndCourseId(userId, null);
        int offset = (page - 1) * size;
        List<Session> sessions = sessionService.getPageByUserIdAndCourseId(offset, size, userId, null);

        Set<String> courseIds = sessions.stream().map(Session::getCourseId).collect(Collectors.toSet());
        Map<String, String> courseNames = courseService.listByIds(courseIds).stream()
                .collect(Collectors.toMap(Course::getId, Course::getName, (a, b) -> a));

        List<SessionVO> vos = sessions.stream()
                .map(s -> {
                    String courseName = courseNames.get(s.getCourseId());
                    return toSessionVO(s, courseName);
                })
                .toList();

        int pages = (int) Math.ceil((double) total / size);
        return ResponseEntity.ok(ApiResponse.success(new PageVO<>(vos, total, page, size, pages)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse> delete(@PathVariable String id, Authentication auth) {
        String userId = (String) auth.getPrincipal();
        Session session = sessionService.getById(id);
        if (session == null || Boolean.TRUE.equals(session.getDeleted()))
            return ResponseEntity.badRequest().body(ApiResponse.error(404, "会话不存在"));
        if (!session.getUserId().equals(userId))
            return ResponseEntity.badRequest().body(ApiResponse.error(403, "无权删除"));
        session.setDeleted(true);
        sessionService.updateById(session);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    @GetMapping("/{courseId}")
    public ResponseEntity<ApiResponse> listByCourse(
            @PathVariable String courseId,
            @RequestParam(defaultValue = "1") @Min(1) int page,
            @RequestParam(defaultValue = "20") @Min(1) int size,
            Authentication auth) {
        String userId = (String) auth.getPrincipal();
        try {
            long total = sessionService.countByUserIdAndCourseId(userId, courseId);
            int offset = (page - 1) * size;
            List<Session> sessions = sessionService.getPageByUserIdAndCourseId(offset, size, userId, courseId);
            Course course = courseService.getById(courseId);
            String courseName = course != null ? course.getName() : null;
            List<SessionVO> vos = sessions.stream()
                    .map(s -> toSessionVO(s, courseName)).toList();

            int pages = (int) Math.ceil((double) total / size);
            return ResponseEntity.ok(ApiResponse.success(new PageVO<>(vos, total, page, size, pages)));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(500, e.getMessage()));
        }
    }

    @GetMapping("/{id}/history")
    public ResponseEntity<ApiResponse> history(@PathVariable String id, Authentication auth) {
        String userId = (String) auth.getPrincipal();
        try {
            List<ChatMessageVO> messages = qaService.getSessionHistory(id, userId);
            return ResponseEntity.ok(ApiResponse.success(messages));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(500, e.getMessage()));
        }
    }

    private SessionVO toSessionVO(Session s, String courseName) {
        SessionVO vo = new SessionVO();
        vo.setId(s.getId());
        vo.setCourseId(s.getCourseId());
        vo.setCourseName(courseName);
        vo.setTitle(s.getTitle());
        vo.setCreatedAt(s.getCreatedAt());
        vo.setUpdatedAt(s.getUpdatedAt());
        return vo;
    }
}
