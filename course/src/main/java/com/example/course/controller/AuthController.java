package com.example.course.controller;

import com.example.course.dto.ApiResponse;
import com.example.course.dto.LoginDTO;
import com.example.course.dto.RegisterDTO;
import com.example.course.dto.SendCodeDTO;
import com.example.course.dto.VerifyCodeDTO;
import com.example.course.service.AuthService;
import com.example.course.vo.TokenVO;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register")
    public ResponseEntity<ApiResponse> register(@Valid @RequestBody RegisterDTO req) {
        try {
            return ResponseEntity.ok(ApiResponse.success(authService.register(req)));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(400, e.getMessage()));
        }
    }

    @PostMapping("/login/password")
    public ResponseEntity<ApiResponse> loginByPassword(@Valid @RequestBody LoginDTO req) {
        try {
            return ResponseEntity.ok(ApiResponse.success(authService.loginByPassword(req)));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(401, e.getMessage()));
        }
    }

    @PostMapping("/login/code")
    public ResponseEntity<ApiResponse> loginByCode(@Valid @RequestBody VerifyCodeDTO req) {
        try {
            TokenVO result = authService.loginByCode(req.getEmail(), req.getCode());
            return ResponseEntity.ok(ApiResponse.success(result));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(401, e.getMessage()));
        }
    }

    @PostMapping("/code/send")
    public ResponseEntity<ApiResponse> sendCode(@Valid @RequestBody SendCodeDTO req) {
        try {
            authService.sendCode(req.getEmail());
            return ResponseEntity.ok(ApiResponse.success(null));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(429, e.getMessage()));
        }
    }

    @PostMapping("/logout")
    public ResponseEntity<ApiResponse> logout(@RequestHeader("Authorization") String token) {
        authService.logout(token.replace("Bearer ", ""));
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}
