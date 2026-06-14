package com.Rahul.AshaSathi.validation;

import org.springframework.stereotype.Service;

/**
 * Classifies document-level OCR confidence and determines
 * whether the document requires manual review.
 *
 * Thresholds (mirrors Python confidence_service.py):
 *   HIGH            >= 0.90
 *   MEDIUM          >= 0.75
 *   REVIEW_REQUIRED  < 0.75
 */
@Service
public class ConfidenceValidationService {

    public enum ConfidenceLevel { HIGH, MEDIUM, REVIEW_REQUIRED }

    private static final double HIGH_THRESHOLD   = 0.90;
    private static final double MEDIUM_THRESHOLD = 0.75;

    /**
     * Classify a confidence score (0.0 – 1.0) into a level.
     */
    public ConfidenceLevel classify(double score) {
        if (score >= HIGH_THRESHOLD)   return ConfidenceLevel.HIGH;
        if (score >= MEDIUM_THRESHOLD) return ConfidenceLevel.MEDIUM;
        return ConfidenceLevel.REVIEW_REQUIRED;
    }

    /**
     * Returns true if this document should be flagged for human review.
     */
    public boolean requiresReview(double score) {
        return classify(score) == ConfidenceLevel.REVIEW_REQUIRED;
    }

    /**
     * Returns a user-friendly label for UI display.
     */
    public String getLabel(double score) {
        return switch (classify(score)) {
            case HIGH            -> "High Confidence";
            case MEDIUM          -> "Medium Confidence";
            case REVIEW_REQUIRED -> "Review Required";
        };
    }
}
