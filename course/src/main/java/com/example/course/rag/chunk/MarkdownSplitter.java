package com.example.course.rag.chunk;

import org.springframework.stereotype.Component;

import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Component
public class MarkdownSplitter implements ChunkingStrategy {

    private static final Pattern HEADING = Pattern.compile("^(#{1,6})\\s+(.+)$");

    @Override
    public List<DocumentChunk> chunk(String text, Map<String, Object> baseMetadata) {
        List<Section> sections = parseSections(text);
        return buildChunks(sections, baseMetadata);
    }

    private List<Section> parseSections(String text) {
        List<Section> sections = new ArrayList<>();
        String[] lines = text.split("\n", -1);
        StringBuilder content = new StringBuilder();
        String currentHeading = null;
        int currentLevel = 0;
        String[] headingPath = new String[7];
        boolean inCodeBlock = false;

        for (String line : lines) {
            if (line.trim().startsWith("```")) {
                inCodeBlock = !inCodeBlock;
            }

            if (!inCodeBlock) {
                Matcher matcher = HEADING.matcher(line);
                if (matcher.find()) {
                    String trimmed = content.toString().trim();
                    if (!trimmed.isEmpty()) {
                        String[] path = Arrays.copyOf(headingPath, headingPath.length);
                        sections.add(new Section(currentHeading, currentLevel, trimmed, path));
                    }
                    content = new StringBuilder();
                    currentLevel = matcher.group(1).length();
                    currentHeading = matcher.group(2).trim();
                    headingPath[currentLevel] = currentHeading;
                    for (int i = currentLevel + 1; i <= 6; i++) {
                        headingPath[i] = null;
                    }
                    continue;
                }
            }

            content.append(line).append("\n");
        }

        if (!content.toString().trim().isEmpty()) {
            String[] path = Arrays.copyOf(headingPath, headingPath.length);
            sections.add(new Section(currentHeading, currentLevel, content.toString().trim(), path));
        }

        return sections;
    }

    private List<DocumentChunk> buildChunks(List<Section> sections, Map<String, Object> baseMetadata) {
        List<DocumentChunk> chunks = new ArrayList<>();
        for (Section section : sections) {
            Map<String, Object> metadata = new HashMap<>(baseMetadata);
            metadata.put("heading_level", section.level);
            if (section.path[1] != null) metadata.put("heading_h1", section.path[1]);
            if (section.path[2] != null) metadata.put("heading_h2", section.path[2]);
            if (section.path[3] != null) metadata.put("heading_h3", section.path[3]);
            if (section.path[4] != null) metadata.put("heading_h4", section.path[4]);
            metadata.put("heading", section.heading != null ? section.heading : "");
            chunks.add(new DocumentChunk(section.content, metadata));
        }
        return chunks;
    }

    private static class Section {
        final String heading;
        final int level;
        final String content;
        final String[] path;

        Section(String heading, int level, String content, String[] path) {
            this.heading = heading;
            this.level = level;
            this.content = content;
            this.path = path;
        }
    }
}
