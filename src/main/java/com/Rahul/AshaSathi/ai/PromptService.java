package com.Rahul.AshaSathi.ai;

import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Loads and caches prompt templates from classpath:prompts/.
 *
 * Prompts are read once at startup and held in memory for the lifetime
 * of the application — zero per-request file I/O.
 */
@Slf4j
@Service
public class PromptService {

    private static final String EXTRACTION_PROMPT = "medical-extraction.prompt";
    private static final String SUMMARY_PROMPT    = "summary-generation.prompt";

    /** In-memory prompt cache keyed by filename. */
    private final Map<String, String> promptCache = new ConcurrentHashMap<>();

    @PostConstruct
    public void loadPrompts() {
        log.info("Loading and caching prompt templates...");
        promptCache.put(EXTRACTION_PROMPT, readPrompt(EXTRACTION_PROMPT));
        promptCache.put(SUMMARY_PROMPT,    readPrompt(SUMMARY_PROMPT));
        log.info("Prompt templates loaded: {}", promptCache.keySet());
    }

    private String readPrompt(String filename) {
        String path = "prompts/" + filename;
        try {
            ClassPathResource resource = new ClassPathResource(path);
            byte[] bytes = resource.getInputStream().readAllBytes();
            String content = new String(bytes, StandardCharsets.UTF_8);
            log.debug("Loaded prompt '{}' ({} chars).", filename, content.length());
            return content;
        } catch (IOException e) {
            throw new IllegalStateException(
                "Cannot load required prompt file from classpath: " + path, e);
        }
    }

    /**
     * Build a medical extraction prompt by injecting OCR text
     * into the {{OCR_TEXT}} placeholder.
     */
    public String buildExtractionPrompt(String ocrText) {
        return promptCache
                .getOrDefault(EXTRACTION_PROMPT, "")
                .replace("{{OCR_TEXT}}", ocrText);
    }

    /**
     * Build a clinical summary prompt by injecting medical data JSON
     * into the {{MEDICAL_DATA}} placeholder.
     */
    public String buildSummaryPrompt(String medicalDataJson) {
        return promptCache
                .getOrDefault(SUMMARY_PROMPT, "")
                .replace("{{MEDICAL_DATA}}", medicalDataJson);
    }
}
