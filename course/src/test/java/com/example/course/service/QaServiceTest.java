package com.example.course.service;

import com.example.course.entity.ChatMessage;
import com.example.course.entity.QaSource;
import com.example.course.entity.Session;
import com.example.course.rag.RagPipeline;
import com.example.course.vo.ChatMessageVO;
import com.example.course.vo.QaSourceVO;
import com.fasterxml.jackson.core.JsonProcessingException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import reactor.core.publisher.Flux;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class QaServiceTest {

    @Mock
    SessionService sessionService;

    @Mock
    ChatMessageService chatMessageService;

    @Mock
    QaSourceService qaSourceService;

    @Mock
    RagPipeline ragPipeline;

    @Mock
    com.fasterxml.jackson.databind.ObjectMapper objectMapper;

    QaService qaService;

    @BeforeEach
    void setUp() {
        qaService = new QaService(sessionService, chatMessageService, qaSourceService, ragPipeline, objectMapper);
    }

    @Test
    void ask_createNewSession_savesMessagesAndReturnsVO() {
        when(chatMessageService.getRecentBySessionId(anyString(), anyInt())).thenReturn(List.of());
        when(sessionService.save(any(Session.class))).thenAnswer(invocation -> {
            Session s = invocation.getArgument(0);
            s.setId("session-1");
            return true;
        });
        when(chatMessageService.save(any(ChatMessage.class))).thenAnswer(invocation -> {
            ChatMessage m = invocation.getArgument(0);
            if (m.getId() == null) m.setId("msg-" + m.getRole());
            return true;
        });
        when(ragPipeline.answer(anyString(), anyString(), anyList()))
                .thenReturn(new RagPipeline.RagResult("这是答案", List.of("来源1", "来源2")));

        ChatMessageVO result = qaService.ask(null, "course-1", "什么是TCP", "user-1");

        assertEquals("assistant", result.getRole());
        assertEquals("这是答案", result.getContent());
        assertNotNull(result.getSources());
        assertEquals(2, result.getSources().size());

        ArgumentCaptor<ChatMessage> userMsgCaptor = ArgumentCaptor.captor();
        ArgumentCaptor<ChatMessage> assistantMsgCaptor = ArgumentCaptor.captor();
        verify(chatMessageService, times(2)).save(userMsgCaptor.capture());
        List<ChatMessage> allSaved = userMsgCaptor.getAllValues();
        assertEquals(2, allSaved.size());
        assertTrue(allSaved.stream().anyMatch(m -> "user".equals(m.getRole()) && "什么是TCP".equals(m.getContent())));
        assertTrue(allSaved.stream().anyMatch(m -> "assistant".equals(m.getRole()) && "这是答案".equals(m.getContent())));

        ArgumentCaptor<QaSource> sourceCaptor = ArgumentCaptor.captor();
        verify(qaSourceService, times(2)).save(sourceCaptor.capture());
        assertEquals(2, sourceCaptor.getAllValues().size());
        assertEquals("来源1", sourceCaptor.getAllValues().get(0).getContent());
    }

    @Test
    void ask_existingSession_validatesAndSaves() {
        when(chatMessageService.getRecentBySessionId(anyString(), anyInt())).thenReturn(List.of());
        Session session = new Session();
        session.setId("session-1");
        session.setUserId("user-1");
        session.setCourseId("course-1");

        when(sessionService.getById("session-1")).thenReturn(session);
        when(chatMessageService.save(any(ChatMessage.class))).thenAnswer(invocation -> {
            ChatMessage m = invocation.getArgument(0);
            m.setId("msg-" + m.getRole());
            return true;
        });
        when(ragPipeline.answer(anyString(), anyString(), anyList()))
                .thenReturn(new RagPipeline.RagResult("答案", List.of()));

        ChatMessageVO result = qaService.ask("session-1", "course-1", "问题", "user-1");

        assertEquals("assistant", result.getRole());
        verify(sessionService).getById("session-1");
    }

    @Test
    void ask_sessionNotFound_throwsException() {
        when(sessionService.getById("nonexistent")).thenReturn(null);

        RuntimeException ex = assertThrows(RuntimeException.class,
                () -> qaService.ask("nonexistent", "course-1", "问题", "user-1"));
        assertEquals("会话不存在", ex.getMessage());
    }

    @Test
    void ask_sessionNotOwned_throwsException() {
        Session session = new Session();
        session.setId("session-1");
        session.setUserId("other-user");

        when(sessionService.getById("session-1")).thenReturn(session);

        RuntimeException ex = assertThrows(RuntimeException.class,
                () -> qaService.ask("session-1", "course-1", "问题", "user-1"));
        assertEquals("无权访问该会话", ex.getMessage());
    }

    @Test
    void ask_sessionDeleted_throwsException() {
        Session session = new Session();
        session.setId("session-1");
        session.setUserId("user-1");
        session.setDeleted(true);

        when(sessionService.getById("session-1")).thenReturn(session);

        RuntimeException ex = assertThrows(RuntimeException.class,
                () -> qaService.ask("session-1", "course-1", "问题", "user-1"));
        assertEquals("会话不存在", ex.getMessage());
    }

    @Test
    void askStream_emitsStartSourcesAndDoneEvents() throws Exception {
        when(chatMessageService.getRecentBySessionId(anyString(), anyInt())).thenReturn(List.of());
        when(sessionService.save(any(Session.class))).thenAnswer(invocation -> {
            Session s = invocation.getArgument(0);
            s.setId("session-1");
            return true;
        });
        when(chatMessageService.save(any(ChatMessage.class))).thenAnswer(invocation -> {
            ChatMessage m = invocation.getArgument(0);
            m.setId("msg-" + m.getRole());
            m.setCreatedAt(LocalDateTime.now());
            return true;
        });
        when(ragPipeline.prepareContext(anyString(), anyString()))
                .thenReturn(new RagPipeline.RagContext("context", List.of("来源1")));
        when(ragPipeline.answerStream(any(), anyString(), anyList()))
                .thenReturn(Flux.just("token1", "token2"));

        QaSource savedSource = new QaSource();
        savedSource.setId("src-1");
        savedSource.setMessageId("msg-assistant");
        savedSource.setContent("来源1");
        when(qaSourceService.getByMessageId("msg-assistant")).thenReturn(List.of(savedSource));

        when(objectMapper.writeValueAsString(any())).thenReturn("[]");

        List<String> events = new ArrayList<>();
        CountDownLatch latch = new CountDownLatch(1);

        qaService.askStream(null, "course-1", "问题", "user-1")
                .subscribe(
                        events::add,
                        e -> latch.countDown(),
                        latch::countDown
                );

        assertTrue(latch.await(5, TimeUnit.SECONDS));

        assertTrue(events.get(0).contains("\"type\":\"start\""));
        assertTrue(events.get(1).contains("\"type\":\"sources\""));
        assertTrue(events.get(2).contains("\"type\":\"token\""));
        assertTrue(events.get(3).contains("\"type\":\"token\""));
        assertTrue(events.get(4).contains("\"type\":\"done\""));

        verify(chatMessageService, times(2)).save(any(ChatMessage.class));
        verify(chatMessageService).updateById(argThat(m -> "assistant".equals(m.getRole()) && "token1token2".equals(m.getContent())));
        verify(qaSourceService).save(any(QaSource.class));
    }

    @Test
    void getSessionHistory_validSession_returnsMessages() {
        Session session = new Session();
        session.setId("session-1");
        session.setUserId("user-1");

        ChatMessage userMsg = new ChatMessage();
        userMsg.setId("msg-1");
        userMsg.setRole("user");
        userMsg.setContent("问题");
        userMsg.setCreatedAt(LocalDateTime.now());

        ChatMessage assistantMsg = new ChatMessage();
        assistantMsg.setId("msg-2");
        assistantMsg.setRole("assistant");
        assistantMsg.setContent("答案");
        assistantMsg.setCreatedAt(LocalDateTime.now());

        QaSource source = new QaSource();
        source.setId("src-1");
        source.setMessageId("msg-2");
        source.setContent("来源文本");

        when(sessionService.getById("session-1")).thenReturn(session);
        when(chatMessageService.getBySessionId("session-1")).thenReturn(List.of(userMsg, assistantMsg));
        when(qaSourceService.getByMessageId("msg-2")).thenReturn(List.of(source));

        List<ChatMessageVO> messages = qaService.getSessionHistory("session-1", "user-1");

        assertEquals(2, messages.size());
        assertEquals("user", messages.get(0).getRole());
        assertEquals("问题", messages.get(0).getContent());
        assertEquals("assistant", messages.get(1).getRole());
        assertEquals("答案", messages.get(1).getContent());
        assertNotNull(messages.get(1).getSources());
        assertEquals(1, messages.get(1).getSources().size());
        assertEquals("来源文本", messages.get(1).getSources().get(0).getContent());
    }

    @Test
    void getSessionHistory_sessionNotFound_throwsException() {
        when(sessionService.getById("nonexistent")).thenReturn(null);

        RuntimeException ex = assertThrows(RuntimeException.class,
                () -> qaService.getSessionHistory("nonexistent", "user-1"));
        assertEquals("会话不存在", ex.getMessage());
    }

    @Test
    void getSessionHistory_notOwner_throwsException() {
        Session session = new Session();
        session.setId("session-1");
        session.setUserId("other-user");

        when(sessionService.getById("session-1")).thenReturn(session);

        RuntimeException ex = assertThrows(RuntimeException.class,
                () -> qaService.getSessionHistory("session-1", "user-1"));
        assertEquals("无权访问该会话", ex.getMessage());
    }
}
