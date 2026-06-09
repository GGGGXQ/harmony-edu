package com.example.course.controller;

import com.example.course.dto.ApiResponse;
import com.example.course.dto.ChangePasswordDTO;
import com.example.course.dto.UpdateUserDTO;
import com.example.course.entity.User;
import com.example.course.service.UserService;
import com.example.course.vo.SigninVO;
import com.example.course.vo.UserVO;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;


@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;
    private final PasswordEncoder passwordEncoder;

    public UserController(UserService userService, PasswordEncoder passwordEncoder) {
        this.userService = userService;
        this.passwordEncoder = passwordEncoder;
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse> me(Authentication auth) {
        String userId = (String) auth.getPrincipal();
        User user = userService.getById(userId);
        if (user == null) {
            return ResponseEntity.badRequest().body(ApiResponse.error(404, "用户不存在"));
        }
        return ResponseEntity.ok(ApiResponse.success(toUserVO(user)));
    }

    @PutMapping("/me")
    public ResponseEntity<ApiResponse> update(@Valid @RequestBody UpdateUserDTO req, Authentication auth) {
        String userId = (String) auth.getPrincipal();
        User user = userService.getById(userId);
        if (user == null) {
            return ResponseEntity.badRequest().body(ApiResponse.error(404, "用户不存在"));
        }
        if (req.getEmail() != null) {
            user.setEmail(req.getEmail());
        }
        if (req.getUsername() != null) {
            if (userService.existsByUsername(req.getUsername())) {
                return ResponseEntity.badRequest().body(ApiResponse.error(400, "用户名已存在"));
            }
            user.setUsername(req.getUsername());
        }
        userService.updateById(user);
        return ResponseEntity.ok(ApiResponse.success(toUserVO(user)));
    }

    @PutMapping("/me/password")
    public ResponseEntity<ApiResponse> changePassword(@Valid @RequestBody ChangePasswordDTO req,
                                                             Authentication auth) {
        String userId = (String) auth.getPrincipal();
        User user = userService.getById(userId);
        if (user == null) {
            return ResponseEntity.badRequest().body(ApiResponse.error(404, "用户不存在"));
        }
        if (!passwordEncoder.matches(req.getOldPassword(), user.getPassword())) {
            return ResponseEntity.badRequest().body(ApiResponse.error(400, "原密码错误"));
        }
        user.setPassword(passwordEncoder.encode(req.getNewPassword()));
        userService.updateById(user);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    @PostMapping("/signin")
    public ResponseEntity<ApiResponse> signin(Authentication auth) {
        String userId = (String) auth.getPrincipal();
        try {
            userService.signin(userId);
        } catch (IllegalStateException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(400, e.getMessage()));
        }
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    @GetMapping("/signin/days")
    public ResponseEntity<ApiResponse> signinDays(Authentication auth) {
        String userId = (String) auth.getPrincipal();
        Integer days = userService.getSigninDays(userId);
        User user = userService.getById(userId);
        SigninVO vo = new SigninVO();
        vo.setTodaySigned(user != null && Boolean.TRUE.equals(user.getTodaySigned()));
        vo.setSigninDays(days);
        return ResponseEntity.ok(ApiResponse.success(vo));
    }

    private UserVO toUserVO(User user) {
        UserVO vo = new UserVO();
        vo.setId(user.getId());
        vo.setUsername(user.getUsername());
        vo.setEmail(user.getEmail());
        vo.setTodaySigned(user.getTodaySigned());
        vo.setSigninDays(user.getSigninDays());
        vo.setCreatedAt(user.getCreatedAt());
        return vo;
    }
}
