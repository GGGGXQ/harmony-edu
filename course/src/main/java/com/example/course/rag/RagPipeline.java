package com.example.course.rag;

import com.example.course.entity.ChatMessage;
import com.example.course.entity.Course;
import com.example.course.mapper.CourseMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.model.StreamingChatModel;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.ai.chat.prompt.PromptTemplate;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class RagPipeline {

    private static final Logger log = LoggerFactory.getLogger(RagPipeline.class);

    private final EmbeddingModel embeddingModel;
    private final ChromaService chromaService;
    private final ChatModel chatModel;
    private final StreamingChatModel streamingChatModel;
    private final CourseMapper courseMapper;

    public RagPipeline(EmbeddingModel embeddingModel, ChromaService chromaService,
                        ChatModel chatModel, StreamingChatModel streamingChatModel,
                        CourseMapper courseMapper) {
        this.embeddingModel = embeddingModel;
        this.chromaService = chromaService;
        this.chatModel = chatModel;
        this.streamingChatModel = streamingChatModel;
        this.courseMapper = courseMapper;
    }

    public RagContext prepareContext(String courseId, String question) {
        Course course = courseMapper.selectById(courseId);
        if (course == null) throw new RuntimeException("课程不存在: " + courseId);

        float[] queryEmbedding = embeddingModel.embed(question);
        List<Double> embedding = toDoubleList(queryEmbedding);
        List<Map<String, Object>> retrieved = chromaService.query(course, embedding, 5);

        String context = retrieved.stream()
                .map(r -> (String) r.get("text"))
                .collect(Collectors.joining("\n\n---\n\n"));

        log.info("===== RETRIEVED {} CHUNKS =====", retrieved.size());
        for (int i = 0; i < retrieved.size(); i++) {
            String text = (String) retrieved.get(i).get("text");
            log.info("CHUNK {}: {} chars", i + 1, text != null ? text.length() : 0);
        }

        List<String> sources = retrieved.stream()
                .map(r -> r.get("text").toString())
                .toList();

        return new RagContext(context, sources);
    }

    public RagResult answer(String courseId, String question, List<ChatMessage> history) {
        RagContext ctx = prepareContext(courseId, question);

        Prompt prompt = buildPrompt(ctx.context(), history, question);
        log.info("===== PROMPT =====\n{}", prompt.getContents());
        String answer = chatModel.call(prompt).getResult().getOutput().getText();

        return new RagResult(answer, ctx.sources());
    }

    public Flux<String> answerStream(RagContext ctx, String question, List<ChatMessage> history) {
        Prompt prompt = buildPrompt(ctx.context(), history, question);
        log.info("===== PROMPT =====\n{}", prompt.getContents());
        return streamingChatModel.stream(prompt)
                .map(response -> {
                    if (response.getResult() != null && response.getResult().getOutput() != null) {
                        String text = response.getResult().getOutput().getText();
                        return text != null ? text : "";
                    }
                    return "";
                })
                .filter(token -> !token.isEmpty());
    }

    private Prompt buildPrompt(String context, List<ChatMessage> history, String question) {
        String historyText = history.stream()
                .map(m -> ("user".equals(m.getRole()) ? "用户" : "助手") + "：" + m.getContent())
                .collect(Collectors.joining("\n"));

        String template = """
                你是一个教育助手。基于以下资料和对话历史回答学习者的问题。
                如果资料中找不到答案，请如实说明。

                对话历史：
                {history}

                资料：
                {context}

                当前问题：{question}
                """;
        return new PromptTemplate(template)
                .create(Map.of("context", context, "history", historyText, "question", question));
    }

    private static List<Double> toDoubleList(float[] arr) {
        var list = new java.util.ArrayList<Double>(arr.length);
        for (float v : arr) list.add((double) v);
        return list;
    }

    public record RagContext(String context, List<String> sources) {}
    public record RagResult(String answer, List<String> sources) {}
}
