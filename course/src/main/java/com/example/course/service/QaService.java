package com.example.course.service;

import com.example.course.entity.ChatMessage;
import com.example.course.entity.QaSource;
import com.example.course.entity.Session;
import com.example.course.rag.RagPipeline;
import com.example.course.vo.ChatMessageVO;
import com.example.course.vo.QaSourceVO;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import reactor.core.publisher.Flux;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;

@Service
public class QaService {

    private static final Logger log = LoggerFactory.getLogger(QaService.class);

    private final SessionService sessionService;
    private final ChatMessageService chatMessageService;
    private final QaSourceService qaSourceService;
    private final RagPipeline ragPipeline;
    private final ObjectMapper objectMapper;

    public QaService(SessionService sessionService, ChatMessageService chatMessageService,
                     QaSourceService qaSourceService, RagPipeline ragPipeline, ObjectMapper objectMapper) {
        this.sessionService = sessionService;
        this.chatMessageService = chatMessageService;
        this.qaSourceService = qaSourceService;
        this.ragPipeline = ragPipeline;
        this.objectMapper = objectMapper;
    }

    @Transactional
    public ChatMessageVO ask(String sessionId, String courseId, String question, String userId) {
        Session session = getOrCreateSession(sessionId, courseId, userId, question);

        List<ChatMessage> history = chatMessageService.getRecentBySessionId(session.getId(), 5);
        RagPipeline.RagResult result = ragPipeline.answer(session.getCourseId(), question, history);

        ChatMessage userMsg = saveMessage(session.getId(), "user", question);
        ChatMessage assistantMsg = saveMessage(session.getId(), "assistant", result.answer());
        saveSources(assistantMsg.getId(), result.sources());
        touchSession(session, question);

        return toMessageVO(assistantMsg, result.sources(), session.getId());
    }

    public Flux<String> askStream(String sessionId, String courseId, String question, String userId) {
        try {
            Session session = getOrCreateSession(sessionId, courseId, userId, question);
            String sid = session.getId();

            RagPipeline.RagContext ctx = ragPipeline.prepareContext(session.getCourseId(), question);

            List<ChatMessage> history = chatMessageService.getRecentBySessionId(sid, 5);

            StringBuilder fullAnswer = new StringBuilder();
            List<String> sourceTexts = ctx.sources();

            saveMessage(sid, "user", question);
            ChatMessage assistantMsg = saveMessage(sid, "assistant", "");
            saveSources(assistantMsg.getId(), sourceTexts);

            List<QaSource> savedSources = qaSourceService.getByMessageId(assistantMsg.getId());
            String sourcesJson;
            try {
                List<QaSourceVO> vos = savedSources.stream().map(s -> {
                    QaSourceVO vo = new QaSourceVO();
                    vo.setId(s.getId());
                    vo.setContent(s.getContent());
                    return vo;
                }).toList();
                sourcesJson = objectMapper.writeValueAsString(vos);
            } catch (JsonProcessingException e) {
                sourcesJson = "[]";
            }

            AtomicBoolean hasError = new AtomicBoolean(false);

            Flux<String> answerFlux = ragPipeline.answerStream(ctx, question, history)
                    .filter(token -> token != null && !token.isEmpty())
                    .doOnNext(token -> fullAnswer.append(token))
                    .map(token -> {
                        try {
                            return objectMapper.writeValueAsString(Map.of("type", "token", "content", token));
                        } catch (JsonProcessingException e) {
                            return "{\"type\":\"error\",\"content\":\"token序列化异常\"}";
                        }
                    })
                    .onErrorResume(e -> {
                        hasError.set(true);
                        log.error("askStream streaming 阶段失败", e);
                        String msg = e.getMessage() != null
                                ? e.getMessage().replace("\"", "'").replace("\n", " ")
                                : "未知错误";
                        return Flux.just("{\"type\":\"error\",\"content\":\"" + msg + "\",\"sessionId\":\"" + sid + "\"}");
                    });

            Flux<String> doneEvent = Flux.defer(() -> {
                if (hasError.get()) {
                    assistantMsg.setContent(fullAnswer.toString());
                    chatMessageService.updateById(assistantMsg);
                    return Flux.empty();
                }
                assistantMsg.setContent(fullAnswer.toString());
                chatMessageService.updateById(assistantMsg);
                touchSession(session, question);

                ChatMessageVO vo = new ChatMessageVO();
                vo.setRole("assistant");
                vo.setContent(fullAnswer.toString());
                vo.setSources(savedSources.stream().map(s -> {
                    QaSourceVO sv = new QaSourceVO();
                    sv.setId(s.getId());
                    sv.setContent(s.getContent());
                    return sv;
                }).toList());
                vo.setCreatedAt(assistantMsg.getCreatedAt());
                String msgJson;
                try {
                    msgJson = objectMapper.writeValueAsString(vo);
                } catch (JsonProcessingException e) {
                    msgJson = "{}";
                }
                return Flux.just("{\"type\":\"done\",\"data\":" + msgJson + ",\"sessionId\":\"" + sid + "\"}");
            });

            return Flux.concat(
                    Flux.just("{\"type\":\"start\",\"role\":\"assistant\"}"),
                    Flux.just("{\"type\":\"sources\",\"data\":" + sourcesJson + "}"),
                    answerFlux,
                    doneEvent
            );
        } catch (Exception e) {
            log.error("askStream 同步阶段失败", e);
            String msg = e.getMessage() != null
                    ? e.getMessage().replace("\"", "'").replace("\n", " ")
                    : "未知错误";
            return Flux.just("{\"type\":\"error\",\"content\":\"" + msg + "\"}");
        }
    }

    public List<ChatMessageVO> getSessionHistory(String sessionId, String userId) {
        Session session = sessionService.getById(sessionId);
        if (session == null || Boolean.TRUE.equals(session.getDeleted()))
            throw new RuntimeException("会话不存在");
        if (!session.getUserId().equals(userId)) throw new RuntimeException("无权访问该会话");

        List<ChatMessage> messages = chatMessageService.getBySessionId(sessionId);
        return messages.stream().map(m -> {
            if ("assistant".equals(m.getRole())) {
                List<String> sources = qaSourceService.getByMessageId(m.getId())
                        .stream().map(QaSource::getContent).toList();
                return toMessageVO(m, sources);
            }
            return toMessageVO(m, List.of());
        }).toList();
    }

    private ChatMessage saveMessage(String sessionId, String role, String content) {
        ChatMessage msg = new ChatMessage();
        msg.setSessionId(sessionId);
        msg.setRole(role);
        msg.setContent(content);
        chatMessageService.save(msg);
        return msg;
    }

    private void saveSources(String messageId, List<String> sourceTexts) {
        for (String text : sourceTexts) {
            QaSource source = new QaSource();
            source.setMessageId(messageId);
            source.setContent(text);
            qaSourceService.save(source);
        }
    }

    private ChatMessageVO toMessageVO(ChatMessage msg, List<String> sources) {
        ChatMessageVO vo = new ChatMessageVO();
        vo.setRole(msg.getRole());
        vo.setContent(msg.getContent());
        vo.setCreatedAt(msg.getCreatedAt());
        if (!sources.isEmpty()) {
            vo.setSources(sources.stream().map(t -> {
                QaSourceVO sv = new QaSourceVO();
                sv.setContent(t);
                return sv;
            }).toList());
        }
        return vo;
    }

    private ChatMessageVO toMessageVO(ChatMessage msg, List<String> sources, String sessionId) {
        ChatMessageVO vo = toMessageVO(msg, sources);
        vo.setSessionId(sessionId);
        return vo;
    }

    private Session getOrCreateSession(String sessionId, String courseId, String userId, String question) {
        if (sessionId != null && !sessionId.isBlank()) {
            return validateSessionOwnership(sessionId, userId);
        }
        Session session = new Session();
        session.setUserId(userId);
        session.setCourseId(courseId);
        session.setTitle(question.length() > 50 ? question.substring(0, 50) + "..." : question);
        sessionService.save(session);
        return session;
    }

    private Session validateSessionOwnership(String sessionId, String userId) {
        Session session = sessionService.getById(sessionId);
        if (session == null || Boolean.TRUE.equals(session.getDeleted()))
            throw new RuntimeException("会话不存在");
        if (!session.getUserId().equals(userId)) throw new RuntimeException("无权访问该会话");
        return session;
    }

    private void touchSession(Session session, String question) {
        session.setUpdatedAt(LocalDateTime.now());
        if (session.getTitle() == null || session.getTitle().isBlank()) {
            session.setTitle(question.length() > 50 ? question.substring(0, 50) + "..." : question);
        }
        sessionService.updateById(session);
    }
}
