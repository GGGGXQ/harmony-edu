package com.example.course.rag.ingestion;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.course.entity.Course;
import com.example.course.mapper.CourseMapper;
import com.example.course.rag.ChromaService;
import com.example.course.rag.EmbeddingService;
import com.example.course.rag.chunk.CompositeChunker;
import com.example.course.rag.chunk.DocumentChunk;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.*;

@Component
@Profile("ingest")
public class IngestionRunner implements CommandLineRunner {

    private final CourseMapper courseMapper;
    private final CompositeChunker compositeChunker;
    private final EmbeddingService embeddingService;
    private final ChromaService chromaService;
    private final String bookPath;

    public IngestionRunner(
            CourseMapper courseMapper,
            CompositeChunker compositeChunker,
            EmbeddingService embeddingService,
            ChromaService chromaService,
            @Value("${app.ingestion.book-path}") String bookPath) {
        this.courseMapper = courseMapper;
        this.compositeChunker = compositeChunker;
        this.embeddingService = embeddingService;
        this.chromaService = chromaService;
        this.bookPath = bookPath;
    }

    @Override
    public void run(String... args) throws Exception {
        Path path = Paths.get(bookPath);
        if (!Files.exists(path)) {
            System.err.println("文件不存在: " + path.toAbsolutePath());
            System.exit(1);
            return;
        }

        String fileName = path.getFileName().toString().replaceAll("\\.md$", "");
        String text = Files.readString(path);
        System.out.println("[IngestionRunner] 文件大小: " + text.length() + " 字符");

        Course course = createCourse(fileName);

        Map<String, Object> metadata = new HashMap<>();
        metadata.put("source", path.getFileName().toString());
        metadata.put("course_id", course.getId());

        System.out.println("[IngestionRunner] 开始 chunking...");
        List<DocumentChunk> chunks = compositeChunker.chunk(text, metadata);
        System.out.println("[IngestionRunner] chunking 完成: " + chunks.size() + " 块");

        System.out.println("[IngestionRunner] 开始 embedding " + chunks.size() + " 个 chunk，每 10 个存一次 Chroma...");

        int batchSize = 10;
        int totalBatches = (chunks.size() + batchSize - 1) / batchSize;

        for (int batch = 0; batch < totalBatches; batch++) {
            int start = batch * batchSize;
            int end = Math.min(start + batchSize, chunks.size());

            System.out.println("[IngestionRunner] 批量 " + (batch + 1) + "/" + totalBatches + ": embedding " + start + "~" + end);
            List<List<Double>> batchEmbeddings = new ArrayList<>();
            for (int i = start; i < end; i++) {
                List<Double> embedding = embeddingService.embed(chunks.get(i).getText());
                batchEmbeddings.add(embedding);
            }

            System.out.println("[IngestionRunner] 批量 " + (batch + 1) + "/" + totalBatches + ": 写入 Chroma...");
            try {
                chromaService.storeChunks(course, chunks.subList(start, end), batchEmbeddings, start);
            } catch (Exception e) {
                System.err.println("[IngestionRunner] Chroma 写入失败，ingest 终止: " + e.getMessage());
                System.exit(1);
            }
            System.out.println("[IngestionRunner] 批量 " + (batch + 1) + "/" + totalBatches + " 完成");
            try { Thread.sleep(200); } catch (InterruptedException ignored) {}
        }

        System.out.println("=".repeat(40));
        System.out.println("  文档导入完成");
        System.out.println("  文件: " + path.getFileName() + " (" + text.length() + " 字符)");
        System.out.println("  课程: " + course.getName() + " (ID: " + course.getId() + ")");
        System.out.println("  总块数: " + chunks.size());
        if (!chunks.isEmpty()) {
            double avgSize = chunks.stream().mapToInt(c -> c.getText().length()).average().orElse(0);
            System.out.println("  平均块大小: " + String.format("%.0f", avgSize) + " 字符");
        }
        System.out.println("=".repeat(40));

        System.exit(0);
    }

    private Course createCourse(String fileName) {
        Course existing = courseMapper.selectOne(
                new LambdaQueryWrapper<Course>().eq(Course::getName, fileName));
        if (existing != null) {
            System.out.println("  课程已存在: " + fileName);
            return existing;
        }

        Course course = new Course();
        course.setName(fileName);
        course.setDescription("通过文档 [" + fileName + "] 自动导入");
        courseMapper.insert(course);
        System.out.println("  已创建课程: " + fileName);
        return course;
    }
}
