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
    public String callGemini(String promptText) {
        if (apiKey == null || apiKey.isBlank()) {
            throw new IllegalStateException(
                "GEMINI_API_KEY is not configured. Set it as an environment variable.");
        }

        Map<String, Object> payload = Map.of(
            "contents", List.of(
                Map.of("parts", List.of(Map.of("text", promptText)))
            ),
            "generationConfig", Map.of(
                "temperature", TEMPERATURE,
                "maxOutputTokens", 2048
            )
        );

        String url = ENDPOINT_PATH + "?key=" + apiKey;

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
        var content = (Map<?, ?>) ((Map<?, ?>) candidates.get(0)).get("content");
        var parts   = (List<?>) content.get("parts");
        if (parts == null || parts.isEmpty()) {
            throw new RuntimeException("Gemini returned empty content parts.");
        }
        String text = (String) ((Map<?, ?>) parts.get(0)).get("text");
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
