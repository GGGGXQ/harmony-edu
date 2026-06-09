package com.example.course.rag;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;

@Service
public class EmbeddingService {

    private final String apiUrl;
    private final String apiKey;
    private final String model;
    private final HttpClient httpClient;
    private final ObjectMapper mapper;

    public EmbeddingService(
            @Value("${app.embedding.base-url}") String baseUrl,
            @Value("${app.embedding.api-key}") String apiKey,
            @Value("${app.embedding.model}") String model) {
        this.apiUrl = baseUrl + (baseUrl.endsWith("/") ? "" : "/") + "text-embedding";
        this.apiKey = apiKey;
        this.model = model;
        this.httpClient = HttpClient.newBuilder()
                .version(HttpClient.Version.HTTP_1_1)
                .connectTimeout(Duration.ofSeconds(30))
                .build();
        this.mapper = new ObjectMapper();
    }

    private int embedCallCount = 0;

    public List<Double> embed(String text) {
        Exception lastException = null;
        for (int attempt = 1; attempt <= 3; attempt++) {
            if (attempt > 1) {
                System.out.println("[EmbeddingService] 第 " + attempt + " 次重试...");
            }
            embedCallCount++;
            if (embedCallCount % 50 == 1) {
                System.out.println("[EmbeddingService] 正在 embedding 第 " + embedCallCount + " 个 chunk...");
            }
            try {
                ObjectNode body = mapper.createObjectNode();
                body.put("model", model);
                ObjectNode input = body.putObject("input");
                input.putArray("texts").add(text);

                HttpRequest request = HttpRequest.newBuilder()
                        .uri(URI.create(apiUrl))
                        .header("Content-Type", "application/json")
                        .header("Authorization", "Bearer " + apiKey)
                        .POST(HttpRequest.BodyPublishers.ofString(mapper.writeValueAsString(body)))
                        .build();

                HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

                if (response.statusCode() != 200) {
                    throw new RuntimeException("Embedding API 返回 " + response.statusCode() + ": " + response.body());
                }

                JsonNode root = mapper.readTree(response.body());
                JsonNode output = root.get("output");
                JsonNode embeddings = output != null ? output.get("embeddings") : null;
                if (embeddings != null && embeddings.isArray() && embeddings.size() > 0) {
                    JsonNode embedding = embeddings.get(0).get("embedding");
                    List<Double> result = new ArrayList<>();
                    if (embedding.isArray()) {
                        for (JsonNode v : embedding) {
                            result.add(v.asDouble());
                        }
                    }
                    return result;
                }
                throw new RuntimeException("Embedding API 响应格式异常");
            } catch (RuntimeException e) {
                lastException = e;
                if (attempt < 3) {
                    try { Thread.sleep(1000L * attempt); } catch (InterruptedException ie) { Thread.currentThread().interrupt(); }
                }
            } catch (Exception e) {
                lastException = new RuntimeException("Embedding 调用失败: " + e.getMessage(), e);
                if (attempt < 3) {
                    try { Thread.sleep(1000L * attempt); } catch (InterruptedException ie) { Thread.currentThread().interrupt(); }
                }
            }
        }
        throw new RuntimeException("Embedding 调用失败（重试 3 次后）", lastException);
    }

    public List<List<Double>> embedBatch(List<String> texts) {
        return texts.stream().map(this::embed).toList();
    }
}
