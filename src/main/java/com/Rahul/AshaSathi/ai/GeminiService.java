package com.Rahul.AshaSathi.ai;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;
import reactor.util.retry.Retry;

import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Service responsible for all Gemini 2.5 Flash API interactions.
 *
 * Responsibilities:
 *  - Build and send REST requests to the Gemini generateContent endpoint
 *  - Strip markdown wrappers from responses
 *  - Retry on transient failures (up to 3 attempts with exponential backoff)
 *  - Apply a 45-second timeout per request
 *  - Never expose the API key in logs
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class GeminiService {

    private static final String MODEL = "gemini-2.5-flash";
    private static final String ENDPOINT_PATH =
            "/v1beta/models/" + MODEL + ":generateContent";

    private static final int MAX_RETRIES = 3;
    private static final Duration TIMEOUT = Duration.ofSeconds(45);
    private static final double TEMPERATURE = 0.0;
    // gemini-2.5-flash is a "thinking" model: its internal reasoning tokens are
    // billed against maxOutputTokens. Left enabled, thinking on a full
    // prescription consumes ~1500-2000 tokens and the actual JSON/summary comes
    // back truncated (finishReason=MAX_TOKENS), which breaks extraction parsing
    // and aborts the pipeline before a summary is generated. Disable thinking so
    // the whole budget is available for the response.
    private static final int MAX_OUTPUT_TOKENS = 4096;
    private static final int THINKING_BUDGET = 0;

    @Qualifier("geminiWebClient")
    private final WebClient geminiWebClient;

    private final PromptService promptService;

    @Value("${gemini.api.key:}")
    private String apiKey;

    // ── Markdown stripper ─────────────────────────────────────────────────────

    private static final Pattern MD_FENCE_PATTERN =
            Pattern.compile("^```(?:json)?\\s*|\\s*```$", Pattern.MULTILINE);

    private String stripMarkdown(String text) {
        if (text == null) return "";
        String cleaned = MD_FENCE_PATTERN.matcher(text.strip()).replaceAll("").strip();
        int first = cleaned.indexOf('{');
        int last  = cleaned.lastIndexOf('}');
        if (first != -1 && last != -1 && last > first) {
            cleaned = cleaned.substring(first, last + 1);
        }
        return cleaned;
    }

    // ── Core API call ─────────────────────────────────────────────────────────

    /**
     * Send a text prompt to Gemini 2.5 Flash and return the raw text response.
     * Applies retry with exponential backoff and a hard timeout.
     */
    private String getEffectiveApiKey() {
        String key = this.apiKey;
        if (key == null || key.isBlank() || "AIzaSyBbjSFuewpKa_yf8FLl-AZ75tuSHirv_CE".equals(key.strip())) {
            log.info("Expired or missing environment API key detected. Attempting to load from secrets file.");
            List<String> paths = List.of(
                "src/main/resources/application-secrets.properties",
                "Backend/src/main/resources/application-secrets.properties",
                "./config/application-secrets.properties"
            );
            for (String p : paths) {
                java.io.File file = new java.io.File(p);
                if (file.exists()) {
                    try {
                        java.util.Properties props = new java.util.Properties();
                        try (java.io.FileInputStream fis = new java.io.FileInputStream(file)) {
                            props.load(fis);
                            String fileKey = props.getProperty("GEMINI_API_KEY");
                            if (fileKey == null || fileKey.isBlank()) {
                                fileKey = props.getProperty("gemini.api.key");
                            }
                            if (fileKey != null && !fileKey.isBlank() && !"AIzaSyBbjSFuewpKa_yf8FLl-AZ75tuSHirv_CE".equals(fileKey.strip())) {
                                log.info("Successfully loaded fresh API key from secrets file: {}", p);
                                return fileKey.strip();
                            }
                        }
                    } catch (Exception e) {
                        log.warn("Failed to load secrets from {}: {}", p, e.getMessage());
                    }
                }
            }
        }
        return key != null ? key.strip() : "";
    }

    // ── Core API call ─────────────────────────────────────────────────────────

    /**
     * Send a text prompt to Gemini 2.5 Flash and return the raw text response.
     * Applies retry with exponential backoff and a hard timeout.
     */
    public String callGemini(String promptText) {
        String activeKey = getEffectiveApiKey();
        if (activeKey == null || activeKey.isBlank()) {
            throw new IllegalStateException(
                "GEMINI_API_KEY is not configured. Set it as an environment variable.");
        }

        Map<String, Object> payload = Map.of(
            "contents", List.of(
                Map.of("parts", List.of(Map.of("text", promptText)))
            ),
            "generationConfig", Map.of(
                "temperature", TEMPERATURE,
                "maxOutputTokens", MAX_OUTPUT_TOKENS,
                "thinkingConfig", Map.of("thinkingBudget", THINKING_BUDGET)
            )
        );

        String url = ENDPOINT_PATH + "?key=" + activeKey;

        return geminiWebClient.post()
                .uri(url)
                .bodyValue(payload)
                .retrieve()
                .onStatus(
                    status -> status.value() == 429,
                    response -> Mono.error(new RuntimeException("Gemini rate limit hit"))
                )
                .onStatus(
                    status -> status.is5xxServerError(),
                    response -> response.bodyToMono(String.class)
                        .flatMap(body -> Mono.error(
                            new RuntimeException("Gemini server error: " + body.substring(0, Math.min(200, body.length())))
                        ))
                )
                .bodyToMono(Map.class)
                .timeout(TIMEOUT)
                .retryWhen(
                    Retry.backoff(MAX_RETRIES, Duration.ofSeconds(2))
                         .filter(e -> e instanceof RuntimeException)
                         .doBeforeRetry(signal ->
                             log.warn("Retrying Gemini call (attempt {}): {}",
                                 signal.totalRetries() + 1, signal.failure().getMessage())
                         )
                )
                .map(this::extractText)
                .block();
    }

    @SuppressWarnings("unchecked")
    private String extractText(Map<?, ?> responseBody) {
        var candidates = (List<?>) responseBody.get("candidates");
        if (candidates == null || candidates.isEmpty()) {
            throw new RuntimeException("Gemini returned no candidates.");
        }
        var candidate = (Map<?, ?>) candidates.get(0);
        String finishReason = (String) candidate.get("finishReason");

        var content = (Map<?, ?>) candidate.get("content");
        var parts   = content != null ? (List<?>) content.get("parts") : null;
        if (parts == null || parts.isEmpty()) {
            // MAX_TOKENS means the model used up maxOutputTokens (often on hidden
            // thinking) before emitting any text — surface it explicitly rather
            // than as a generic empty-parts error.
            if ("MAX_TOKENS".equals(finishReason)) {
                throw new RuntimeException(
                    "Gemini response truncated (finishReason=MAX_TOKENS): the model "
                    + "hit maxOutputTokens before producing output. Raise "
                    + "MAX_OUTPUT_TOKENS or keep thinking disabled.");
            }
            throw new RuntimeException(
                "Gemini returned empty content parts (finishReason=" + finishReason + ").");
        }

        String text = (String) ((Map<?, ?>) parts.get(0)).get("text");
        // Even with a text part, MAX_TOKENS means the payload is cut off mid-stream
        // (e.g. truncated JSON), which would fail downstream parsing — reject it.
        if ("MAX_TOKENS".equals(finishReason)) {
            throw new RuntimeException(
                "Gemini response truncated (finishReason=MAX_TOKENS): output was cut "
                + "off and is incomplete. Raise MAX_OUTPUT_TOKENS or keep thinking disabled.");
        }
        log.info("Gemini response received ({} chars).", text == null ? 0 : text.length());
        return text;
    }

    // ── Public domain methods ─────────────────────────────────────────────────

    /**
     * Extract structured medical data from OCR text.
     * Returns the raw JSON string from Gemini (markdown-stripped).
     */
    public String extractMedicalData(String ocrText) {
        log.info("Calling Gemini for medical data extraction ({} chars of OCR text).", ocrText.length());
        String prompt = promptService.buildExtractionPrompt(ocrText);
        String raw = callGemini(prompt);
        return stripMarkdown(raw);
    }

    /**
     * Generate a plain-text clinical summary for an ASHA worker.
     * Returns plain text (≤150 words).
     */
    public String generateSummary(String medicalDataJson) {
        log.info("Calling Gemini for clinical summary generation.");
        String prompt = promptService.buildSummaryPrompt(medicalDataJson);
        String raw = callGemini(prompt);
        // Remove any accidental markdown headers
        return raw.strip().replaceAll("(?m)^#+\\s*", "");
    }
}
