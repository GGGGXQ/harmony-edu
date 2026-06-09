package com.example.course.rag;

import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

@Component
public class TextChunker {

    public List<String> chunk(String text, int chunkSize, int overlap) {
        List<String> chunks = new ArrayList<>();
        String[] paragraphs = text.split("\n\n");

        StringBuilder current = new StringBuilder();
        for (String p : paragraphs) {
            String trimmed = p.trim();
            if (trimmed.isEmpty()) continue;

            if (current.length() + trimmed.length() > chunkSize && current.length() > 0) {
                chunks.add(current.toString().trim());
                current = new StringBuilder(getOverlap(current.toString(), overlap));
            }
            current.append(trimmed).append("\n");
        }

        if (!current.isEmpty()) {
            chunks.add(current.toString().trim());
        }

        return chunks;
    }

    private String getOverlap(String text, int overlapChars) {
        if (text.length() <= overlapChars) return text;
        int start = text.length() - overlapChars;
        int newlinePos = text.indexOf('\n', start);
        return text.substring(newlinePos > 0 ? newlinePos : start);
    }

    public List<String> chunk(String text) {
        return chunk(text, 500, 50);
    }
}
