package com.Rahul.AshaSathi.service;

import com.Rahul.AshaSathi.dto.MedicalDocumentDTO;
import com.Rahul.AshaSathi.entity.DrugMaster;
import com.Rahul.AshaSathi.entity.LabResult;
import com.Rahul.AshaSathi.entity.LabReferenceRange;
import com.Rahul.AshaSathi.repository.DrugMasterRepository;
import com.Rahul.AshaSathi.repository.LabReferenceRangeRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

/**
 * ValidationService — Phase 6
 *
 * Handles:
 *  1. Drug validation: exact match → fuzzy Levenshtein match against drug_master
 *  2. Lab result validation: compares extracted value against lab_reference_ranges
 *     and assigns NORMAL / LOW / HIGH / CRITICAL severity
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class ValidationService {

    private final DrugMasterRepository drugMasterRepository;
    private final LabReferenceRangeRepository labReferenceRangeRepository;

    // ─── Drug Validation ────────────────────────────────────────────────────

    public record DrugValidationResult(boolean verified, String matchedName, int matchScore) {}

    /**
     * Validates a medicine name against the drug_master table.
     * First tries exact match (case-insensitive), then falls back to fuzzy Levenshtein.
     * Threshold: score >= 85 → verified, score 70–84 → flagged for review, < 70 → unknown.
     */
    public DrugValidationResult validateDrug(String extractedName) {
        if (extractedName == null || extractedName.isBlank()) {
            return new DrugValidationResult(false, null, 0);
        }

        // 1. Exact match
        Optional<DrugMaster> exactMatch = drugMasterRepository.findByDrugNameIgnoreCase(extractedName.trim());
        if (exactMatch.isPresent()) {
            log.debug("Drug '{}' → exact match found: '{}'", extractedName, exactMatch.get().getDrugName());
            return new DrugValidationResult(true, exactMatch.get().getDrugName(), 100);
        }

        // 2. Fuzzy Levenshtein match across all active drugs
        List<DrugMaster> allDrugs = drugMasterRepository.findAllActiveDrugs();
        String normalizedInput = extractedName.trim().toLowerCase();

        String bestMatch = null;
        int bestScore = 0;

        for (DrugMaster drug : allDrugs) {
            int score = levenshteinSimilarityScore(normalizedInput, drug.getDrugName().toLowerCase());
            if (score > bestScore) {
                bestScore = score;
                bestMatch = drug.getDrugName();
            }
        }

        log.debug("Drug '{}' → best fuzzy match: '{}' (score: {})", extractedName, bestMatch, bestScore);

        if (bestScore >= 85) {
            return new DrugValidationResult(true, bestMatch, bestScore);
        } else if (bestScore >= 70) {
            // Flagged — partially matched but not confidently verified
            return new DrugValidationResult(false, bestMatch, bestScore);
        } else {
            return new DrugValidationResult(false, null, bestScore);
        }
    }

    // ─── Lab Validation ─────────────────────────────────────────────────────

    /**
     * Validates a lab result value against the reference range in lab_reference_ranges.
     * Returns severity: NORMAL, LOW, HIGH, or CRITICAL.
     */
    public LabResult.Severity validateLabResult(String testName, String valueStr) {
        if (testName == null || valueStr == null || valueStr.isBlank()) {
            return LabResult.Severity.NORMAL;
        }

        double value;
        try {
            // Strip any non-numeric characters except decimal point and minus sign
            String cleaned = valueStr.replaceAll("[^0-9.\\-]", "").trim();
            value = Double.parseDouble(cleaned);
        } catch (NumberFormatException e) {
            log.warn("Could not parse lab value '{}' for test '{}' — defaulting to NORMAL", valueStr, testName);
            return LabResult.Severity.NORMAL;
        }

        Optional<LabReferenceRange> rangeOpt = labReferenceRangeRepository.findByTestNameIgnoreCase(testName.trim());
        if (rangeOpt.isEmpty()) {
            log.debug("No reference range found for test '{}' — defaulting to NORMAL", testName);
            return LabResult.Severity.NORMAL;
        }

        LabReferenceRange range = rangeOpt.get();

        // Critical thresholds take priority
        if (range.getCriticalLow() != null && value < range.getCriticalLow()) {
            return LabResult.Severity.CRITICAL;
        }
        if (range.getCriticalHigh() != null && value > range.getCriticalHigh()) {
            return LabResult.Severity.CRITICAL;
        }
        if (range.getMinValue() != null && value < range.getMinValue()) {
            return LabResult.Severity.LOW;
        }
        if (range.getMaxValue() != null && value > range.getMaxValue()) {
            return LabResult.Severity.HIGH;
        }

        return LabResult.Severity.NORMAL;
    }

    // ─── Levenshtein Similarity Algorithm ───────────────────────────────────

    /**
     * Returns a 0-100 similarity score between two strings using Levenshtein distance.
     * 100 = identical strings, 0 = completely different.
     */
    private int levenshteinSimilarityScore(String a, String b) {
        int distance = levenshteinDistance(a, b);
        int maxLen = Math.max(a.length(), b.length());
        if (maxLen == 0) return 100;
        return (int) Math.round(100.0 * (1.0 - (double) distance / maxLen));
    }

    private int levenshteinDistance(String a, String b) {
        int m = a.length(), n = b.length();
        int[][] dp = new int[m + 1][n + 1];

        for (int i = 0; i <= m; i++) dp[i][0] = i;
        for (int j = 0; j <= n; j++) dp[0][j] = j;

        for (int i = 1; i <= m; i++) {
            for (int j = 1; j <= n; j++) {
                if (a.charAt(i - 1) == b.charAt(j - 1)) {
                    dp[i][j] = dp[i - 1][j - 1];
                } else {
                    dp[i][j] = 1 + Math.min(dp[i - 1][j - 1], Math.min(dp[i - 1][j], dp[i][j - 1]));
                }
            }
        }
        return dp[m][n];
    }
}
