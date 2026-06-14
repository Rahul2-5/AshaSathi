package com.Rahul.AshaSathi.ai;

import com.Rahul.AshaSathi.DTO.MedicalExtractionDTO;
import com.Rahul.AshaSathi.DTO.MedicineDTO;
import com.Rahul.AshaSathi.DTO.LabResultDTO;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;

/**
 * Parses the raw JSON string returned by Gemini into a MedicalExtractionDTO.
 *
 * Responsibilities:
 *  - Strip markdown fences
 *  - Repair common JSON issues (trailing commas)
 *  - Deserialise with Jackson
 *  - Fallback to empty schema on any parse failure
 *  - Normalise all fields to non-null safe defaults
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ResponseParser {

    private static final ObjectMapper MAPPER = new ObjectMapper();
    private static final TypeReference<Map<String, Object>> MAP_TYPE =
            new TypeReference<>() {};

    // Strip leading/trailing markdown fences
    private static final Pattern FENCE_PATTERN =
            Pattern.compile("^```(?:json)?\\s*|\\s*```$", Pattern.MULTILINE);

    // ── Public entry point ────────────────────────────────────────────────────

    /**
     * Parse Gemini's raw response string into a validated MedicalExtractionDTO.
     * Never throws — returns an empty DTO on any failure.
     */
    public MedicalExtractionDTO parse(String rawGeminiResponse) {
        if (rawGeminiResponse == null || rawGeminiResponse.isBlank()) {
            log.warn("Gemini returned empty response; using empty DTO.");
            return emptyDto();
        }

        String cleaned  = stripMarkdown(rawGeminiResponse);
        String repaired = repairJson(cleaned);

        Map<String, Object> data = null;

        // Attempt 1: direct parse
        try {
            data = MAPPER.readValue(repaired, MAP_TYPE);
        } catch (Exception e) {
            log.warn("Direct JSON parse failed: {}. Attempting single-quote fix.", e.getMessage());
        }

        // Attempt 2: replace single-quotes → double-quotes
        if (data == null) {
            try {
                data = MAPPER.readValue(repaired.replace("'", "\""), MAP_TYPE);
                log.info("JSON recovered via single-quote replacement.");
            } catch (Exception e) {
                log.error("All JSON repair attempts failed. Returning empty DTO.");
                return emptyDto();
            }
        }

        return normalise(data);
    }

    // ── Cleaning helpers ──────────────────────────────────────────────────────

    private String stripMarkdown(String text) {
        String t = FENCE_PATTERN.matcher(text.strip()).replaceAll("").strip();
        int first = t.indexOf('{');
        int last  = t.lastIndexOf('}');
        if (first != -1 && last > first) {
            t = t.substring(first, last + 1);
        }
        return t;
    }

    private String repairJson(String text) {
        // Remove trailing commas before ] or }
        return text.replaceAll(",\\s*([\\]}])", "$1");
    }

    // ── Schema normaliser ─────────────────────────────────────────────────────

    @SuppressWarnings("unchecked")
    private MedicalExtractionDTO normalise(Map<String, Object> data) {
        MedicalExtractionDTO dto = new MedicalExtractionDTO();
        dto.setDiagnosis(getString(data, "diagnosis"));
        dto.setFollowUpDate(getString(data, "follow_up_date"));
        dto.setNotes(getString(data, "notes"));

        List<MedicineDTO> medicines = new ArrayList<>();
        Object rawMeds = data.get("medicines");
        if (rawMeds instanceof List<?> medList) {
            for (Object item : medList) {
                if (item instanceof Map<?, ?> med) {
                    MedicineDTO m = new MedicineDTO();
                    m.setMedicineName(strOf(med, "name"));
                    m.setDosage(strOf(med, "dosage"));
                    m.setFrequency(strOf(med, "frequency"));
                    m.setDuration(strOf(med, "duration"));
                    if (!m.getMedicineName().isBlank()) {
                        medicines.add(m);
                    }
                }
            }
        }
        dto.setMedicines(medicines);

        List<LabResultDTO> labs = new ArrayList<>();
        Object rawLabs = data.get("lab_tests");
        if (rawLabs instanceof List<?> labList) {
            for (Object item : labList) {
                if (item instanceof Map<?, ?> lab) {
                    LabResultDTO l = new LabResultDTO();
                    l.setTestName(strOf(lab, "test_name"));
                    l.setValue(strOf(lab, "value"));
                    l.setUnit(strOf(lab, "unit"));
                    l.setReferenceRange(strOf(lab, "reference_range"));
                    if (!l.getTestName().isBlank()) {
                        labs.add(l);
                    }
                }
            }
        }
        dto.setLabTests(labs);
        return dto;
    }

    private MedicalExtractionDTO emptyDto() {
        MedicalExtractionDTO dto = new MedicalExtractionDTO();
        dto.setMedicines(new ArrayList<>());
        dto.setLabTests(new ArrayList<>());
        return dto;
    }

    private String getString(Map<String, Object> map, String key) {
        Object val = map.get(key);
        return (val instanceof String s && !s.isBlank()) ? s : null;
    }

    private String strOf(Map<?, ?> map, String key) {
        Object val = map.get(key);
        return val == null ? "" : val.toString();
    }
}
