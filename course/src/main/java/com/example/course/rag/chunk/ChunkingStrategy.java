package com.example.course.rag.chunk;

import java.util.List;
import java.util.Map;

public interface ChunkingStrategy {

    List<DocumentChunk> chunk(String text, Map<String, Object> baseMetadata);
}
