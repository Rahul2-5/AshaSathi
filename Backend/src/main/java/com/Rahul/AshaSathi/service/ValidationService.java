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
     * Pipeline: exact match → normalized exact match → combined fuzzy+token score.
     * Threshold: score >= 85 → verified, score 70–84 → flagged for review, < 70 → unknown.
     */
    public DrugValidationResult validateDrug(String extractedName) {
        if (extractedName == null || extractedName.isBlank()) {
            return new DrugValidationResult(false, null, 0);
        }

        String raw = extractedName.trim();

        // 1. Exact match on raw OCR text
        Optional<DrugMaster> exactMatch = drugMasterRepository.findByDrugNameIgnoreCase(raw);
        if (exactMatch.isPresent()) {
            log.debug("Drug '{}' → exact match", raw);
            return new DrugValidationResult(true, exactMatch.get().getDrugName(), 100);
        }

        // 2. Normalize: strip "Tab.", "Cap.", "Inj." prefixes and dosage suffixes
        //    e.g. "Tab. Metformin 500mg" → "metformin"
        String normalized = normalizeDrugName(raw);
        if (!normalized.equalsIgnoreCase(raw)) {
            exactMatch = drugMasterRepository.findByDrugNameIgnoreCase(normalized);
            if (exactMatch.isPresent()) {
                log.debug("Drug '{}' → normalized exact match: '{}'", raw, exactMatch.get().getDrugName());
                return new DrugValidationResult(true, exactMatch.get().getDrugName(), 100);
            }
        }

        // 3. Fuzzy match using combined Levenshtein + token-intersection scoring
        List<DrugMaster> allDrugs = drugMasterRepository.findAllActiveDrugs();
        String bestMatch = null;
        int bestScore = 0;

        for (DrugMaster drug : allDrugs) {
            int score = combinedScore(normalized, drug.getDrugName().toLowerCase());
            if (score > bestScore) {
                bestScore = score;
                bestMatch = drug.getDrugName();
            }
        }

        log.debug("Drug '{}' (normalized: '{}') → best match: '{}' (score: {})", raw, normalized, bestMatch, bestScore);

        if (bestScore >= 85) {
            return new DrugValidationResult(true, bestMatch, bestScore);
        } else if (bestScore >= 70) {
            return new DrugValidationResult(false, bestMatch, bestScore);
        } else {
            return new DrugValidationResult(false, null, bestScore);
        }
    }

    /**
     * Strips prescription form prefixes ("Tab.", "Cap.", "Inj.", etc.) and
     * trailing dosage suffixes ("500mg", "2.5ml", etc.) so matching works on
     * the bare molecule name.
     */
    private String normalizeDrugName(String name) {
        String result = name.toLowerCase().trim();
        // Strip leading form prefixes
        result = result.replaceAll("^(tab\\.?|cap\\.?|caps\\.?|inj\\.?|syp\\.?|syr\\.?|susp\\.?|oint\\.?|cream|drops?|gel|patch)\\s+", "");
        // Strip trailing dosage (e.g. "500mg", "5 mg", "2.5ml", "10 iu", "1000 units")
        result = result.replaceAll("\\s+\\d+\\.?\\d*\\s*(mg|mcg|ml|g\\b|iu|units?).*$", "").trim();
        return result;
    }

    /**
     * Combines Levenshtein similarity with a token-intersection score.
     * Token scoring catches cases where the molecule name is one token inside
     * a longer string (e.g. "amoxicillin clavulanate" matching "amoxicillin").
     */
    private int combinedScore(String input, String dbDrug) {
        int levenScore = levenshteinSimilarityScore(input, dbDrug);

        // Substring containment: proportional to how much of the shorter string is matched
        if (dbDrug.contains(input) || input.contains(dbDrug)) {
            int shorter = Math.min(input.length(), dbDrug.length());
            int longer  = Math.max(input.length(), dbDrug.length());
            int containScore = (int) Math.round(100.0 * shorter / longer);
            levenScore = Math.max(levenScore, containScore);
        }

        // Token-level: best Levenshtein score across individual word pairs
        String[] inputTokens = input.split("[\\s,+/-]+");
        String[] dbTokens    = dbDrug.split("[\\s,+/-]+");
        int tokenScore = 0;
        for (String it : inputTokens) {
            if (it.length() < 4) continue; // skip short/noise tokens
            for (String dt : dbTokens) {
                if (dt.length() < 4) continue;
                int ts = levenshteinSimilarityScore(it, dt);
                if (ts > tokenScore) tokenScore = ts;
            }
        }
        // Token match alone is slightly discounted (not as reliable as full-name match)
        return Math.max(levenScore, (int)(tokenScore * 0.95));
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
