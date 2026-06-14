package com.Rahul.AshaSathi.validation;

import com.Rahul.AshaSathi.DTO.MedicineDTO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Locale;

/**
 * Validates extracted medicines against the drug_master PostgreSQL table.
 *
 * Strategy:
 * 1. Exact match (case-insensitive)
 * 2. Levenshtein fuzzy match (PostgreSQL levenshtein() function)
 *    — Verified if distance <= threshold for name length
 *    — matchScore = (1 - distance/maxLen) * 100
 * 3. Unknown: verified=false, matchScore=0
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class DrugValidationService {

    private static final int FUZZY_SCORE_THRESHOLD = 85; // minimum match score to flag as partial

    private final JdbcTemplate jdbcTemplate;

    /**
     * Validate a list of MedicineDTOs against drug_master.
     * Mutates each DTO to set verified, matchedDrugName, matchScore.
     */
    public List<MedicineDTO> validateMedicines(List<MedicineDTO> medicines) {
        for (MedicineDTO med : medicines) {
            if (med.getMedicineName() == null || med.getMedicineName().isBlank()) continue;
            validateSingle(med);
        }
        return medicines;
    }

    private void validateSingle(MedicineDTO med) {
        String name = med.getMedicineName().trim();

        // ── 1. Exact match ────────────────────────────────────────────────────
        List<String> exactMatches = jdbcTemplate.queryForList(
            "SELECT drug_name FROM drug_master WHERE LOWER(drug_name) = LOWER(?)",
            String.class, name
        );
        if (!exactMatches.isEmpty()) {
            med.setVerified(true);
            med.setMatchedDrugName(exactMatches.get(0));
            med.setMatchScore(100);
            log.debug("Drug '{}' → exact match '{}'.", name, exactMatches.get(0));
            return;
        }

        // ── 2. Levenshtein fuzzy match ────────────────────────────────────────
        // Use PostgreSQL's levenshtein() from the fuzzystrmatch extension
        try {
            List<Map2> fuzzyResults = jdbcTemplate.query(
                """
                SELECT drug_name,
                       levenshtein(LOWER(drug_name), LOWER(?)) AS dist
                FROM drug_master
                ORDER BY dist ASC
                LIMIT 1
                """,
                (rs, rowNum) -> new Map2(rs.getString("drug_name"), rs.getInt("dist")),
                name
            );

            if (!fuzzyResults.isEmpty()) {
                Map2 top = fuzzyResults.get(0);
                int maxLen = Math.max(name.length(), top.drugName.length());
                int score  = maxLen == 0 ? 0 :
                    (int) Math.round((1.0 - (double) top.dist / maxLen) * 100);

                if (score >= FUZZY_SCORE_THRESHOLD) {
                    med.setVerified(true);
                    med.setMatchedDrugName(top.drugName);
                    med.setMatchScore(score);
                    log.debug("Drug '{}' → fuzzy match '{}' score={}.", name, top.drugName, score);
                } else if (score >= 60) {
                    // Partial / review
                    med.setVerified(false);
                    med.setMatchedDrugName(top.drugName);
                    med.setMatchScore(score);
                    log.debug("Drug '{}' → partial match '{}' score={} (review required).", name, top.drugName, score);
                } else {
                    med.setVerified(false);
                    med.setMatchScore(score);
                    log.debug("Drug '{}' → no match (score={}).", name, score);
                }
                return;
            }
        } catch (Exception e) {
            // levenshtein() requires fuzzystrmatch extension — gracefully degrade
            log.warn("Levenshtein query failed (fuzzystrmatch not installed?): {}. Skipping fuzzy match.", e.getMessage());
        }

        // ── 3. Unknown drug ───────────────────────────────────────────────────
        med.setVerified(false);
        med.setMatchScore(0);
        log.debug("Drug '{}' → unknown.", name);
    }

    /** Simple inner record for fuzzy result rows. */
    private record Map2(String drugName, int dist) {}
}
