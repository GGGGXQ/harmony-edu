package com.example.course.rag.chunk;

import java.util.Map;

public class DocumentChunk {

    private final String text;
    private final Map<String, Object> metadata;

    public DocumentChunk(String text, Map<String, Object> metadata) {
        this.text = text;
        this.metadata = metadata;
    }

    public String getText() {
        return text;
    }

    public Map<String, Object> getMetadata() {
        return metadata;
    }
}
