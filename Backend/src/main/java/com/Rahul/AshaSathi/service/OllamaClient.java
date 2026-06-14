package com.Rahul.AshaSathi.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.*;

import java.util.Map;

/**
 * OllamaClient — Phase 7
 *
 * Communicates directly with the local Ollama instance at http://localhost:11434.
 * Used for:
 *   1. Medical data extraction (structured JSON from raw OCR text)
 *   2. Clinical summary generation (plain text, ≤150 words)
 */
@Service
@Slf4j
public class OllamaClient {

    @Value("${app.ollama.base-url:http://localhost:11434}")
    private String ollamaBaseUrl;

    @Value("${app.ollama.model:llama3.1:8b-instruct-q4_0}")
    private String model;

    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    // ─── Medical Data Extraction Prompt ─────────────────────────────────────

    /**
     * Sends raw OCR text to Llama 3.1 and requests structured JSON extraction.
     * Returns raw JSON string from the model.
     */
    public String extractMedicalData(String ocrText) {
        String prompt = buildExtractionPrompt(ocrText);
        return callOllama(prompt);
    }

    /**
     * Sends structured medical data to Llama 3.1 and requests a clinical summary.
     * Returns plain text under 150 words for ASHA worker consumption.
     */
    public String generateClinicalSummary(String diagnosis, String medicines,
                                           String abnormalLabs, String followUp) {
        String prompt = buildSummaryPrompt(diagnosis, medicines, abnormalLabs, followUp);
        return callOllama(prompt);
    }

    // ─── Core HTTP Call ──────────────────────────────────────────────────────

    private String callOllama(String prompt) {
        String url = ollamaBaseUrl + "/api/generate";

        Map<String, Object> requestBody = Map.of(
            "model",   model,
            "prompt",  prompt,
            "stream",  false,
            "options", Map.of("temperature", 0.0)
        );

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        try {
            String requestJson = objectMapper.writeValueAsString(requestBody);
            HttpEntity<String> entity = new HttpEntity<>(requestJson, headers);

            log.debug("Calling Ollama model '{}' at {}", model, url);
            ResponseEntity<Map> response = restTemplate.postForEntity(url, entity, Map.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                String result = (String) response.getBody().get("response");
                log.debug("Ollama responded successfully ({} chars)", result != null ? result.length() : 0);
                return result != null ? result : "";
            } else {
                log.error("Ollama returned non-2xx status: {}", response.getStatusCode());
                throw new RuntimeException("Ollama error: HTTP " + response.getStatusCode());
            }
        } catch (Exception e) {
            log.error("Failed to communicate with Ollama: {}", e.getMessage());
            throw new RuntimeException("Ollama service unavailable: " + e.getMessage(), e);
        }
    }

    // ─── Prompt Builders ─────────────────────────────────────────────────────

    private String buildExtractionPrompt(String ocrText) {
        return """
                You are a medical data extraction engine.

                Extract information from the provided OCR text.

                Return ONLY valid JSON.
                Do not include markdown.
                Do not include explanations.
                If a field is missing return null.

                JSON Schema:
                {
                  "diagnosis": "",
                  "follow_up_date": "",
                  "medicines": [
                    {
                      "name": "",
                      "dosage": "",
                      "frequency": "",
                      "duration": ""
                    }
                  ],
                  "lab_tests": [
                    {
                      "test_name": "",
                      "value": "",
                      "unit": "",
                      "reference_range": ""
                    }
                  ],
                  "notes": ""
                }

                OCR TEXT:
                """ + ocrText;
    }

    private String buildSummaryPrompt(String diagnosis, String medicines,
                                       String abnormalLabs, String followUp) {
        return """
                Generate a concise clinical summary for an ASHA worker.

                Include:
                - Diagnosis
                - Important medicines
                - Abnormal lab values
                - Follow-up information

                Keep summary under 150 words.
                Use simple language.
                Return plain text only.

                Clinical Data:
                Diagnosis: """ + diagnosis + """

                Medicines: """ + medicines + """

                Abnormal Lab Values: """ + abnormalLabs + """

                Follow-up: """ + followUp;
    }
}
