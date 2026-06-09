package com.example.course.controller;

import com.example.course.dto.ApiResponse;
import com.example.course.dto.QaDTO;
import com.example.course.service.QaService;
import com.example.course.vo.ChatMessageVO;
import jakarta.validation.Valid;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;

@RestController
@RequestMapping("/api/qa")
public class QaController {

    private final QaService qaService;

    public QaController(QaService qaService) {
        this.qaService = qaService;
    }

    @PostMapping("/ask")
    public ResponseEntity<ApiResponse> ask(@Valid @RequestBody QaDTO req, Authentication auth) {
        try {
            String userId = (String) auth.getPrincipal();
            ChatMessageVO result = qaService.ask(req.getSessionId(), req.getCourseId(), req.getQuestion(), userId);
            return ResponseEntity.ok(ApiResponse.success(result));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(500, e.getMessage()));
        }
    }

    @PostMapping(value = "/ask/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter askStream(@Valid @RequestBody QaDTO req, Authentication auth) {
        String userId = (String) auth.getPrincipal();
        SseEmitter emitter = new SseEmitter(0L);
        System.out.println("[SSE] SseEmitter created for user=" + userId);

        qaService.askStream(req.getSessionId(), req.getCourseId(), req.getQuestion(), userId)
                .doOnNext(data -> System.out.println("[SSE] onNext: " + data.substring(0, Math.min(50, data.length()))))
                .doOnError(e -> System.out.println("[SSE] onError: " + (e.getMessage() != null ? e.getMessage() : e.getClass().getName())))
                .doOnComplete(() -> System.out.println("[SSE] onComplete"))
                .subscribe(
                    data -> {
                        try { emitter.send(SseEmitter.event().data(data)); }
                        catch (IOException e) {
                            System.out.println("[SSE] send error: " + e.getMessage());
                            emitter.completeWithError(e);
                        }
                    },
                    error -> {
                        System.out.println("[SSE] subscribe error: " + (error.getMessage() != null ? error.getMessage() : error.getClass().getName()));
                        try {
                            String msg = error.getMessage() != null
                                ? error.getMessage().replace("\"", "'").replace("\n", " ")
                                : "未知错误";
                            emitter.send(SseEmitter.event().data("{\"type\":\"error\",\"content\":\"" + msg + "\"}"));
                        } catch (IOException e) { System.out.println("[SSE] error handler send failed: " + e.getMessage()); }
                        try { emitter.complete(); } catch (Exception e) { System.out.println("[SSE] error handler complete failed: " + e.getMessage()); }
                    },
                    () -> {
                        System.out.println("[SSE] subscribe complete, calling emitter.complete()");
                        try { emitter.complete(); }
                        catch (Exception e) { System.out.println("[SSE] complete exception: " + e.getMessage()); }
                    }
                );

        System.out.println("[SSE] returning emitter");
        return emitter;
    }
}
