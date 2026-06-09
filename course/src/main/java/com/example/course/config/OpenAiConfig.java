package com.example.course.config;

import org.springframework.ai.openai.OpenAiChatModel;
import org.springframework.ai.openai.OpenAiChatOptions;
import org.springframework.ai.openai.api.OpenAiApi;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.http.client.reactive.ReactorClientHttpConnector;
import org.springframework.web.client.DefaultResponseErrorHandler;
import org.springframework.web.client.RestClient;
import org.springframework.web.reactive.function.client.WebClient;

import java.net.http.HttpClient;
import java.time.Duration;
import java.util.concurrent.Executors;

@Configuration
public class OpenAiConfig {

    @Value("${app.embedding.api-key}")
    private String dashscopeApiKey;

    @Value("${app.chat.model}")
    private String chatModel;

    @Bean
    @Primary
    public OpenAiChatModel dashScopeChatModel() {
        String baseUrl = "https://dashscope.aliyuncs.com";
        String completionsPath = "/compatible-mode/v1/chat/completions";

        HttpClient httpClient = HttpClient.newBuilder()
                .version(HttpClient.Version.HTTP_1_1)
                .connectTimeout(Duration.ofSeconds(30))
                .executor(Executors.newFixedThreadPool(10))
                .build();

        reactor.netty.http.client.HttpClient nettyHttpClient =
                reactor.netty.http.client.HttpClient.create()
                        .responseTimeout(Duration.ofSeconds(180));

        OpenAiApi api = new OpenAiApi(baseUrl, dashscopeApiKey, completionsPath, completionsPath,
                RestClient.builder().requestFactory(new JdkClientHttpRequestFactory(httpClient)),
                WebClient.builder().clientConnector(new ReactorClientHttpConnector(nettyHttpClient)),
                new DefaultResponseErrorHandler());

        OpenAiChatOptions options = OpenAiChatOptions.builder().model(chatModel).build();
        return new OpenAiChatModel(api, options);
    }
}
