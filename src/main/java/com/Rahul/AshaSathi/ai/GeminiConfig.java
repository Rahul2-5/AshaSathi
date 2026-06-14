package com.Rahul.AshaSathi.ai;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.reactive.function.client.WebClient;

import java.time.Duration;

/**
 * Configuration for Gemini 2.5 Flash API integration.
 *
 * API key is loaded exclusively from environment variables / Heroku Config Vars.
 * Never hardcoded in source code.
 */
@Configuration
public class GeminiConfig {

    private static final String GEMINI_BASE_URL =
            "https://generativelanguage.googleapis.com";

    @Value("${gemini.api.key:}")
    private String geminiApiKey;

    /**
     * Dedicated WebClient for Gemini API calls.
     * Configured with a 45-second response timeout suitable for LLM inference.
     */
    @Bean("geminiWebClient")
    public WebClient geminiWebClient() {
        return WebClient.builder()
                .baseUrl(GEMINI_BASE_URL)
                .codecs(configurer ->
                    configurer.defaultCodecs().maxInMemorySize(2 * 1024 * 1024) // 2 MB
                )
                .build();
    }
}
