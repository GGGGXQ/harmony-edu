package com.example.course.rag.chunk;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Component
public class CompositeChunker {

    private final MarkdownSplitter markdownSplitter;
    private final SentenceChunker sentenceChunker;
    private final int chunkSize;

    public CompositeChunker(
            MarkdownSplitter markdownSplitter,
            SentenceChunker sentenceChunker,
            @Value("${app.ingestion.chunk-size:1000}") int chunkSize) {
        this.markdownSplitter = markdownSplitter;
        this.sentenceChunker = sentenceChunker;
        this.chunkSize = chunkSize;
    }

    public List<DocumentChunk> chunk(String text, Map<String, Object> baseMetadata) {
        List<DocumentChunk> sections = markdownSplitter.chunk(text, baseMetadata);
        List<DocumentChunk> result = new ArrayList<>();

        for (DocumentChunk section : sections) {
            if (section.getText().length() <= chunkSize) {
                result.add(section);
            } else {
                result.addAll(sentenceChunker.chunk(section.getText(), section.getMetadata()));
            }
        }

        return result;
    }
}
