package com.example.course.rag;

import com.example.course.entity.Course;
import com.example.course.mapper.CourseMapper;
import com.example.course.rag.chunk.DocumentChunk;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.net.ProxySelector;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class ChromaService {

    private final String baseUrl;
    private final ObjectMapper mapper;
    private final CourseMapper courseMapper;

    public ChromaService(@Value("${app.chroma.url}") String baseUrl,
                         CourseMapper courseMapper) {
        this.baseUrl = baseUrl;
        this.mapper = new ObjectMapper();
        this.courseMapper = courseMapper;
    }

    private HttpClient newHttpClient() {
        return HttpClient.newBuilder()
                .version(HttpClient.Version.HTTP_1_1)
                .proxy(ProxySelector.of(null))
                .connectTimeout(Duration.ofSeconds(30))
                .build();
    }

    @PostConstruct
    public void testConnection() {
        System.out.println("[ChromaService] baseUrl = " + baseUrl);
        try {
            HttpRequest req = HttpRequest.newBuilder()
                    .uri(URI.create(baseUrl + "/api/v1/collections"))
                    .GET()
                    .build();
            HttpResponse<String> resp = newHttpClient().send(req, HttpResponse.BodyHandlers.ofString());
            System.out.println("[ChromaService] 连接测试: HTTP " + resp.statusCode());
        } catch (Exception e) {
            System.out.println("[ChromaService] 连接失败: " + e.getClass().getSimpleName() + " - " + e.getMessage());
        }
    }

    private String collectionName(String courseId) {
        return "course_" + courseId + "_docs";
    }

    private String resolveCollectionId(Course course) {
        if (course.getChromaCollectionId() != null) {
            return course.getChromaCollectionId();
        }

        String name = collectionName(course.getId());
        try {
            HttpRequest listReq = HttpRequest.newBuilder()
                    .uri(URI.create(baseUrl + "/api/v1/collections"))
                    .GET()
                    .build();
            HttpResponse<String> listResp = newHttpClient().send(listReq, HttpResponse.BodyHandlers.ofString());
            if (listResp.statusCode() == 200) {
                JsonNode collections = mapper.readTree(listResp.body());
                if (collections.isArray()) {
                    for (JsonNode col : collections) {
                        if (name.equals(col.get("name").asText())) {
                            String id = col.get("id").asText();
                            course.setChromaCollectionId(id);
                            courseMapper.updateById(course);
                            System.out.println("[ChromaService] 找到集合: " + name + " -> " + id);
                            return id;
                        }
                    }
                }
            }
        } catch (Exception ignored) {}

        System.out.println("[ChromaService] 创建集合: " + name);
        try {
            ObjectNode body = mapper.createObjectNode();
            body.put("name", name);

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(baseUrl + "/api/v1/collections"))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(mapper.writeValueAsString(body)))
                    .build();
            HttpResponse<String> resp = newHttpClient().send(request, HttpResponse.BodyHandlers.ofString());
            if (resp.statusCode() != 200 && resp.statusCode() != 201) {
                throw new RuntimeException("创建集合失败: HTTP " + resp.statusCode() + " " + resp.body());
            }
            JsonNode created = mapper.readTree(resp.body());
            String id = created.get("id").asText();
            course.setChromaCollectionId(id);
            courseMapper.updateById(course);
            System.out.println("[ChromaService] 集合创建成功: " + name + " -> " + id);
            return id;
        } catch (Exception e) {
            throw new RuntimeException("Chroma 集合创建/查找失败", e);
        }
    }

    public void storeChunks(Course course, List<DocumentChunk> chunks, List<List<Double>> embeddings, int startIndex) {
        String colId = resolveCollectionId(course);
        System.out.println("[ChromaService] storeChunks: colId=" + colId + ", chunks=" + chunks.size() + ", startIndex=" + startIndex);

        ArrayNode ids = mapper.createArrayNode();
        ArrayNode embeddingsNode = mapper.createArrayNode();
        ArrayNode metadatas = mapper.createArrayNode();
        ArrayNode documents = mapper.createArrayNode();

        for (int i = 0; i < chunks.size(); i++) {
            DocumentChunk chunk = chunks.get(i);
            int globalIndex = startIndex + i;
            ids.add(chunk.getMetadata().get("course_id") + "_" + globalIndex);

            ArrayNode emb = mapper.createArrayNode();
            embeddings.get(i).forEach(emb::add);
            embeddingsNode.add(emb);

            ObjectNode meta = mapper.createObjectNode();
            meta.put("chunk_index", globalIndex);
            if (chunk.getMetadata().get("heading_h1") != null) {
                meta.put("heading_h1", chunk.getMetadata().get("heading_h1").toString());
            }
            if (chunk.getMetadata().get("heading_h2") != null) {
                meta.put("heading_h2", chunk.getMetadata().get("heading_h2").toString());
            }
            if (chunk.getMetadata().get("heading_h3") != null) {
                meta.put("heading_h3", chunk.getMetadata().get("heading_h3").toString());
            }
            if (chunk.getMetadata().get("source") != null) {
                meta.put("source", chunk.getMetadata().get("source").toString());
            }
            metadatas.add(meta);

            documents.add(chunk.getText());
        }

        try {
            ObjectNode body = mapper.createObjectNode();
            body.set("ids", ids);
            body.set("embeddings", embeddingsNode);
            body.set("metadatas", metadatas);
            body.set("documents", documents);

            String json = mapper.writeValueAsString(body);
            System.out.println("[ChromaService] POST /add: bytes=" + json.getBytes().length);

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(baseUrl + "/api/v1/collections/" + colId + "/add"))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(json))
                    .build();

            HttpResponse<String> resp = newHttpClient().send(request, HttpResponse.BodyHandlers.ofString());
            if (resp.statusCode() != 201 && resp.statusCode() != 200) {
                System.out.println("[ChromaService] store 失败: HTTP " + resp.statusCode() + " " + resp.body());
                throw new RuntimeException("Chroma 存储失败: HTTP " + resp.statusCode());
            }
            System.out.println("[ChromaService] store 完成: HTTP " + resp.statusCode());
        } catch (Exception e) {
            System.out.println("[ChromaService] 存储异常: " + e.getClass().getSimpleName() + " - " + e.getMessage());
            throw new RuntimeException("Chroma 存储失败", e);
        }
    }

    public List<Map<String, Object>> query(Course course, List<Double> queryEmbedding, int topK) {
        String colId = resolveCollectionId(course);
        System.out.println("[ChromaService] query: colId=" + colId + ", topK=" + topK);

        try {
            ObjectNode body = mapper.createObjectNode();
            ArrayNode queryEmb = mapper.createArrayNode();
            queryEmbedding.forEach(queryEmb::add);
            body.set("query_embeddings", mapper.createArrayNode().add(queryEmb));
            body.put("n_results", topK);
            body.put("include", mapper.createArrayNode()
                    .add("metadatas")
                    .add("documents")
                    .add("distances"));

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(baseUrl + "/api/v1/collections/" + colId + "/query"))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(mapper.writeValueAsString(body)))
                    .build();

            HttpResponse<String> response = newHttpClient().send(request, HttpResponse.BodyHandlers.ofString());
            System.out.println("[ChromaService] query 响应: HTTP " + response.statusCode());
            JsonNode root = mapper.readTree(response.body());

            List<Map<String, Object>> results = new ArrayList<>();
            JsonNode documents = root.get("documents");
            JsonNode metadatas = root.get("metadatas");
            JsonNode distances = root.get("distances");

            if (documents != null && documents.isArray() && documents.size() > 0) {
                JsonNode docList = documents.get(0);
                JsonNode metaList = metadatas != null ? metadatas.get(0) : null;
                JsonNode distList = distances != null ? distances.get(0) : null;

                for (int i = 0; i < docList.size(); i++) {
                    Map<String, Object> item = new HashMap<>();
                    item.put("text", docList.get(i).asText());
                    if (metaList != null && metaList.get(i) != null) {
                        item.put("metadata", metaList.get(i).toString());
                    }
                    if (distList != null && distList.get(i) != null) {
                        item.put("distance", distList.get(i).asDouble());
                    }
                    results.add(item);
                }
            }

            return results;
        } catch (Exception e) {
            throw new RuntimeException("Chroma 查询失败", e);
        }
    }
}
