package com.Rahul.AshaSathi.validation;

import com.Rahul.AshaSathi.DTO.LabResultDTO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

/**
 * Validates extracted lab results against the lab_reference_ranges table.
 *
 * Severity levels:
 *   NORMAL   — value within reference range
 *   LOW      — value below min
 *   HIGH     — value above max
 *   CRITICAL — value severely outside range (< 50% of min, or > 150% of max)
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class LabValidationService {

    private final JdbcTemplate jdbcTemplate;

    public List<LabResultDTO> validateLabResults(List<LabResultDTO> labs) {
        for (LabResultDTO lab : labs) {
            if (lab.getTestName() == null || lab.getTestName().isBlank()) continue;
            classifySeverity(lab);
        }
        return labs;
    }

    private void classifySeverity(LabResultDTO lab) {
        // Attempt to parse the numeric value
        double numericValue;
        try {
            String cleaned = lab.getValue()
                .replaceAll("[^0-9.\\-]", "")
                .trim();
            if (cleaned.isEmpty()) {
                lab.setSeverity("NORMAL");
                return;
            }
            numericValue = Double.parseDouble(cleaned);
        } catch (NumberFormatException e) {
            // Non-numeric result (e.g. "Positive") — default to NORMAL
            lab.setSeverity("NORMAL");
            return;
        }

        // Lookup reference range
        Optional<RefRange> rangeOpt = fetchRange(lab.getTestName());
        if (rangeOpt.isEmpty()) {
            // Unknown test — use reference_range from OCR if available
            lab.setSeverity("NORMAL");
            log.debug("No reference range found for test '{}'. Defaulting to NORMAL.", lab.getTestName());
            return;
        }

        RefRange range = rangeOpt.get();
        double min = range.minValue();
        double max = range.maxValue();

        String severity;
        if (numericValue < min * 0.5 || numericValue > max * 1.5) {
            severity = "CRITICAL";
        } else if (numericValue < min) {
            severity = "LOW";
        } else if (numericValue > max) {
            severity = "HIGH";
        } else {
            severity = "NORMAL";
        }

        lab.setSeverity(severity);
        // Set the DB reference range string if not already provided by OCR
        if (lab.getReferenceRange() == null || lab.getReferenceRange().isBlank()) {
            lab.setReferenceRange(range.minValue() + " - " + range.maxValue() + " " + range.unit());
        }

        log.debug("Lab '{}' value={} → {} (range: {}-{}).",
            lab.getTestName(), numericValue, severity, min, max);
    }

    private Optional<RefRange> fetchRange(String testName) {
        try {
            List<RefRange> results = jdbcTemplate.query(
                """
                SELECT min_value, max_value, unit
                FROM lab_reference_ranges
                WHERE LOWER(test_name) = LOWER(?)
                LIMIT 1
                """,
                (rs, rowNum) -> new RefRange(
                    rs.getDouble("min_value"),
                    rs.getDouble("max_value"),
                    rs.getString("unit")
                ),
                testName
            );
            return results.isEmpty() ? Optional.empty() : Optional.of(results.get(0));
        } catch (Exception e) {
            log.warn("Error querying lab_reference_ranges for '{}': {}", testName, e.getMessage());
            return Optional.empty();
        }
    }

    private record RefRange(double minValue, double maxValue, String unit) {}
}
