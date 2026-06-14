package com.Rahul.AshaSathi.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

import java.util.concurrent.Executor;

/**
 * Enables async processing for document pipeline.
 * Configures a dedicated thread pool for OCR/LLM operations
 * to avoid blocking Spring's default task executor.
 */
@Configuration
@EnableAsync
public class AsyncConfig {

    @Bean(name = "medicalProcessingExecutor")
    public Executor medicalProcessingExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(3);
        executor.setMaxPoolSize(8);
        executor.setQueueCapacity(50);
        executor.setThreadNamePrefix("MedicalOCR-");
        executor.initialize();
        return executor;
    }
}
