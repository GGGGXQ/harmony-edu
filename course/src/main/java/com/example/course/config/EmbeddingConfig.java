package com.example.course.config;

import org.springframework.ai.document.MetadataMode;
import org.springframework.ai.openai.OpenAiEmbeddingModel;
import org.springframework.ai.openai.OpenAiEmbeddingOptions;
import org.springframework.ai.openai.api.OpenAiApi;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.web.client.DefaultResponseErrorHandler;
import org.springframework.web.client.RestClient;
import org.springframework.web.reactive.function.client.WebClient;

import java.net.http.HttpClient;
import java.time.Duration;
import java.util.concurrent.Executors;

@Configuration
public class EmbeddingConfig {

    @Bean
    @Primary
    public OpenAiEmbeddingModel dashScopeEmbeddingModel(
            @Value("${app.embedding.api-key}") String apiKey,
            @Value("${app.embedding.model}") String model) {
        HttpClient httpClient = HttpClient.newBuilder()
                .version(HttpClient.Version.HTTP_1_1)
                .connectTimeout(Duration.ofSeconds(30))
                .executor(Executors.newFixedThreadPool(5))
                .build();
        var api = new OpenAiApi("https://dashscope.aliyuncs.com", apiKey,
                "/compatible-mode/v1/chat/completions",
                "/compatible-mode/v1/embeddings",
                RestClient.builder().requestFactory(new JdkClientHttpRequestFactory(httpClient)),
                WebClient.builder(),
                new DefaultResponseErrorHandler());
        var options = OpenAiEmbeddingOptions.builder().model(model).build();
        return new OpenAiEmbeddingModel(api, MetadataMode.EMBED, options);
    }
}
