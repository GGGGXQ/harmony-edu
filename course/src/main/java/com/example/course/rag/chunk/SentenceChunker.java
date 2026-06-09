package com.example.course.rag.chunk;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.text.BreakIterator;
import java.util.*;

@Component
public class SentenceChunker implements ChunkingStrategy {

    private final int chunkSize;
    private final int overlap;

    public SentenceChunker(
            @Value("${app.ingestion.chunk-size:1000}") int chunkSize,
            @Value("${app.ingestion.chunk-overlap:100}") int chunkOverlap) {
        this.chunkSize = chunkSize;
        this.overlap = chunkOverlap;
    }

    @Override
    public List<DocumentChunk> chunk(String text, Map<String, Object> baseMetadata) {
        List<String> sentences = splitSentences(text);
        List<DocumentChunk> chunks = new ArrayList<>();
        int chunkIndex = 0;

        StringBuilder current = new StringBuilder();
        for (String sentence : sentences) {
            if (current.length() + sentence.length() > chunkSize && !current.isEmpty()) {
                Map<String, Object> metadata = new HashMap<>(baseMetadata);
                metadata.put("chunk_type", "sentence");
                metadata.put("chunk_index", chunkIndex++);
                chunks.add(new DocumentChunk(current.toString().trim(), metadata));
                current = new StringBuilder(getOverlapText(current.toString(), overlap));
            }
            current.append(sentence);
        }

        if (!current.isEmpty()) {
            Map<String, Object> metadata = new HashMap<>(baseMetadata);
            metadata.put("chunk_type", "sentence");
            metadata.put("chunk_index", chunkIndex);
            chunks.add(new DocumentChunk(current.toString().trim(), metadata));
        }

        return chunks;
    }

    private List<String> splitSentences(String text) {
        List<String> sentences = new ArrayList<>();
        BreakIterator iterator = BreakIterator.getSentenceInstance(Locale.CHINESE);
        iterator.setText(text);
        int start = iterator.first();
        int end = iterator.next();
        while (end != BreakIterator.DONE) {
            String sentence = text.substring(start, end).trim();
            if (!sentence.isEmpty()) {
                sentences.add(sentence);
            }
            start = end;
            end = iterator.next();
        }
        return sentences;
    }

    private String getOverlapText(String text, int overlapChars) {
        if (text.length() <= overlapChars) return text;
        int start = text.length() - overlapChars;
        int newlinePos = text.indexOf('\n', start);
        return text.substring(newlinePos > 0 ? newlinePos : start);
    }
}
